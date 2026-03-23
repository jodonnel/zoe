# Lab #09: Consumer IoT → CloudEvents
## Complete Documentation Index

**Date Created:** 2026-02-23
**Trade Show:** SAP Insider, March 2026
**Effort:** 5 working days
**Risk:** Minimal (additive code, fully testable locally)

---

## DOCUMENTS

### 1. LAB-09-CONSUMER-IOT-BRIEF.md
**Purpose:** Strategic architecture critique + answers to 6 core questions
**Length:** ~7,200 words
**Audience:** Decision-makers, architects, you
**Contents:**
- ✅ Framing analysis (why "limbic kill shot" is a distraction)
- ✅ Device selection (Withings > Garmin for demo impact)
- ✅ SAP integration options (SuccessFactors Wellness recommended)
- ✅ Demo positioning (supporting moment, not standalone)
- ✅ Minimal customer-ready version (3 phases: PoC → Integration → Automation)
- ✅ 90-second talk track (the pitch that makes CTOs lean forward)
- ✅ Architecture summary & strategic rationale

**Key insight:** "Limbic kill shot" appeals to engineers. CTOs care about consolidation. Reframe the demo as proof of unified event fabric, not architectural elegance.

**Read this first if:** You need to understand what Lab #09 is *for* and why it matters strategically.

---

### 2. LAB-09-BUILD-SPEC.md
**Purpose:** Technical specification + code examples + build tasks
**Length:** ~6,800 words
**Audience:** Developer who builds it, technical team lead
**Contents:**
- ✅ Withings relay service (Flask webhook receiver + mock)
- ✅ Garmin relay service (activity poller + mock)
- ✅ Dashboard enhancement (HTML/CSS/JS for live updates)
- ✅ Presentation deck outline (15 slides, 4 minutes)
- ✅ Kanban build tasks (5 tasks, 5 days)
- ✅ Local test procedure (runnable commands)
- ✅ File checklist (what to create)
- ✅ Trade show deployment options (local vs. cluster)
- ✅ Success metrics

**Key detail:** All code is additive. No changes to Flask. Endpoints already exist. This is a 5-day sprint with zero risk.

**Read this next if:** You're the developer building it, or you're managing the build.

---

### 3. LAB-09-COMPETITIVE-BRIEF.md
**Purpose:** Market positioning, competitive vulnerabilities, account strategy
**Length:** ~5,500 words
**Audience:** Sales team, account execs, marketing
**Contents:**
- ✅ Market position vs. Azure IoT, AWS IoT, GCP
- ✅ Why now (market maturity, SAP strategy alignment, Red Hat positioning)
- ✅ Competitive vulnerabilities (what each vendor cannot easily do)
- ✅ CTO decision tree (how the demo creates buying signals)
- ✅ Account strategy (who should see this, by tier)
- ✅ Revenue thread (from booth to opportunity to ARR)
- ✅ Messaging templates (email, elevator pitch, objection answers)
- ✅ Supporting collateral checklist
- ✅ Success metrics (booth traffic, follow-ups, PoCs)

**Key framing:** Lab #09 is not about IoT. It's about consolidation. One platform. One integration. Open standards.

**Read this if:** You're an account exec, you're preparing for the booth, or you're handling competitive objections.

---

### 4. LAB-09-SUMMARY.md
**Purpose:** One-pager for quick reference + desk-side guide
**Length:** ~3,200 words
**Audience:** Everyone (booth staff, pre-call briefing, team alignment)
**Contents:**
- ✅ 30-second pitch
- ✅ Answers to all 6 questions (table format)
- ✅ Build plan (phases 1–3, effort, deliverables)
- ✅ Competitive position (table)
- ✅ 90-second talk track (exactly what to say)
- ✅ Files to create (quick reference)
- ✅ Local testing (copy-paste commands)
- ✅ Booth deployment options
- ✅ Success criteria checklist
- ✅ Competitive angles (FAQ format)
- ✅ Risk mitigation table
- ✅ Next steps
- ✅ Document index

**Read this if:** You're on the booth floor, you need the elevator pitch, or you're running a pre-call briefing.

---

## HOW TO USE THESE DOCUMENTS

### Before You Start Building (Days 1–2)
1. Read **LAB-09-CONSUMER-IOT-BRIEF.md** fully (understand the "why")
2. Skim **LAB-09-SUMMARY.md** for the 30-second pitch
3. Review **LAB-09-BUILD-SPEC.md** to understand scope

### During Build (Days 3–7)
1. Use **LAB-09-BUILD-SPEC.md** as your spec (follow the Kanban tasks)
2. Reference the code examples in **BUILD-SPEC.md** for implementation
3. Check off tasks in **BUILD-SPEC.md** as you complete them

### Before Trade Show (1 week out)
1. Rehearse the **90-second talk track** from **LAB-09-SUMMARY.md**
2. Run **local test procedure** from **BUILD-SPEC.md** (10+ times)
3. Review **LAB-09-COMPETITIVE-BRIEF.md** to prep objection answers

### At the Booth (Trade show)
1. Print **LAB-09-SUMMARY.md** (have it visible as a cheat sheet)
2. Keep **90-second talk track** in your head (rehearsed)
3. Use **messaging templates** from **COMPETITIVE-BRIEF.md** for follow-ups
4. Reference **CTO decision tree** from **COMPETITIVE-BRIEF.md** when qualifying leads

### In Follow-up Conversations (Post-booth)
1. Use **revenue thread** from **COMPETITIVE-BRIEF.md** to progress the deal
2. Reference **risk mitigation** from **SUMMARY.md** to set expectations
3. Point to full **LAB-09-CONSUMER-IOT-BRIEF.md** for architecture credibility

---

## KEY DECISIONS (Already Made For You)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Framing** | Unified Event Fabric (not "limbic kill shot") | Speaks to CTO consolidation problem, not engineering cleverness |
| **Device priority** | Withings scale > Garmin watch | Discrete events, threshold-based, enterprise-relevant |
| **SAP integration** | SuccessFactors Wellness (primary) + BTP (backup) | SF = employee wellness (human capital angle), BTP = flexibility |
| **Demo positioning** | Supporting moment (inside larger deck) | Not enough content for standalone; fits inside 5+ other presentations |
| **Build phases** | Phase 1 (PoC) → Phase 2 (SAP) → Phase 3 (Ansible) | Ship Phase 1 to booth. Phase 2 optional. Phase 3 skip for trade show. |
| **Talk track** | 90-second live demo moment + narrative | Tight, repeatable, addresses CTO's actual problem |
| **Deployment** | OpenShift QA cluster (primary) + local backup (secondary) | Professional + safe fallback |

---

## SUCCESS CRITERIA (How You Know It's Working)

### Booth Floor
- [ ] CTO says "Oh, I see — same pipeline, different devices"
- [ ] Demo runs live without failures (tested 100+ times locally)
- [ ] Account exec gets 3+ follow-up conversations ("tell me more")
- [ ] Audience understands the consolidation story (not just "cool tech")

### Sales Pipeline
- [ ] 10+ qualified leads (CTOs with multiple IoT programs)
- [ ] 3+ PoC conversations initiated within 60 days
- [ ] 1+ PoC deal signed (Phase 1 architecture work)

### Long-term
- [ ] Customer uses this pattern for their own IoT data sources
- [ ] Expands to supply chain, facilities, field operations
- [ ] Becomes ARR driver for OpenShift + SAP BTP subscriptions

---

## WHAT NOT TO DO

### Don't
- [ ] Oversell this as "production IoT platform" (it's a PoC)
- [ ] Try to run Phase 2 (SAP) without real SAP BTP credentials (too risky at booth)
- [ ] Skip local testing and go straight to cluster deployment (demo failures kill credibility)
- [ ] Ad-lib the talk track (rehearse it until it's tight, then stick to it)
- [ ] Use a real Withings device at the booth (mock data is safer, more repeatable)
- [ ] Make this a 20-minute standalone presentation (supporting moment only)
- [ ] Claim this is "different from AWS" in the broad architecture sense (claim is it's different in SAP integration path and on-prem portability)

---

## CRITICAL PATH (5 Days to Booth-Ready)

```
Day 1: Withings relay (relay.py + mock.py) → test locally
Day 2: Garmin relay (relay.py + mock.py) → test locally with Withings
Day 3: Dashboard enhancement (add cards) → live demo works
Day 4: Presentation deck (15 slides) → talk track rehearsal
Day 5: Testing & backup → record video (fallback)

Pre-booth (1 week out):
- Deploy to QA cluster
- Dry run with network
- Rehearse with account team
- Finalize messaging

Trade show:
- Run demo 10+ times before first visitor
- Use script (don't improvise)
- Gather feedback, iterate
- Qualify leads
```

---

## FILE STRUCTURE (What You'll Create)

```
transport/withings/
├── relay.py              ← Flask webhook receiver
├── mock.py               ← Mock data generator (for testing)
└── README.md             ← Setup guide (no SAP account required)

transport/garmin/
├── relay.py              ← Activity poller
├── mock.py               ← Mock data generator
└── README.md             ← Setup guide

north/stage/
├── dashboard.html        ← MODIFY: add two cards for live metrics
└── present-lab-09-consumer-iot.html  ← NEW: 15-slide presentation deck

docs/
└── lab-09-guide.md       ← OPTIONAL: field team reference guide
```

**No changes to app.py.** Endpoints `/ingest/withings` and `/ingest/garmin` already exist.

---

## CONTACT & ESCALATION

### If you have questions about:

| Question | Reference Document |
|----------|-------------------|
| **Why build this demo?** | LAB-09-CONSUMER-IOT-BRIEF.md (sections 1–2) |
| **How to build it?** | LAB-09-BUILD-SPEC.md (entire document) |
| **What to say at the booth?** | LAB-09-SUMMARY.md (section on talk track) + LAB-09-CONSUMER-IOT-BRIEF.md (section 6) |
| **How to answer competitive objections?** | LAB-09-COMPETITIVE-BRIEF.md (risk section, competitive angles) |
| **Is this enough for trade show?** | LAB-09-SUMMARY.md (success criteria) |
| **What if the live demo fails?** | LAB-09-BUILD-SPEC.md (trade show deployment section) + LAB-09-COMPETITIVE-BRIEF.md (risk mitigation) |

---

## FINAL THOUGHT

**Lab #09 is not about IoT. It's about making a CTO believe that Red Hat + SAP give them a consolidated edge event platform that doesn't lock them to a single vendor.**

The Withings smartwatch is just the prop. The story is: *one architecture, any device, open standards, integrated to SAP.*

Everything in these four documents is designed to tell that story consistently — from strategy to booth to follow-up.

---

**Created:** 2026-02-23
**Status:** Ready to assign
**Next step:** Assign Phase 1 build to a developer

---

**Index maintained by:** Zoe (Enterprise Demo Architect)
**For:** Red Hat Account Team + SAP Sales
