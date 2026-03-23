# Job Coach Demo — Narration Script

**Voice:** Jenny Neural (warm, clear, human but professional)  
**Format:** Natural spoken language, written for ears not eyes  
**Timing:** Each slide narration is 20–45 seconds, driving pacing of automatic deck advance  
**Key principle:** The narration IS the experience. No reading slides. No "as you can see." Just honest, human explanation of what matters and why.

---

## Slide 1 — Hook: "What if Brian could work independently?"

**Narration:**
What if someone with an intellectual disability could work a real job without a handler standing next to them? Not someday. Now. Brian's got the skills. He's got the will. What he's been missing is a coach who's always available, always consistent, and doesn't cost more than his paycheck. We built an AI job coach that runs right on the glasses he already wears. No cloud dependency. No surveillance. Just Brian, the task, and the support he needs the moment he needs it.

**Est. duration:** 38 seconds

**Notes:**
This is the emotional open. Tone is conviction, not sappiness. "What if" should land as hope + realism, not charity. The close "the support he needs the moment he needs it" sets up why the other slides matter.

---

## Slide 2 — The Problem

**Narration:**
Here's the gap: 5.4 million adults with intellectual disabilities in the United States. Less than one in five has a job. Not because they can't work. Most of them can. The problem is job coaching doesn't scale. A disability support professional—a DSP—costs twenty-five, thirty, forty dollars an hour, and there aren't enough of them. They burn out. They move on. And the coaching is only as good as whoever's on shift that day. Meanwhile, the assistive technology that people with disabilities rely on? It's stuck in the past. It's single-purpose. It's expensive. It's stigmatizing. And way too much of it records everything to the cloud, which means Brian's privacy goes with it. [PAUSE] The technology we use every day has gotten so smart. Why hasn't the technology for people with disabilities kept up?

**Est. duration:** 44 seconds

**Notes:**
This is the problem statement. It needs *weight*. The tone shifts from aspiration to urgency. The final question is rhetorical but genuine—it lands harder when delivered with real force, not as performance. The DSP cost and burnout are the market wedge. The privacy statement is a *values* moment—emphasize it.

---

## Slide 3 — The Solution

**Narration:**
We built a job coach that runs on the edge—meaning right there on the device, with no cloud dependency, no constant surveillance. It does three things. First, task coaching: a DSP records the steps for a job—how to stock a shelf, how to clean a restroom, how to bag groceries—and Brian can replay that sequence anytime, at his own pace. Second, danger steering: the camera on the glasses watches for safety issues in real time and alerts him before something goes wrong. Third, social navigation: if Brian's not sure what to say when he's ordering food or checking out, the system gives him a script—a coach in his ear, no one else hears it. Everything runs locally. Brian's data stays with Brian. No cloud surveillance. No data broker selling his behavior to the highest bidder.

**Est. duration:** 42 seconds

**Notes:**
Three capabilities, each solving a different pain. Pause between each—let them land separately. "Runs on the edge" and "stays with Brian" are the privacy throughline. This is where we earn the credibility signal for the "what if" from Slide 1.

---

## Slide 4 — Architecture

**Narration:**
Here's what that looks like in practice. Brian wears Meta Ray-Ban glasses: camera, microphone, bone conduction audio. On the device side—this could be a small edge server, could be a handheld—we run an open-source operating system from Red Hat, IBM's Granite AI model for understanding context, and Watson for converting speech to text and text back to speech. All of that lives on the device. When Brian's connected, the system talks to our backend on SAP BTP—that's the task library, the analytics so we know what's working, and the interface for disability support professionals to design new coaching sequences. The architecture is built for offline-first operation, which means if the connection drops, coaching doesn't stop.

**Est. duration:** 40 seconds

**Notes:**
This is a credibility-building slide. It's technical but should sound *grounded*, not theoretical. "Could be a handheld, could be an edge server" acknowledges there's flexibility—this isn't pie-in-the-sky. "Offline-first operation" is a specific, defensible claim. Close on resilience, not sophistication.

---

## Slide 5 — Model Updates

**Narration:**
Now, the coaching gets smarter over time, but not the way you might think. We don't claim that the system learns automatically from Brian's usage—that's not how this works. Here's what actually happens. We observe how people like Brian use the coaching. When we notice a pattern—like a task sequence that confuses multiple people—we identify what needs improvement. Our team refines the task prompts, tests the new version, and pushes it out via an atomic image update. If the new version works better, great. If not, we roll back in seconds. [PAUSE] What's powerful here is that we can identify problems from the field and ship improvements in a week, not a quarter. And because every update is atomic and reversible, we never leave a customer stuck with a broken model. Safety and speed, both at once.

**Est. duration:** 44 seconds

**Notes:**
This is the highest-risk slide for overselling. Scout flagged it explicitly. The narration must be *honest* about the human judgment involved while still showing it's impressive. "We observe... we identify... we refine" is *careful intelligence*, not *autonomous learning*. The rollback story is undersold in most tech pitches but it's a genuine advantage—emphasize it. Pause before the final sentence to let the safety promise land.

---

## Slide 6 — Demo Mockup

**Narration:**
Let's walk through what Brian actually experiences. He's stocking shelves at a retail job, and here's how the coaching works. [The sequence appears] "Pick up the box from the cart." He does. "Find the product tag on the shelf—it matches the box label." Now he's searching, actively, for the right spot. "Place items on the shelf, left to right, labels facing forward." That's where we are now. "Move the empty box to the recycling bin near the back door." And finally, "Great work. Ready for the next box?" This is a mockup we built to show the user experience. The task sequence is real—a DSP recorded it once, months ago. Brian can replay it anytime, at his own pace. He can pause on any step. He can back up if he made a mistake. No timer. No DSP waiting. Just him and the work.

**Est. duration:** 42 seconds

**Notes:**
Scout flagged this as critical for framing. The word "mockup" is essential—say it clearly so there's no ambiguity. The narration walks through the sequence so you understand the *cadence* and *feedback* without overselling the automation. "A DSP recorded it once, months ago" is the honest positioning. This is coaching-as-recording, not coaching-as-AI-chatbot. The close emphasizes autonomy: "at his own pace, no timer, no DSP waiting"—these are dignity moves, not technical features.

---

## Slide 7 — Live Demo

**Narration:**
To prove we've actually built this, we created a live browser demo you can interact with right now. It's called Brian Chores. It's running edge text-to-speech using the same Jenny Neural voice you're hearing right now, it's offline-capable, and it's running the actual task playback pipeline from our system. [PAUSE] So in a moment, you're going to see and hear the real thing working, not a mockup. Let me show you.

**Est. duration:** 28 seconds

**Notes:**
This is a transition moment, not a full narration. It bridges from "here's what it looks like" to "here's proof it works." The specificity—"edge text-to-speech," "Jenny Neural," "offline-capable"—builds credibility. The pause before "you're going to see the real thing" creates anticipation. Keep this short. Let the live demo speak for itself.

---

## Slide 8 — Impact / Close

**Narration:**
So here's what this is really about. Not a new feature. Not a nice-to-have. Independence. [PAUSE] Dignity. [PAUSE] Determination. Five and a half million adults with intellectual disabilities in the United States. Less than twenty percent have jobs. Not because they can't do the work. Because the support doesn't scale. This changes that. Brian gets the coaching he needs. When he needs it. Where he needs it. No handler. No surveillance. No waiting for a DSP who might not show up. [PAUSE] For people with disabilities, this is the difference between sitting on the sidelines and being in the game. Let's talk about how to get this into the field.

**Est. duration:** 45 seconds

**Notes:**
This is the mission moment. It's the close of the emotional arc that opened with "What if." Tone shifts to conviction. The three values—Independence, Dignity, Determination—each get a beat of silence after it so they land as statements, not a rush. The stats reframe (same numbers as Slide 2, but now with the solution behind them) show progress. The final line is a call to action. This is the slide where you breathe, speak with intention, and let the values *sit* after you say them. This is not a sales pitch. This is a statement of intent.

---

## NARRATION SUMMARY

**Total deck duration:** ~281 seconds (roughly 4.5 minutes of spoken narration)

**Emotional arc:**
- Slides 1–2: Hope → Urgency (plant the question, establish the gap)
- Slides 3–4: Solution → Credibility (here's what different, here's the proof it's real)
- Slide 5: Innovation with Honesty (smart + safe, not oversold)
- Slide 6: Reality Check (this is what it feels like, this is a mockup of UX)
- Slide 7: Proof → Transition (it's really built, watch this)
- Slide 8: Values → Action (this matters, let's move forward)

**Key narration decisions made:**
1. Slide 5 deliberately avoids "automatic learning" language and emphasizes human judgment + rollback safety.
2. Slide 6 explicitly names itself a mockup and emphasizes autonomy over automation.
3. Slide 7 is kept short; the live demo carries the proof, not the narration.
4. Slides 1, 2, 8 use pauses strategically to let values land, not rush them.
5. Voice is warm and human, never clinical or corporate. Specific claims (week-long retraining, atomic rollback, offline-first) are stated plainly.

**For the feasibility engineer:**
- All narration timings allow 20–45 second windows per slide.
- Pauses are marked [PAUSE] so the voice artist knows where to breathe.
- No slide relies on live demo performance except Slide 7 (which is intentionally the live demo moment).
- Slides 5 and 6 are high-stakes framing; narration was written to Scout's specific warnings, not against them.

