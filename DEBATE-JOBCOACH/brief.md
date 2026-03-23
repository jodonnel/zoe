# Job Coach Narration Brief

## The deck: present-job-coach.html (7 slides)

### Slide 1 — Hook
Persona: Brian. Adult with IDD. Wants to work independently.
Headline: "What if Brian could work independently?"
Subhead: "An AI job coach. Running at the edge. On glasses he already wears."

### Slide 2 — The Problem
- 5.4M adults with IDD in the US. Less than 20% employment rate.
- Assistive tech lags consumer tech by decades. Single-purpose, expensive, stigmatizing.
- Job coaching is manual and inconsistent. DSPs can't be everywhere.
- Independence requires real-time support: task sequences, danger awareness, social navigation.
- Privacy matters. Recording everything to the cloud undermines autonomy.

### Slide 3 — The Solution
Three capabilities, edge AI, one platform:
- Job Task Coaching: step-by-step audio prompts. Learned once with a DSP, replayed on demand.
- Danger Steering: real-time alerts for unsafe situations. Vision model runs locally.
- Social Navigation: guided prompts for ordering food, checking out, small talk.
Privacy-first: all inference at the edge. No constant cloud recording. Brian's data stays with Brian.

### Slide 4 — Architecture
Meta Ray-Ban → Device Edge → SAP BTP
- Meta Ray-Ban: camera, mic, bone conduction audio
- Device Edge: RHEL Image Mode · IBM Granite · Watson STT · TTS
- SAP BTP: task library · analytics · DSP interface

### Slide 5 — Model Updates
How the model gets smarter:
- ROSA/OpenShift AI: fine-tune Granite on new task data, bake weights into bootc image, push to registry
- bootc upgrade: device pulls image diff, stages atomically, reboots into new OS + model, rollback in one command
- Federated loop: Brian's corrections ship back as CloudEvents, cluster retrains, next image includes his improvements

### Slide 6 — Demo Concept
Task playback mockup: "How do I stock the shelf?"
1. "Pick up the box from the cart."
2. "Find the product tag on the shelf — it matches the box label."
3. "Place items on the shelf, left to right, labels facing forward." [ACTIVE]
4. "Move the empty box to the recycling bin near the back door."
5. "Great work. Ready for the next box?"
Footer: DSP recorded this task sequence once. Brian can replay it anytime, at his own pace.

### Slide 7 — Live Demo link
Opens brian-chores.html (phone-first, edge-tts, Jenny Neural voice, offline-capable)

### Slide 8 — Impact/Close
"Independence. Dignity. Determination."
Stats: 5.4M IDD adults · <20% employment · Edge AI privacy-first
Close: "Brian gets the coaching he needs. When he needs it. Where he needs it."

## Stack
- Red Hat Device Edge / RHEL Image Mode
- IBM Granite (local LLM)
- Watson STT (local speech-to-text)
- edge-tts / Jenny Neural (TTS, already built)
- SAP BTP (workflows, task library, DSP interface)
- Meta Ray-Ban glasses (camera, mic, bone conduction audio)
- ROSA / OpenShift AI (model training + update pipeline)
- CloudEvents (federated loop)

## Jim's ask
1. Understand the business and technical proposition
2. Write a narration script for the full deck
3. Assess feasibility of kiosk mode: advances ONLY after narration completes
