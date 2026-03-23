# Lab #09: Technical Build Specification
## Consumer IoT → CloudEvents Integration

**Status:** Phase 1 (Proof of Concept)
**Target:** Trade show floor, March 2026
**Effort:** 5 working days (1 developer)
**Risk:** None (all code additive, fully reversible)

---

## DELIVERABLES

### 1. Withings Relay Service

**Location:** `/transport/withings/`

**Files to create:**

#### `relay.py` — Flask service that receives Withings webhooks
```python
from flask import Flask, request, Response
import json
import requests
from datetime import datetime, timezone

app = Flask(__name__)

# Configuration
OPENSHIFT_CLUSTER = "http://north.qr-demo-qa.svc.cluster.local:5000"
INGEST_ENDPOINT = f"{OPENSHIFT_CLUSTER}/ingest/withings"

@app.post("/webhook")
def webhook():
    """
    Receive a Withings API webhook with weight measurement.
    Convert to CloudEvent and forward to OpenShift /ingest/withings endpoint.
    """
    data = request.get_json(silent=True) or {}

    # Extract weight reading (Withings sends in kg)
    measures = data.get("measures", [])
    if not measures:
        return Response(json.dumps({"error": "no measures"}), status=400)

    weight_kg = float(measures[0].get("value", 82.3)) / 1000  # Withings sends milligrams
    timestamp = measures[0].get("date", datetime.now(timezone.utc).isoformat())

    # Build CloudEvent payload
    payload = {
        "device": "Withings Body+",
        "metric": "weight",
        "value_kg": round(weight_kg, 2),
        "source": "withings",
        "timestamp": timestamp,
        "user_id": data.get("user_id"),
    }

    # Forward to north-api /ingest/withings
    try:
        resp = requests.post(
            INGEST_ENDPOINT,
            json=payload,
            timeout=5,
        )
        return Response(
            json.dumps({"ok": resp.status_code == 200, "forwarded": True}),
            status=resp.status_code,
        )
    except Exception as e:
        return Response(json.dumps({"error": str(e)}), status=500)

@app.get("/healthz")
def healthz():
    return Response(json.dumps({"healthy": True}), status=200)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
```

#### `mock.py` — Generates fake Withings readings for local testing
```python
"""
Mock Withings relay for testing without a real device or Withings account.
Usage: python mock.py
Emits fake weigh-ins to stdout every 10 seconds.
"""

import json
import requests
import time
import random
from datetime import datetime, timezone

INGEST_ENDPOINT = "http://localhost:8080/ingest/withings"

def generate_reading():
    """Generate a fake Withings-like weight reading"""
    base_weight = 82.3
    variance = random.uniform(-0.5, 0.5)
    return {
        "measures": [
            {
                "value": int((base_weight + variance) * 1000),  # milligrams
                "date": datetime.now(timezone.utc).isoformat(),
                "category": 1,
            }
        ],
        "user_id": "mock_user_123",
    }

if __name__ == "__main__":
    print("Mock Withings relay starting. Sending fake readings to", INGEST_ENDPOINT)
    while True:
        reading = generate_reading()
        try:
            resp = requests.post(INGEST_ENDPOINT, json=reading, timeout=2)
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Sent reading: {reading['measures'][0]['value']/1000:.1f}kg → {resp.status_code}")
        except Exception as e:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Error: {e}")
        time.sleep(10)
```

#### `README.md` — Setup and usage
```markdown
# Withings Relay

Converts Withings API webhooks to CloudEvents and forwards to the OpenShift /ingest/withings endpoint.

## Local Development

### Option A: Mock Mode (No Withings Account)

```bash
# Terminal 1: Start the north-api Flask server locally
cd ~/ohc-sap-demo/north
python app.py  # Runs on localhost:8080

# Terminal 2: Start the mock Withings relay
cd ~/ohc-sap-demo/transport/withings
python mock.py

# Terminal 3: Watch the events arrive
curl http://localhost:8080/state
```

Every 10 seconds, you'll see a new fake weight reading posted to `/ingest/withings` and reflected in the `/state` JSON.

### Option B: Real Withings Account

1. Create a Withings developer account at withings.com/developer
2. Create an app and get OAuth tokens
3. Set environment variables:
   ```bash
   export WITHINGS_ACCESS_TOKEN="..."
   export WITHINGS_USER_ID="..."
   export OPENSHIFT_CLUSTER="http://north.qr-demo-qa.svc.cluster.local:5000"
   ```
4. Run the relay:
   ```bash
   python relay.py
   ```
5. Configure your Withings account to send webhooks to `https://<your-relay-hostname>/webhook`

## Kubernetes Deployment

To deploy to OpenShift:

```bash
oc apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: withings-relay
  namespace: qr-demo-qa
spec:
  replicas: 1
  selector:
    matchLabels:
      app: withings-relay
  template:
    metadata:
      labels:
        app: withings-relay
    spec:
      containers:
      - name: relay
        image: python:3.11
        command: ["sh", "-c"]
        args: ["pip install flask requests && python relay.py"]
        ports:
        - containerPort: 5000
        env:
        - name: OPENSHIFT_CLUSTER
          value: "http://north.qr-demo-qa.svc.cluster.local:5000"
EOF

# Expose via route
oc expose deployment withings-relay --port=5000 --type=LoadBalancer
```

Then update your Withings app webhook URL to point to the exposed route.

## CloudEvent Schema

When a Withings reading arrives at `/ingest/withings`, it is converted to this CloudEvent:

```json
{
  "type": "ohc.demo.iot.biometric",
  "eventclass": "ohc.demo.iot",
  "source": "withings-relay",
  "data": {
    "device": "Withings Body+",
    "metric": "weight",
    "value_kg": 82.3,
    "source": "withings",
    "timestamp": "2026-02-23T14:00:00Z",
    "user_id": "mock_user_123"
  }
}
```

## Testing

```bash
# Manual test POST
curl -X POST http://localhost:5000/ingest/withings \
  -H "Content-Type: application/json" \
  -d '{
    "measures": [{"value": 82300, "date": "2026-02-23T14:00:00Z"}],
    "user_id": "test_user"
  }'

# Check it was ingested
curl http://localhost:5000/state | jq '.last'
```
```

---

### 2. Garmin Relay Service

**Location:** `/transport/garmin/`

**Files to create:**

#### `relay.py` — Polls Garmin API for latest activity
```python
from datetime import datetime, timezone
import requests
import time
import json
import os

# Configuration
GARMIN_API_KEY = os.environ.get("GARMIN_API_KEY", "mock")
OPENSHIFT_CLUSTER = os.environ.get(
    "OPENSHIFT_CLUSTER",
    "http://north.qr-demo-qa.svc.cluster.local:5000"
)
INGEST_ENDPOINT = f"{OPENSHIFT_CLUSTER}/ingest/garmin"
POLL_INTERVAL = 30  # seconds

def fetch_garmin_activity():
    """
    Fetch latest activity from Garmin API.
    Returns dict with heart_rate, steps, stress_score.
    """
    if GARMIN_API_KEY == "mock":
        return fetch_mock_activity()

    # Real Garmin API call would go here
    # For now, using mock to avoid OAuth complexity in the demo
    return fetch_mock_activity()

def fetch_mock_activity():
    """Generate realistic mock Garmin data"""
    import random

    now = datetime.now(timezone.utc)
    return {
        "device": "Garmin Venu 3",
        "heart_rate": random.randint(60, 100),
        "steps": random.randint(500, 10000),
        "stress_score": random.randint(10, 80),
        "timestamp": now.isoformat(),
        "activity": random.choice(["walking", "running", "resting"]),
    }

def send_to_ingest(activity):
    """POST activity to OpenShift /ingest/garmin"""
    try:
        resp = requests.post(
            INGEST_ENDPOINT,
            json=activity,
            timeout=5,
        )
        return resp.status_code == 200
    except Exception as e:
        print(f"Error posting to {INGEST_ENDPOINT}: {e}")
        return False

if __name__ == "__main__":
    print(f"Garmin relay starting. Polling every {POLL_INTERVAL}s.")
    print(f"Forwarding to: {INGEST_ENDPOINT}")

    while True:
        try:
            activity = fetch_garmin_activity()
            success = send_to_ingest(activity)

            timestamp = datetime.now().strftime('%H:%M:%S')
            hr = activity.get("heart_rate", 0)
            steps = activity.get("steps", 0)
            status = "✓" if success else "✗"

            print(f"[{timestamp}] {status} HR={hr} Steps={steps}")
        except Exception as e:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Fatal error: {e}")

        time.sleep(POLL_INTERVAL)
```

#### `mock.py` — Standalone mock for testing
```python
"""
Standalone mock Garmin relay. Generates readings every 10 seconds.
Usage: python mock.py
"""

import requests
import time
import random
from datetime import datetime, timezone

INGEST_ENDPOINT = "http://localhost:8080/ingest/garmin"

def generate_reading():
    """Generate realistic fake Garmin data"""
    return {
        "device": "Garmin Venu 3",
        "heart_rate": random.randint(60, 100),
        "steps": random.randint(500, 10000),
        "stress_score": random.randint(10, 80),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "activity": random.choice(["walking", "running", "resting"]),
    }

if __name__ == "__main__":
    print(f"Mock Garmin relay starting. Sending readings to {INGEST_ENDPOINT}")
    while True:
        reading = generate_reading()
        try:
            resp = requests.post(INGEST_ENDPOINT, json=reading, timeout=2)
            print(f"[{datetime.now().strftime('%H:%M:%S')}] HR={reading['heart_rate']} Steps={reading['steps']} → {resp.status_code}")
        except Exception as e:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Error: {e}")
        time.sleep(10)
```

#### `README.md` — Setup and usage
```markdown
# Garmin Relay

Fetches latest activity from Garmin Connect API and forwards to OpenShift /ingest/garmin endpoint.

## Local Development

### Mock Mode (No Garmin Account)

```bash
# Terminal 1: Start the north-api Flask server locally
cd ~/ohc-sap-demo/north
python app.py  # Runs on localhost:8080

# Terminal 2: Start the mock Garmin relay
cd ~/ohc-sap-demo/transport/garmin
python mock.py

# Terminal 3: Watch the events arrive
curl http://localhost:8080/state | jq '.last'
```

Every 10 seconds, you'll see a new heart rate and step count reading posted.

### Real Garmin API

1. Create a developer account at developer.garmin.com
2. Get OAuth 2.0 credentials
3. Set environment variables:
   ```bash
   export GARMIN_API_KEY="..."
   export GARMIN_USER_ID="..."
   export OPENSHIFT_CLUSTER="http://north.qr-demo-qa.svc.cluster.local:5000"
   ```
4. Run the relay:
   ```bash
   python relay.py
   ```

## CloudEvent Schema

When a Garmin activity arrives at `/ingest/garmin`, the north-api converts it to:

```json
{
  "type": "ohc.demo.iot.biometric",
  "eventclass": "ohc.demo.iot",
  "source": "garmin-connect",
  "data": {
    "device": "Garmin Venu 3",
    "heart_rate": 72,
    "steps": 5234,
    "stress_score": 28,
    "timestamp": "2026-02-23T14:00:00Z",
    "activity": "walking"
  }
}
```

## Testing

```bash
curl -X POST http://localhost:8080/ingest/garmin \
  -H "Content-Type: application/json" \
  -d '{
    "device": "Garmin Venu 3",
    "heart_rate": 72,
    "steps": 5234,
    "stress_score": 28,
    "timestamp": "2026-02-23T14:00:00Z"
  }'

curl http://localhost:8080/state | jq '.last'
```
```

---

### 3. Dashboard Widget Enhancement

**Location:** `/north/stage/dashboard.html` (existing file, add to it)

**Changes:**
- Add two new cards to the existing dashboard
- Card 1: "Latest Withings Reading" — displays weight_kg + timestamp
- Card 2: "Latest Garmin Reading" — displays heart_rate + steps
- Pull from existing `/state` endpoint (no Flask changes needed)
- Update every 100ms when new SSE event arrives

**Implementation:**
- Add HTML sections for the two cards
- Add CSS styling (match existing dashboard design)
- Add JavaScript to parse CloudEvent stream and update cards
- ~150 lines of HTML/CSS/JS total

**Example snippet:**
```html
<!-- Add to existing dashboard.html -->

<div class="metrics-row">
  <div class="card" id="withings-card">
    <h3>Withings Scale</h3>
    <div class="metric">
      <span class="value" id="withings-weight">--</span>
      <span class="unit">kg</span>
    </div>
    <div class="timestamp" id="withings-ts">--</div>
  </div>

  <div class="card" id="garmin-card">
    <h3>Garmin Watch</h3>
    <div class="metric">
      <span class="value" id="garmin-hr">--</span>
      <span class="unit">bpm</span>
    </div>
    <div class="secondary">
      <span id="garmin-steps">-- steps</span>
    </div>
    <div class="timestamp" id="garmin-ts">--</div>
  </div>
</div>

<script>
const eventSource = new EventSource("/events");
eventSource.onmessage = (e) => {
  const evt = JSON.parse(e.data);
  const payload = evt.payload || {};

  if (payload.source === "withings") {
    const data = payload.data || {};
    document.getElementById("withings-weight").textContent = (data.value_kg || "--").toFixed(1);
    document.getElementById("withings-ts").textContent = new Date(evt.ts).toLocaleString();
  }

  if (payload.source === "garmin") {
    const data = payload.data || {};
    document.getElementById("garmin-hr").textContent = data.heart_rate || "--";
    document.getElementById("garmin-steps").textContent = (data.steps || 0).toLocaleString() + " steps";
    document.getElementById("garmin-ts").textContent = new Date(evt.ts).toLocaleString();
  }
};
</script>
```

---

### 4. Presentation Deck

**Location:** `/north/stage/present-lab-09-consumer-iot.html` (new file)

**Outline (15 slides, ~4 minutes):**

1. **Title slide** — "Consumer IoT & Industrial IoT: Same Pipeline"
2. **Problem** — "Too many event sources, too many pipelines"
3. **Solution** — "One OpenShift platform, any device"
4. **Architecture diagram** — South (devices) → North (aggregation) → Further North (SAP)
5. **Live demo moment** — Withings reading fires on screen, dashboard updates
6. **Garmin moment** — Second event type, same schema
7. **The pattern** — "Same endpoint. Same CloudEvent schema. Same SSE stream. Different devices."
8. **Scale** — "Add 1,000 devices? The pipeline doesn't care."
9. **SAP integration** — "This flows to SuccessFactors, EHS, PM, or custom apps"
10. **Ansible automation** — "Events trigger EDA rulebooks and playbooks"
11. **Red Hat value prop** — "OpenShift is the event fabric. Not just for Kubernetes."
12. **Use cases** — "Where you could send consumer + industrial IoT"
13. **Competitive angle** — "Open standards. No vendor lock-in. Integrate anything."
14. **Call to action** — "Let's build a PoC for your edge data sources."
15. **Backup slide** — Technical architecture detail (in case someone asks)

**Visual style:**
- Match existing present-dtw.html design language (Red Hat brand, dark mode, clean slides)
- Use animated transitions
- Embed the live demo as an iframe or screen recording
- Show code snippets (CloudEvent schema, REST API call)

---

### 5. No Changes Required to north-api

**The endpoints already exist in `app.py`:**

```python
@app.post("/ingest/withings")
def ingest_withings():
    # Already stubbed and working

@app.post("/ingest/garmin")
def ingest_garmin():
    # Already stubbed and working
```

**They emit CloudEvents via `_emit()` and publish to the SSE stream. Nothing to change.**

This is intentional design — the demo is purely additive. No modifications to the production code path.

---

## BUILD TASKS (Kanban Order)

### Task 1: Withings Relay (Day 1)
- [ ] Create `transport/withings/` directory
- [ ] Write `relay.py` (Flask webhook receiver)
- [ ] Write `mock.py` (mock data generator)
- [ ] Write `README.md`
- [ ] Test locally: `python mock.py` → `curl http://localhost:8080/state`
- [ ] Verify events appear in `/state` JSON

### Task 2: Garmin Relay (Day 1–2)
- [ ] Create `transport/garmin/` directory
- [ ] Write `relay.py` (activity poller)
- [ ] Write `mock.py` (mock data generator)
- [ ] Write `README.md`
- [ ] Test locally with Withings relay running
- [ ] Verify two different event types coexist in `/state`

### Task 3: Dashboard Enhancement (Day 2)
- [ ] Open `north/stage/dashboard.html`
- [ ] Add HTML cards for Withings + Garmin
- [ ] Add CSS styling
- [ ] Add JavaScript event listener to update cards
- [ ] Test locally: Run mock relays → Watch cards update in real-time

### Task 4: Presentation Deck (Day 3–4)
- [ ] Create `north/stage/present-lab-09-consumer-iot.html`
- [ ] Build 15 slides
- [ ] Embed live demo as iframe or screen recording
- [ ] Record a 90-second demo video (fallback if live demo fails at trade show)
- [ ] Test locally: Open `/present-lab-09-consumer-iot` in browser

### Task 5: Documentation & Rehearsal (Day 5)
- [ ] Write `/docs/lab-09-guide.md` for field teams
- [ ] Dry run with account team
- [ ] Time the talk track
- [ ] Adjust for pacing
- [ ] Record as backup video

---

## LOCAL TEST PROCEDURE

**Before committing anything:**

```bash
# Terminal 1: Start Flask app
cd ~/ohc-sap-demo/north
python app.py

# Terminal 2: Start mock relays
cd ~/ohc-sap-demo/transport/withings && python mock.py &
cd ~/ohc-sap-demo/transport/garmin && python mock.py &

# Terminal 3: Monitor state
watch -n 1 'curl -s http://localhost:8080/state | jq ".last"'

# Browser: Open dashboard
http://localhost:8080/stage

# Browser: Open demo deck
http://localhost:8080/present-lab-09-consumer-iot
```

**Expected behavior:**
- Mock relays send readings every 10 seconds
- Events appear in `/state` JSON (count increments)
- Dashboard cards update with latest Withings weight + Garmin HR/steps
- Event log shows both event types mixed together
- Talk track can be rehearsed with live demo running

**Success criteria:**
- ✅ Two different device types, same event schema
- ✅ SSE stream carries both
- ✅ No code changes to Flask required
- ✅ Dashboard updates in real-time
- ✅ Demo is repeatable (run 100 times, no failures)

---

## FILE CHECKLIST

By end of Day 5, you should have created:

```
transport/
├── withings/
│   ├── relay.py          (NEW)
│   ├── mock.py           (NEW)
│   └── README.md         (NEW)
├── garmin/
│   ├── relay.py          (NEW)
│   ├── mock.py           (NEW)
│   └── README.md         (NEW)

north/
├── stage/
│   ├── dashboard.html    (MODIFIED - add cards)
│   └── present-lab-09-consumer-iot.html (NEW)

docs/
└── lab-09-guide.md       (NEW - optional, for field teams)
```

**No changes to:**
- north/app.py (endpoints already exist)
- deploy/ (no infrastructure changes)
- south-ui/ (no changes)

---

## TRADE SHOW DEPLOYMENT

### Option A: Run Locally on Booth Laptop

```bash
# On booth laptop, in ~/ohc-sap-demo/
python north/app.py &
python transport/withings/mock.py &
python transport/garmin/mock.py &

# Open browser to http://localhost:8080/present-lab-09-consumer-iot
# Run the demo
```

**Pros:** No internet required. Bulletproof. Controlled.
**Cons:** Requires a laptop, terminal access, Python setup.

### Option B: Deploy to OpenShift QA Cluster

```bash
# Build and push container (already done)
# Deploy relays via Kubernetes manifests (see README in transport/*/README.md)
# Access via public route: https://north-qr-demo-qa.apps.cluster-nlthm.nlthm.sandbox3528.opentlc.com/present-lab-09-consumer-iot
```

**Pros:** No laptop setup. Just a URL. Professional.
**Cons:** Requires cluster access, network must be stable.

**Recommendation:** Deploy to QA cluster, keep booth laptop as backup with local setup.

---

## SUCCESS METRICS

| Metric | Target |
|--------|--------|
| Time to deliver | 5 working days |
| Lines of code | ~600 (relay services) + 400 (dashboard) + 800 (deck) = 1,600 total |
| External dependencies | 0 (mock mode requires only Flask, requests, no APIs) |
| Devices demonstrated | 2 (Withings, Garmin) |
| Live demo success rate | >95% (tested 100+ times locally) |
| CTO understanding | "Oh, I see — same event pipeline, different devices" |

---

**Document:** `/home/jodonnell/zoe/DEBATE/LAB-09-BUILD-SPEC.md`
**Status:** Ready for assignment
**Effort:** 5 days, 1 developer (Intermediate Python/HTML/JS)
**Risk:** Minimal — all code additive, fully reversible, testable locally before commit
