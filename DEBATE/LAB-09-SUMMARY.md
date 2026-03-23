# Lab #09 Summary: Executive One-Pager
## Consumer IoT → CloudEvents

**Trade Show:** SAP Insider, March 2026 | **Effort:** 5 days | **Risk:** None | **Value:** High

---

## THE PITCH (30 seconds)

> A Withings weigh-in becomes a CloudEvent. A Garmin heart rate reading becomes a CloudEvent. Both flow through the same OpenShift pipeline as factory sensors and badge readers. Your enterprise doesn't need separate IoT silos. One platform. Any edge device. Same integration to SAP.

---

## ANSWERS TO YOUR 6 QUESTIONS

| # | Question | Answer |
|---|----------|--------|
| **1** | Is "limbic kill shot" the right framing? | **No.** Reframe as *Unified Event Fabric for Mixed-Criticality IoT.* Addresses CTO consolidation problem, not engineering elegance. |
| **2** | Garmin vs Withings? | **Withings decisively.** Discrete events (weigh-ins), threshold-based actions, enterprise-relevant (wellness programs, compliance). Garmin is continuous point-in-time data. |
| **3** | SAP integration story? | **SuccessFactors Wellness** (employee wellness signals) + **SAP BTP Integration Suite** (flexible routing). Lead with SF, have BTP ready for architects. |
| **4** | Standalone or supporting moment? | **Supporting moment inside larger deck.** Fits inside "Unified Event Fabric," "Edge Strategy," or "SuccessFactors HR Transformation" presentations. Not enough content for 20-minute standalone. |
| **5** | Minimal customer-ready version? | **Phase 1 (5 days):** Withings relay + Garmin relay + dashboard widget. Mock data, no external APIs required. Ship this to booth. Phase 2 (optional): SAP integration. |
| **6** | One-line talk track? | *"That's a Withings reading. It's a CloudEvent now — same event schema as badge readers and factory sensors. Your enterprise doesn't fracture IoT into silos. One event fabric. One integration story to SAP. Pick the destination."* |

---

## BUILD PLAN

### Phase 1: Proof of Concept (Days 1–5)

**Deliverables:**
- `transport/withings/relay.py` + `mock.py` + README (100 lines)
- `transport/garmin/relay.py` + `mock.py` + README (100 lines)
- Dashboard enhancement: Add two cards to show Withings weight + Garmin heart rate (200 lines)
- Presentation deck: 15 slides, 4 minutes, live demo moment (800 lines HTML)

**No code changes to Flask required.** Endpoints already exist at `/ingest/withings` and `/ingest/garmin`.

**Why this works:** Fully testable locally with mock data. No external API tokens required. Demonstrates the pattern. Ship to booth.

### Phase 2: SAP Integration (Days 6–10, Optional)

**Deliverables:**
- Event router in Flask to forward CloudEvents to SAP BTP
- SuccessFactors wellness workflow trigger (sandbox)
- Extended presentation deck (add 2 slides showing integration)

**Only if you have SAP BTP credentials.** Phase 1 alone is sufficient.

### Phase 3: Ansible Automation (Days 11–15, Skip for Trade Show)

**Deliverables:**
- EDA rulebook listening to CloudEvents
- Playbook that sends Slack notification + creates ServiceNow ticket

**Not needed for trade show.** Overkill for the booth floor. Save for customer PoCs.

---

## COMPETITIVE POSITION

| Vendor | Says | Cannot Do | Lab #09 Does |
|--------|------|-----------|-------------|
| Azure IoT Hub | "All-in-one IoT" | Integrate SAP without custom work | Shows native SAP integration |
| AWS IoT Core | "Massive scale, flexible" | Same code path on-prem + AWS | Runs on OpenShift anywhere |
| GCP Cloud IoT | "Easy on-ramp" | Real enterprise integration | CloudEvents + SAP BTP = solved |

**Red Hat + SAP unique position:** Open standards (CloudEvents) + on-prem infrastructure (OpenShift) + enterprise decision system (SAP). No vendor lock-in.

---

## TALK TRACK (90 seconds, rehearse this)

> *[Demonstrate a Withings weigh-in firing on screen. It appears on the dashboard.]*
>
> That's a weight reading from Jim's personal Withings scale. It's a CloudEvent now — same event schema as the badge readers, factory sensors, and vehicle telemetry in our other labs.
>
> Your enterprise doesn't need separate pipelines for industrial vs. consumer IoT. One event fabric. One integration layer to SAP. One decision point.
>
> Want to route it to SuccessFactors for wellness tracking? To EHS for compliance? To a custom app? Pick the destination. The device doesn't care. Add 10,000 more device types? The architecture doesn't change. You don't get vendor lock-in. You don't need 10 different API teams.
>
> *[Show the CloudEvent schema in the code]*
>
> This is CloudEvents, an open standard. Not proprietary. You own it. We own it. Your customers own it.

**If they ask "why would we monitor employee fitness?":**
> Replace Withings with your supply chain GPS, your building HVAC sensors, your field technician location beacons. Same architecture. Same decision layer. Consolidation without complexity.

---

## FILES TO CREATE

```
transport/withings/
├── relay.py          (Flask webhook receiver)
├── mock.py           (generates fake readings)
└── README.md         (setup + testing guide)

transport/garmin/
├── relay.py          (activity poller)
├── mock.py           (generates fake readings)
└── README.md         (setup + testing guide)

north/stage/
├── dashboard.html    (MODIFY: add Withings + Garmin cards)
└── present-lab-09-consumer-iot.html (NEW: 15-slide deck)

docs/
└── lab-09-guide.md   (optional: field team guide)
```

**No changes to app.py.** Endpoints already exist.

---

## LOCAL TESTING (Before Booth)

```bash
# Terminal 1: Start Flask app
cd ~/ohc-sap-demo/north && python app.py

# Terminal 2: Start mock relays
cd ~/ohc-sap-demo/transport/withings && python mock.py &
cd ~/ohc-sap-demo/transport/garmin && python mock.py &

# Terminal 3: Watch events arrive
watch -n 1 'curl -s http://localhost:8080/state | jq ".last"'

# Browser: Dashboard with live updates
http://localhost:8080/stage

# Browser: Full presentation deck
http://localhost:8080/present-lab-09-consumer-iot
```

**Expected:** Two different device types, same event schema, same SSE stream, no errors. Run 100 times. Never fails. (This is the standard for trade show demos.)

---

## BOOTH DEPLOYMENT OPTIONS

### Option A: Local on Laptop (Safest)
- Run north-api + relays locally on booth laptop
- No internet required
- Pros: Bulletproof. Controlled. Cons: Requires terminal access.

### Option B: OpenShift QA Cluster (Professional)
- Deploy relays to OpenShift
- Access via HTTPS URL
- Pros: No laptop setup. Cloud-native. Cons: Network dependency.

**Recommendation:** Deploy to QA cluster, keep local backup.

---

## SUCCESS CRITERIA

- ✅ CTO says: "Oh, I see — same pipeline, different devices"
- ✅ Account exec gets 3+ follow-up conversations
- ✅ Demo runs 100 times without failing
- ✅ Talk track is tight (exactly 90 seconds)
- ✅ Presentation fits inside larger deck (supporting moment, not standalone)
- ✅ CloudEvent schema is visible in the demo
- ✅ SAP integration is mentioned (but doesn't need to be live)

---

## COMPETITIVE ANGLES (If Asked)

| Question | Answer |
|----------|--------|
| "Why not just buy Azure IoT Hub?" | You can. But then you're locked into Azure for IoT and need custom integration to SAP. We give you OpenShift + SAP integration out of the box. |
| "How is this different from AWS IoT Core?" | Same problem — AWS lock-in, custom integrations. We run on-prem in OpenShift. Same code path everywhere. |
| "Does this scale?" | CloudEvents is stateless. Kubernetes scales horizontally. Yes, easily. 10,000 devices, no code changes. |
| "What happens if we add a new device type?" | POST to /ingest with a CloudEvent. That's it. No redeployment. No new code. |

---

## RISK MITIGATION

| Risk | Mitigation |
|------|-----------|
| Live demo fails | Have a pre-recorded video (90 seconds) as backup. Play it on the big screen. |
| CTO asks for a real device integration | That's a PoC conversation. "Let's pick your most common device type and wire it up in 2–3 weeks." |
| Sales oversells; customer expects day-one scale | "This is the architecture pattern. Scaling your edge data is a 6–9 month project. We'll help plan it." |
| Audience is non-technical (ops, purchasing) | Pivot talk track: "Reduce OpEx by consolidating platforms. One vendor. One support contract. One integration story." |

---

## NEXT STEPS

1. **Assign Phase 1** to a developer (5 days, Python/HTML/JS)
2. **Create local demo** and test it 10+ times
3. **Record backup video** (90 seconds) of the demo running
4. **Rehearse talk track** with account team
5. **Deploy to QA cluster** 1 week before trade show
6. **Dry run booth setup** with live network (to catch any surprises)
7. **Brief booth staff** on the talk track and objection handling

---

## DOCUMENTS CREATED FOR YOU

| Document | Purpose | Audience |
|----------|---------|----------|
| **LAB-09-CONSUMER-IOT-BRIEF.md** | Strategic architecture critique + 6-question framework | You, architect, decision-makers |
| **LAB-09-BUILD-SPEC.md** | Detailed technical specification + code outlines | Developer who builds it |
| **LAB-09-COMPETITIVE-BRIEF.md** | Market positioning, account strategy, lead qualification | Account team, sales enablement |
| **LAB-09-SUMMARY.md** | This document. One-pager for quick reference | Everyone (booth staff, pre-call briefing) |

---

## THE STORY (Why This Matters)

**Today:** Enterprises have 5+ IoT programs from 5+ vendors. Each has its own schema, integration path, and operational overhead. The cost and complexity are unbearable.

**Our message:** One event layer (Red Hat OpenShift) + One integration point (SAP BTP) = Consolidation. Open standards (CloudEvents). Any device. Any destination.

**Lab #09 is proof:** A consumer smartwatch flows through the same pipeline as an industrial sensor. If you believe that, you believe the architecture scales to your supply chain, your facilities, your fleet.

**The close:** "Let's do a PoC. Pick your top 3 data sources. We'll wire them up in 6 weeks. You'll see the consolidation ROI in the first month."

---

**Created:** 2026-02-23
**Status:** Ready for booth
**Files:** 4 documents, ~15,000 words
**Next:** Assign build, schedule rehearsal, execute

---

**Prepared by:** Zoe (Enterprise Demo Architect)
**For:** Red Hat Account Team + SAP Sales
**Event:** SAP Insider Trade Show, March 2026
