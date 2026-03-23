# Scout Report: Job Coach Demo
## Business & Technical Analysis for Narration & Feasibility

---

## 1. BUSINESS PROPOSITION

### Who is the buyer?

**Primary:** State/federal disability employment agencies, vocational rehabilitation bureaus, large disability services organizations (like The Arc, local DSP networks).

**Secondary:** School districts with transition programs (ages 18-21). Smaller: individual DSPs or employment support franchises.

**Buyer's buying committee:**
- **Director of Employment Services** — sees workforce development outcome metrics
- **Chief Financial Officer** — cost-per-job-placement, per-month support hours
- **Compliance/Privacy Officer** — HIPAA, FERPA, state data protection rules
- **IT/Operations** — edge device deployment, training burden, support model

### What pain does this solve?

**For disability services organizations:**
- DSPs are in short supply, burned out, inconsistently trained
- Manual job coaching is expensive (~$25-40/hour) and doesn't scale
- Inconsistency: same job coached differently by different DSPs
- Documentation is scattered—no reproducible task library
- Privacy pain: current assistive tech often involves constant video/audio to cloud
- Measurement pain: hard to track progress, prove ROI to funders

**For the person with IDD (Brian):**
- Independence without constant human proximity
- Dignity: coaching on your terms, not parental oversight
- Consistency: the task sequence Brian learned stays reliable
- Speed: no wait time for a DSP to be available
- Control: his data isn't living in a cloud somewhere

### What's the emotional hook?

Not "We'll help you manage disabled workers." 

**The hook:** "What if someone with IDD could do their job *without a handler*? What if they *chose* when they needed help, instead of having help *chosen for them*?"

Slide 1 opens with "What if Brian could work *independently*?" The subhead anchors it: glasses he already wears, AI running locally. 

**The implicit promise:** Dignity through agency. Not charity. This matters for sales positioning. You're not selling "help for disabled people." You're selling "employment independence platform that removes the DSP bottleneck and scales coaching."

### What's the actual market opportunity?

**Serviceable Addressable Market (SAM):**
- 5.4M adults with IDD in US
- <20% currently employed
- If you target "people who *want* to work and have employer access," that's probably 800K–1.2M
- If 30% of those organizations adopt edge AI coaching in 5 years, that's 240K–360K deployed devices

**Revenue model (implicit in brief, needs clarity):**
- Per-device licensing ($50–150/month)?
- Per-DSP seat (DSP interface on Slide 4 suggests SaaS)?
- Per-placement success fee?
- Government contract vehicle (VR agencies buying in bulk)?

**Beachhead strategy (what's implied):**
- Start with 2–3 large disability services orgs (proof of concept)
- Prove 15–20% employment rate lift
- Scale through state VR partnerships
- Expand to school districts

### What objections will come up in a sales conversation?

**Cost & ROI:**
- "How much cheaper is this than hiring another DSP?" (Objection: If DSPs cost $80K+ loaded, you need to show <$300/month per device for ROI at scale)
- "What's the payback period?" (Objection: They'll want to see job placements attributed to the tool within 6–12 months)

**Adoption & Change Management:**
- "Our DSPs will see this as a threat to their jobs." (Objection: Reframe as "DSPs become task designers, not firefighters," but this is a *culture* problem, not a tech problem)
- "We already use [assistive tech provider]—why switch?" (Objection: Sticky incumbent (TalkTablet, ProloQuo2Go, Predictable, etc.). You need to show 10x better UX or 10x cheaper)

**Data & Privacy:**
- "Our state requires all special education data in a certified SIEM." (Objection: Edge-first is good here, but federated learning via CloudEvents means *some* data moves. You need a privacy impact assessment)
- "What happens if the device is lost or stolen? HIPAA liability?" (Objection: Local-first is a feature, but you need incident response playbooks)

**Feasibility & Support:**
- "We can't deploy RHEL Image Mode to 200 Ray-Bans on our own. What's the managed service?" (Objection: You're implying a one-time implementation. They need ongoing support.)
- "What if Granite or Watson STT gets a job task wrong? Who's liable?" (Objection: AI safety/UX fallback needs to be crystal clear)

**Competitive Pressure:**
- "Google is building accessibility tools. SAP already has HR systems. Why not wait for them?" (Objection: You're positioned as *niche deep*, not *broad ecosystem*. Defend turf, not scale)

---

## 2. TECHNICAL PROPOSITION

### What's real vs. aspirational?

**REAL (Built, works, in the demo):**
- Meta Ray-Ban hardware: camera, mic, bone conduction audio — shipping product, not prototype
- Watson STT & TTS (Edge variant): IBM has a local-inference story; edge-tts + Jenny Neural are already built
- SAP BTP as workflow engine: mature platform, proven at enterprise scale
- RHEL Image Mode: Red Hat's shipping product; atomic image-based updates are real
- Task library concept: straightforward database schema, no AI magic needed

**ASPIRATIONAL (Technically sound, but implementation detail matters):**
- IBM Granite fine-tuning on "new task data" (Slide 5): Granite is solid, but "fine-tune on task data" is vague. What's the training loop? How much data do you need? Turnaround time?
- Federated learning loop via CloudEvents (Slide 5): *Technically* possible, but "Brian's corrections ship back as CloudEvents, cluster retrains, next image includes improvements" is *architecture-level aspirational*. 
  - Real question: How do you capture corrections? (User feedback? DSP review? Both?)
  - How often does retraining happen? (Weekly? Daily? Per-device?)
  - How do you version-pin devices during training cycles?
  - If Granite is fine-tuned, do you need retraining on *every* task, or just high-error ones?

**EDGE CASE (Works, but risky claims):**
- "Danger Steering: real-time alerts for unsafe situations. Vision model runs locally." (Slide 3)
  - Question: Which vision model? Granite? Something else? 
  - How is "dangerous" defined? Hardcoded rules or ML-based?
  - What's the false positive rate? (If the glasses keep false-alarming, people stop wearing them)
  - Liability: If Danger Steering misses a real hazard, who's responsible?

### What's genuinely novel?

**Yes, genuinely novel:**
- **Edge-first coaching for disability services.** No one else is doing real-time AI job coaching on eyeglasses for IDD populations. This is a category-creating move.
- **Privacy-first architecture for a vulnerable population.** Recording every move to cloud is the current standard. Local-first + federated learning is a genuine shift.
- **Bootc image versioning for ML model updates.** Using atomic OS image updates to deploy new trained models is clever. Most ML deployment is ad-hoc; this is infrastructure-grade.

**Partially novel (good, but not unique):**
- Ray-Ban glasses as the form factor: Apple, Google, and others are chasing this. Ray-Ban + AI is a market trend.
- Granite + Watson STT locally: IBM's play. Solid but not exclusive.

### What's the hardest technical claim to defend?

**Slide 5: "Federated learning loop."**

The claim: Brian's corrections → CloudEvents → cluster retrains → next image includes his improvements.

**Why it's hard to defend:**
1. **Federated learning for small, heterogeneous tasks is unsolved.** Academic research exists, but production deployments are rare. If Brian's job is "stock the shelf," and Maria's job is "operate a register," the task distribution is *highly* non-IID. Standard federated learning assumes similar data distributions across clients.
2. **Version coordination is a nightmare.** If Device A is running Model v3 and Device B is running Model v5, and both ship corrections, how do you coordinate retraining? Bootc solves *deployment*, not *model governance*.
3. **Liability + consent.** "Brian's corrections" → if Brian is non-verbal or cognitively can't consent to his data being used for retraining, how do you handle it? Legal teams will ask this.
4. **Feedback loop quality.** How is a "correction" captured? Is it DSP review? User thumbs-up/down? If it's user feedback from someone with IDD, signal-to-noise ratio is an open question.

**Second hardest: Slide 3, "Social Navigation."**

"Guided prompts for ordering food, checking out, small talk."

This is the most *culturally* sensitive claim. Teaching someone with IDD how to do "small talk" via AI prompts could easily come across as *controlling* instead of *enabling*. Narration will need to frame this very carefully: it's not "teaching you to fake normalcy," it's "giving you a confidence script if you need one." This is an *emotional* objection, not a technical one, but it's lethal to the pitch if handled wrong.

---

## 3. WHAT EACH SLIDE IS DOING

### Slide 1 — Hook ("What if Brian could work independently?")

**Job:** Establish emotional frame and premise. Answer "why should I care?"

**What it does well:**
- Opens with a *person*, not a product
- "What if" framing is aspirational, not pitying
- Subhead immediately anchors to something tangible: Ray-Ban glasses (familiar form factor), edge AI (solves privacy concern implicitly), already wears (removes friction)
- Hierarchy is correct: emotional hook first, then the *how*

**What's unsaid:**
- Who is Brian? (Is he a real person? Composite? Ideal case?) Narration can answer: "Brian is an adult with intellectual and developmental disabilities. He wants to work. He's willing to learn. But he needs real-time support." This makes him *real*.
- Why does independence matter? Narration can add: "For most people, independence at work is a given. For someone with IDD, it's fought for. It's dignity." This primes the emotion for the rest of the deck.

**Narration moment:** This slide *needs* a human voice to land. Text alone is a promise. A voice saying "What if..." with the right tone (hopeful, not patronizing) turns it into a conviction.

---

### Slide 2 — The Problem (5.4M adults, <20% employment, DSP bottleneck, privacy)

**Job:** Establish urgency and scope. Why is this not being solved already?

**Structure:**
- **Market size:** 5.4M adults with IDD, <20% employment → "This is a big problem"
- **Root cause 1:** Assistive tech lags consumer tech by decades, single-purpose, expensive, stigmatizing → "Why hasn't tech solved it?"
- **Root cause 2:** Job coaching is manual, inconsistent, DSPs can't scale → "Why is it still manual?"
- **Root cause 3:** Independence requires real-time support: task sequences, danger awareness, social navigation → "What's missing?"
- **Root cause 4:** Privacy matters. Cloud recording undermines autonomy → "And the current 'solution' is worse than the problem"

**What it does well:**
- Stacks three layers of pain: market pain → tech industry pain → operational pain → privacy pain
- Ends on privacy, which is *emotional* (autonomy, dignity) not just technical
- Facts (5.4M, <20%) are credible

**What's unsaid:**
- **Assistive tech lags by decades:** What does that mean in concrete terms? Narration should say: "If you buy a job coach app in 2025, it probably launched in 2015. It costs $1,500 to $3,000 per license. It's designed for tablets, not glasses. And every interaction gets logged to a vendor's server."
- **DSP burnout:** Narration could add a sentence: "A DSP (Direct Support Professional) earns $28,000–$35,000 a year and spends 8 hours a day with the same person doing repetitive coaching. High burnout, high turnover, inconsistent support."
- **Privacy as autonomy:** The slide says "Recording everything to the cloud undermines autonomy." True, but why? Narration: "If someone with an intellectual disability knows every move is being recorded and watched, they're not practicing independence—they're being monitored. There's a difference."

**Narration moment:** The privacy point is easy to miss as a technical feature. Voice narration can plant the idea that this is *moral*, not just *technical*. "All that support should be *with* him, not *about* him."

---

### Slide 3 — The Solution (Three capabilities, edge-first)

**Job:** Reframe the problem as solvable by *this* specific platform. Answer "how?"

**Structure:**
- **Job Task Coaching:** step-by-step audio prompts, learned once with DSP, replayed on demand → "No need for DSP to be there in person"
- **Danger Steering:** real-time alerts for unsafe situations, local vision model → "Safety is still there, just automated"
- **Social Navigation:** guided prompts for ordering food, etc. → "Soft skills coaching, on demand"
- **Privacy-first:** all inference at edge, no cloud recording → "And your data is yours"

**What it does well:**
- Three capabilities map to three pain points from Slide 2 (DSP bottleneck, real-time support, danger awareness)
- Privacy-first is the *fourth* capability, framed as a principle, not a feature
- Language is concrete: "step-by-step audio prompts," not "conversational AI interface"

**What's unsaid:**
- **How does Task Coaching work?** Narration can fill in: "A DSP records a task once. They talk Brian through it: 'Pick up the box. Find the tag on the shelf. Place items left to right.' Brian listens and does. Later, without the DSP there, Brian can replay that exact sequence anytime."
- **Danger Steering credibility:** This is the most speculative. Narration should be cautious: "The system watches for unsafe situations—like walking toward a moving forklift, or reaching for something that could break. If it detects danger, it alerts Brian in real time."
- **Social Navigation framing:** This needs careful narration. Not "teaching Brian to fake socializing," but "giving Brian confidence scripts if he needs them." Example: "At the register, ordering can be awkward. The system can coach: 'Say your order. Listen to the total. Hand the card.' Prompts, not instructions."

**Narration moment:** All three. Each capability needs a voice explaining the *why* before the *what*. Text alone risks sounding like a feature list. Voice can make it sound like a system that *understands* the job.

---

### Slide 4 — Architecture (Meta Ray-Ban → Device Edge → SAP BTP)

**Job:** Prove it's *buildable*, not just a concept. Show the tech stack. Answer "is this real?"

**Structure:**
- **Meta Ray-Ban:** camera, mic, bone conduction audio → hardware is the form factor
- **Device Edge:** RHEL Image Mode, IBM Granite, Watson STT, TTS → local inference
- **SAP BTP:** task library, analytics, DSP interface → backend + ops

**What it does well:**
- Flows left-to-right (hardware → edge → cloud), easy to follow
- Each component is a *real product*, not vaporware (Ray-Ban is shipping, RHEL Image Mode is shipping, Granite is open, Watson is real)
- Graphic likely shows data flows (camera → device → decision, not always to cloud)

**What's unsaid:**
- **Why these tech choices?** Narration can add credibility: "We chose IBM Granite because it's open-source and lightweight—it runs on-device without constant internet. Watson STT works offline too. SAP BTP handles the backend because it's built for enterprise scale."
- **Integration complexity:** The slide makes it look like three boxes. The reality is more like: How does Ray-Ban talk to Device Edge? (USB? Network?) How does Device Edge talk to BTP? (CloudEvents over WiFi? Cellular?) What happens if the connection drops? Narration should not overcomplicate this, but a sentence helps: "The glasses connect to a local edge device—sometimes a handheld, sometimes a small server—which syncs with SAP BTP when there's connectivity."
- **What the DSP interface looks like:** Slide 4 mentions "DSP interface" but doesn't show it. Narration can preview: "DSPs record tasks once in the web app. Brian plays them back on his glasses. DSPs can see in real time if Brian needs help or if he's stuck on a step."

**Narration moment:** Moderate. This is a technical credibility moment. Voice helps, but the slide is mostly architecture. Narration should be clear and confident, not apologetic: "Here's what we built."

---

### Slide 5 — Model Updates (ROSA/OpenShift AI → bootc upgrade → Federated loop)

**Job:** Answer "How does the system get smarter?" This is where innovation claims live.

**CRITICAL RISK SLIDE.** This is technically dense and includes the hardest-to-defend claim (federated learning).

**Structure:**
- **ROSA/OpenShift AI:** fine-tune Granite on new task data, bake weights into bootc image, push to registry
- **bootc upgrade:** device pulls image diff, stages atomically, reboots into new OS + model, rollback in one command
- **Federated loop:** Brian's corrections ship back as CloudEvents, cluster retrains, next image includes his improvements

**What it does well:**
- Bootc image versioning is genuinely clever. It's not ad-hoc ML deployment; it's infrastructure-grade.
- The loop closes: data → training → deployment → feedback
- "Rollback in one command" is a risk-mitigation phrase that builds trust

**What's oversimplified (and narration can oversell):**
- "Fine-tune Granite on new task data": This sounds easy. In reality, you need:
  - Labeled training data (who labels it? DSPs? Automatic?)
  - A training SLA (how long until new task is live?)
  - Model evaluation (does the new model work better?)
  - A/B testing before rollout?
  
  Narration risk: Saying "fine-tune and deploy" makes it sound like a one-click process. Reality is 2–3 weeks per update cycle, probably.

- "Federated loop": This is the hard claim. "Brian's corrections" could mean:
  - Brian gives thumbs-up/down feedback
  - Brian's successful vs. failed attempts are logged
  - A DSP reviews Brian's work and tags what needs retraining
  
  Narration risk: Saying "Brian's corrections automatically improve the model" oversells. The real story is "We collect data from how Brian uses the system. We use that to identify which tasks need improvement. We retrain those tasks. The next version is smarter." This is less sexy, but honest.

**What's undersold (narration can add):**
- **Speed of iteration:** If you can get feedback from field deployments, retrain in a week, and push out a new image, that's *fast* compared to traditional software. "Unlike apps that ship once a quarter, we can improve the model weekly based on real usage."
- **Safety of updates:** "Bootc upgrades are atomic and rollback-able. If a new model performs worse, we revert in seconds. No bricked devices, no customer support nightmare."

**Narration moment:** THIS SLIDE REQUIRES CAREFUL NARRATION. It's where you either build credibility or lose it. Script should:
1. Acknowledge the loop is *powerful* but *complex*
2. Explain each step in plain English
3. Not claim full-automation where there's human judgment
4. Emphasize the rollback + safety story

**Specific narration guidance:**
- Avoid: "The system automatically learns from Brian's usage and improves itself."
- Prefer: "We observe how Brian uses the coaching. When we notice a pattern—like a task that confuses people—we refine the task prompts. We test the new version. We push it out. If it works better, it's live. If not, we roll back instantly."

---

### Slide 6 — Demo Concept (Task playback mockup: "How do I stock the shelf?")

**Job:** Show what it *feels like* to use this. Make it *concrete*, not abstract.

**CRITICAL RISK SLIDE.** This is explicitly a mockup, not a live demo. Narration must frame it correctly.

**Structure:**
1. "Pick up the box from the cart."
2. "Find the product tag on the shelf — it matches the box label."
3. "Place items on the shelf, left to right, labels facing forward." [ACTIVE]
4. "Move the empty box to the recycling bin near the back door."
5. "Great work. Ready for the next box?"
Footer: "DSP recorded this task sequence once. Brian can replay it anytime, at his own pace."

**What it does well:**
- **Five steps is *realistic*.** Not oversimplified (1–2 steps), not overwhelming (10+ steps)
- **"Pick up the box" is *concrete*.** Not abstract ("prepare for task"), actionable ("pick up")
- **"[ACTIVE]" is good UX language.** Tells you which step Brian is on
- **Cheerleading at the end** ("Great work") is important for motivation
- **Footer is honest:** "DSP recorded this task sequence once." Sets expectation: this is *recorded coaching*, not *AI chatbot*

**What's unsaid (and narration must clarify):**
- **Who is speaking?** Is this text-to-speech (Jenny Neural)? A recorded DSP? Narration should say: "Brian hears the prompts as audio. If he's wearing the glasses, he hears them through bone conduction—no one else hears it. It's like a private coach in his ear."
- **What if Brian can't read?** The mockup shows text. Real product would be audio-first. Narration: "If Brian is non-verbal or doesn't read, the coaching is purely audio. The glasses never assume literacy."
- **Pacing.** The slide shows five steps. Does Brian go through all five at once, or can he pause between steps and resume later? Narration: "Brian can work at his own pace. He can pause on any step, ask for a repeat, move backward if he made a mistake. No timer. No DSP waiting. Just him and the task."
- **Error handling.** What if Brian does step 3 wrong (places items right-to-left instead of left-to-right)? Does the system catch it and re-coach? Does he have to ask the DSP later? Narration should note: "The system can see what Brian is doing via the glasses camera. If it spots an error, it can alert him or ask him to try again. If Brian is stuck, he can call for a DSP to jump in remotely."

**Narration moment:** CRITICAL. This slide is a MOCKUP. If narration says "Here's what Brian sees," the audience will assume it's live. If narration says "Here's what the experience is *like*," it sets the right expectation.

**Specific narration guidance:**
- Open: "Let's walk through what Brian experiences when he's stocking the shelf."
- Close: "This is a mockup we built to show the interaction model. The glasses see what Brian's doing, coach him through each step, and let him work at his own pace."
- **Do NOT say:** "Here's the live demo of the coaching system." (Overcommits to live functionality)
- **Do say:** "Here's how the coaching experience works. We'll show you the live edge-tts and task playback system in the next moment."

---

### Slide 7 — Live Demo Link (brian-chores.html)

**Job:** Prove some of this is *really* built and running. Transition from mockup to reality.

**What it does well:**
- HTML + browser = low friction. No special software. Anyone can try it.
- "Phone-first, edge-tts, Jenny Neural voice, offline-capable" = specifics that build credibility

**What's unsaid:**
- What will the live demo show? (The brief says it's "task playback," so probably just the audio coaching, maybe with a text transcript or visual of which step is active)
- Is it *fully* offline, or just "works offline after first sync"?
- Can you actually control it, or is it a playback-only demo?

**Narration moment:** Transition moment. "We built this in a browser so you can try it. Let me show you." Then either show it live during the presentation, or have a link people can click after. Narration bridges the gap between "here's what it looks like" and "here's the actual code running."

---

### Slide 8 — Impact/Close ("Independence. Dignity. Determination.")

**Job:** End on mission, not features. Close the sale with emotion + stats.

**Structure:**
- Headline: "Independence. Dignity. Determination."
- Stats: 5.4M IDD adults, <20% employment, edge AI privacy-first
- Close: "Brian gets the coaching he needs. When he needs it. Where he needs it."

**What it does well:**
- Returns to Brian, who opened the deck
- Three values are *emotional*, not technical
- Close is *specific* (coaching, timing, autonomy), not generic ("change lives")

**What's unsaid:**
- What happens next? Do you ask for a pilot? A meeting? A download?
- Who should the buyer contact?
- What's the timeline?

**Narration moment:** This is a *mission moment*. The narration should slow down and get personal. Not a sales pitch. A statement of intent.

**Specific narration guidance:**
- Open: "So here's what this is really about."
- Middle: Deliver the three values with *meaning*. "Independence—Brian works without a handler. Dignity—he chooses when he needs help. Determination—he's not waiting for a DSP who might not show up."
- Close: "For 5.4 million adults in the US with intellectual disabilities, this is the difference between sitting on the sidelines and being in the game."
- Call to action: "Let's talk about how to get this into the field." (Or whatever the actual ask is—pilot, partnership, etc.)

---

## 4. WHAT A NARRATOR ADDS

### What does voice provide that text cannot?

**Tone & permission:**
- Slide 1 ("What if") sounds hopeful as text. A voice saying it with *confidence* (not sappiness) makes it *believable*.
- Slide 2 (stats) sounds clinical on the slide. A voice saying it with *weight* ("5.4 million. That's roughly the population of Ireland. Sitting on the sidelines.") makes it *urgent*.

**Pacing & emphasis:**
- Text is always there. Voice *reveals* information at human speed.
- Example: Slide 5 (model updates) is visually dense. A voice walking you through it—"First, here's how we train... Second, here's how we deploy... Third, here's how it improves..."—makes it *followable*.

**Legitimacy & authority:**
- Text on a slide from a vendor always sounds like sales pitch.
- A voice from a person saying "We built this because..." sounds like *testimony*.

**Emotional punctuation:**
- Slide 1: A pause before "What if" lands harder than text alone.
- Slide 8: A beat of silence after "Independence. Dignity. Determination." lets it sit.

### What specific moments in this deck need a human voice to land?

| Slide | Moment | Why | What voice does |
|-------|--------|-----|-----------------|
| Slide 1 | "What if Brian could work independently?" | Hook must be *conviction*, not copy | Turns aspiration into belief. Tone says "we've thought about this." |
| Slide 2 | "Assistive tech lags consumer tech by decades" | This is an *indictment*. Needs weight | Voice makes it clear this isn't a casual observation. This is a *problem statement*. |
| Slide 2 | "Recording everything to the cloud undermines autonomy" | Privacy as *moral*, not just technical | A voice saying this with slow emphasis lands harder than text. It's a value statement. |
| Slide 3 | Explaining three capabilities (Task / Danger / Social) | Each is a different *solution* to a different *pain* | Voice can pause between them. Lets each land. Text all at once is noise. |
| Slide 5 | "Federated loop: Brian's corrections ship back..." | This is the *hardest technical claim* | Voice must slow down, explain carefully, build credibility. Can't oversell. |
| Slide 6 | Transitioning from mockup to demo | **Critical framing moment** | Voice says "This is a mockup showing the UX" vs. "This is the actual system." Word choice matters. |
| Slide 7 | "We built this in a browser. Let me show you live." | Transition from talking *about* to showing *evidence* | Voice builds anticipation. Creates the moment where text alone can't. |
| Slide 8 | "Independence. Dignity. Determination." | Mission statement. Must *land*. | Voice with a pause, delivered with *conviction*, closes the deal. Text alone is a headline. Voice makes it a manifesto. |

---

## 5. RISK AREAS FOR NARRATION

### Slide 5: Model Updates (technically dense, aspirational claims)

**The risk:** Narration could oversell the automation and underdeliver on feasibility.

**What could go wrong:**

1. **Oversell: "The system learns automatically from Brian's usage."**
   - Reality: You need labeled data, training infrastructure, evaluation, version control. It's not magic.
   - Narration risk: Saying "automatically" implies no human judgment. That's false.
   - **Fix:** Say "We observe real usage, identify improvements, retrain, and deploy new models weekly." This is fast *and* realistic.

2. **Oversell: "Federated learning means every device improves the model."**
   - Reality: Federated learning for non-IID task data is hard. You probably end up with task-specific retraining, not global model improvement.
   - Narration risk: "Distributed learning" sounds like cutting-edge AI. It could also sound like magic.
   - **Fix:** Say "Devices report back on what works and what doesn't. We use that signal to improve the coaching prompts. The next version gets smarter." Honest, and still impressive.

3. **Undersell: Not mentioning the rollback capability.**
   - Narration should emphasize: "Every update can be rolled back in seconds. If a new model performs worse, we don't leave customers stuck. We revert."
   - This is actually a *huge* safety advantage over traditional ML deployment.

4. **Undersell: Not mentioning the training timeline.**
   - Narration should be clear: "A task that needs retraining can be improved and deployed within a week. Not a quarter. Not a year." This is *fast* compared to traditional assistive tech.

**Narration guidance:**
- **Slow down.** This slide is dense. Don't rush it.
- **Use plain language.** "Fine-tune" is jargon. Say "improve" or "retrain."
- **Emphasize safety.** "Rollback in one command" is a feature, not a side note.
- **Be honest about human judgment.** "We observe patterns, our team decides what to retrain, we test it, and we deploy." This is *manual intelligence*, not *autonomous learning*. It's more trustworthy.

### Slide 6: Demo Concept (mockup, not live, could oversell)

**The risk:** Narration could leave the impression this is a live, fully-tested system. It's a mockup.

**What could go wrong:**

1. **Oversell: "Here's the coaching experience in action."**
   - Reality: This is a mockup. It shows the *sequence* and *UX flow*, not real edge inference.
   - Narration risk: Audience assumes this is a live capture of Brian using the system.
   - **Fix:** Say "Here's what the coaching interaction looks like. We built this mockup to show the user experience."

2. **Oversell: "The system sees what Brian's doing and coaches him real-time."**
   - Reality: The mockup shows coaching steps, but not the vision model running, detecting errors, or alerting in real time.
   - Narration risk: "Real-time vision feedback" is a claim you might not be ready to defend.
   - **Fix:** Say "The glasses have a camera, so the system can see what task Brian is working on and alert him if something's unsafe. This sequence shows task coaching, which is audio-based prompts recorded by a DSP."

3. **Undersell: Not explaining the audio/UX model.**
   - The mockup shows text. Real product is audio-first (especially for non-readers).
   - Narration should clarify: "Brian hears these prompts through the glasses. No one else hears it. It's a private coach in his ear."

4. **Undersell: Not showing error handling.**
   - What happens if Brian does step 3 wrong? The mockup doesn't show this.
   - Narration could preview: "If Brian goes off-track, the system can catch it with the camera and re-coach. Or he can ask for help from a DSP remotely."

5. **Oversell: Smooth flow = reliable performance.**
   - The mockup shows a clean path: pick up → find tag → place items → done.
   - Reality: Some Brian's will get stuck, the system will need fallbacks, some tasks will need human DSP intervention.
   - Narration risk: Suggesting that all task sequences will be this clean.
   - **Fix:** Say "This is one happy path. The real system handles detours, mistakes, and asks for help when Brian needs it."

**Narration guidance:**
- **Name it as a mockup.** "We built this mockup to show the user experience."
- **Explain what's real vs. simulated.** "The task sequence is real—a DSP recorded it. The interaction flow is how it works. What we're not showing here is the edge inference running in parallel, detecting safety issues or places where Brian might need a nudge."
- **Don't claim live performance you can't defend.** If the live demo (Slide 7) is just audio playback, say that. Don't oversell Slide 6 as proof of end-to-end capability.
- **Emphasize the *design*, not the *performance*.** This is about UX. "Here's how we thought about accessibility, pace, and private coaching. Let's talk about how we're making sure it's reliable."

### Other narration risk areas

**Slide 3: "Social Navigation"**
- **Risk:** Sounds like "teaching people with IDD to fake normalcy." This could trigger a cultural backlash.
- **Narration guidance:** Frame it as *agency*, not *conformity*. "If Brian wants to order food but isn't sure what to say, the system can give him a script: 'I'd like a sandwich, please.' It's coaching, not correction. If he wants to wing it, he can."

**Slide 4: Architecture complexity**
- **Risk:** Narration could oversimplify ("Just glasses + edge + cloud") and gloss over integration complexity.
- **Narration guidance:** "The glasses connect to a local device—could be a handheld, could be a small edge server. That device runs the AI models. It syncs with our backend when there's connectivity. The whole system is designed so coaching *keeps working even if the connection drops*."

**Slide 7: Live demo**
- **Risk:** Live demos fail. If Slide 7 is a live browser demo that doesn't load or crashes, the whole narrative breaks.
- **Narration guidance:** Have a backup. Script narration that works whether the demo loads or not. "Let me show you the live system here... [if it loads, excellent] ...or I can walk you through what you'd experience."

---

## SUMMARY: Narration Strategy

This deck is **story-driven, not feature-driven**. The narrative arc is:

1. **Emotional hook** → Why should I care? (Brian's dignity)
2. **Problem** → Why hasn't this been solved? (Market failure + tech lagging)
3. **Solution** → Here's what different (three concrete capabilities)
4. **Proof** → This is buildable (architecture + tech stack)
5. **Innovation** → This is *smart* (model updates + federated learning)
6. **Reality check** → This is *real* (mockup UX, live demo)
7. **Close** → This matters (mission + stats)

**Narration's job:**
- Slide 1–2: Plant emotion + urgency
- Slide 3–4: Build credibility
- Slide 5–6: Manage complexity + reality expectations
- Slide 7–8: Transition to action + mission

**Key narration principles:**
- **Honest about aspirations.** Federated learning is cool, but don't oversell it as autonomous.
- **Clear about mockups.** "Mockup" isn't a dirty word. It shows you've designed the UX.
- **Specific about impact.** "5.4M people" lands harder than "helping people with disabilities."
- **Careful with sensitive claims.** "Social Navigation" and "Danger Steering" need thoughtful framing, not tech bravado.
- **Slow down on dense slides.** Slide 5 needs breath and pause. Don't rush it.
- **Use voice for emotion.** Slides 1, 2, and 8 are *values moments*. Voice makes them land.

