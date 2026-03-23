# Feasibility: Narration-Gated Advancement for Job Coach Deck

**Assessment date:** 2026-02-23  
**For:** Jim (builder)  
**Status:** Go/no-go on kiosk mode with auto-advance after audio.

---

## 1. IMPLEMENTATION APPROACH

**The pattern:** Pre-generate MP3s via edge-tts, trigger next slide on `audio.ended` event, gate all manual advance until narration completes.

**Core JS (20 lines):**

```javascript
// Global state
let isNarrating = false;
let currentSlide = 0;

// On slide transition
function advanceSlide(direction) {
  if (isNarrating && direction === 1) {
    console.log("Narration in progress. Click again to skip.");
    return;
  }
  // ... normal slide logic
  playNarration(currentSlide);
}

// Audio control
function playNarration(slideNum) {
  isNarrating = true;
  const audio = document.getElementById(`narration-${slideNum}`);
  audio.play();
}

// Trigger on audio end
document.querySelectorAll('audio').forEach(el => {
  el.addEventListener('ended', () => {
    isNarrating = false;
    // Optional: auto-advance
    advanceSlide(1);
  });
});
```

**Key decision made here:** The `isNarrating` flag lets you gate advance attempts. On click during narration, you can either (a) refuse to advance, (b) warn and offer skip, or (c) auto-skip. More on UX below.

---

## 2. EDGE-TTS GENERATION

**Voice:** en-US-JennyNeural (matched to brian-chores.html, already proven)  
**Tool:** edge-tts CLI  
**Input:** One markdown file with slide number + narration text  
**Output:** 8 MP3 files, one per slide

**Batch generation script:**

```bash
#!/bin/bash

# Narration text (from script.md, split by slide)
declare -A narrations=(
  [1]="What if someone with an intellectual disability could work a real job..."
  [2]="Here's the gap: 5.4 million adults with intellectual disabilities..."
  [3]="We built a job coach that runs on the edge..."
  [4]="Here's what that looks like in practice. Brian wears Meta Ray-Ban glasses..."
  [5]="Now, the coaching gets smarter over time..."
  [6]="Let's walk through what Brian actually experiences..."
  [7]="To prove we've actually built this, we created a live browser demo..."
  [8]="So here's what this is really about. Not a new feature..."
)

# Generate MP3s
for slide_num in {1..8}; do
  echo "Generating slide-${slide_num}.mp3..."
  edge-tts \
    --text "${narrations[$slide_num]}" \
    --voice en-US-JennyNeural \
    --write-media "slide-${slide_num}.mp3"
done

echo "Done. Files: slide-1.mp3 through slide-8.mp3"
```

**Real command (one file, as an example):**

```bash
edge-tts \
  --text "What if someone with an intellectual disability could work a real job without a handler standing next to them? Not someday. Now." \
  --voice en-US-JennyNeural \
  --write-media "slide-1.mp3"
```

**Gotchas:**
- edge-tts is Python-based; you need `pip install edge-tts` first.
- Network required for generation (TTS service is cloud-backed, voice synthesis is remote). Offline playback works; generation doesn't.
- Files are small (~100-200 KB each for 30-45 second clips). Total payload ~1 MB for all 8 slides.
- Jenny Neural voice is deterministic; same text always produces identical audio (good for testing, good for caching).

**Time estimate for batch:** ~5 minutes to generate all 8. ~30 seconds per file depends on length + network latency.

---

## 3. THREE APPROACHES TO AUDIO DELIVERY

### A. Linked MP3 Files (Hosted on GitHub Pages)

**How it works:**
- Store `slide-1.mp3` through `slide-8.mp3` in `/assets/audio/` folder in the GitHub Pages repo.
- HTML: `<audio id="narration-1" src="/assets/audio/slide-1.mp3"></audio>`
- Audio element fetches file on first play.

| Metric | Rating | Notes |
|--------|--------|-------|
| **Implementation effort** | Low | Just `<audio>` tag + src attribute. No encoding. |
| **Reliability** | High | Standard HTML5. Works offline if files cached by browser. |
| **File size** | Low | 1 MB total payload. Fast first load if cached. |
| **Offline capability** | Partial | Requires browser cache (service worker recommended for guaranteed offline) |
| **Voice quality** | Excellent | Full-fidelity MP3, no compression artifacts. |

**Recommendation for this use case:** YES, if you add service worker for offline guarantee.

---

### B. Base64-Embedded MP3 (Like blackjack videos)

**How it works:**
- Encode each MP3 as base64 string.
- Embed directly in HTML: `<audio src="data:audio/mpeg;base64,//NExAA..."></audio>`
- No HTTP requests. Everything in one HTML file.

| Metric | Rating | Notes |
|--------|--------|-------|
| **Implementation effort** | Medium | Python script to encode 8 files + paste into HTML template. |
| **Reliability** | Excellent | No network dependency whatsoever. Single file. |
| **File size** | High | Base64 bloats by ~33%. 8 MB total HTML file. Slow initial load. |
| **Offline capability** | Perfect | Works 100% offline, no cache needed. |
| **Voice quality** | Excellent | Bitstream identical to linked MP3. |

**Tradeoff:** Single-file simplicity vs. large HTML payload.

---

### C. Web Speech API (Browser TTS, No Pre-generation)

**How it works:**
- Use `speechSynthesis.speak()` to synthesize narration text on-the-fly in the browser.
- No MP3 files. No generation step. No cloud call during presentation.

```javascript
const utterance = new SpeechSynthesisUtterance(narrationText);
utterance.rate = 1;
utterance.pitch = 1;
speechSynthesis.speak(utterance);
```

| Metric | Rating | Notes |
|--------|--------|-------|
| **Implementation effort** | Low | Direct API call. No pre-generation. |
| **Reliability** | Low | Browser-dependent. Voices vary by OS. Timing unpredictable. |
| **File size** | Zero | No files. Just JavaScript. |
| **Offline capability** | Yes | Runs entirely in browser, no network needed. |
| **Voice quality** | Poor | System voices are robotic. Doesn't match Jenny Neural. |

**Deal-breaker:** You lose the warm, human voice (Jenny Neural) that's already a core part of the Brian Chores experience. Inconsistency across browsers/OS. Not professional enough for this demo.

---

## RECOMMENDATION: Approach A (Linked MP3s) + Service Worker

**Why:** 
1. Standard, reliable, proven pattern.
2. Small file footprint.
3. Service worker gives you guaranteed offline (one-time setup, ~30 lines of code).
4. Matches the stack already used in brian-chores.html.
5. Easy to iterate: regenerate audio, push files, done. No HTML edits needed.

**Alternative if offline offline is non-negotiable:** Approach B (base64 embedding). One-time build step, then everything is static. Downside: 8 MB HTML file loads slower, and updates require full re-embed.

**Reject:** Approach C. Voice quality matters for this pitch. Not worth it.

---

## 4. KIOSK MODE UX: PRESENTER CONTROLS

**The scenario:** Live demo. 200 people in room. Jim or another presenter is clicking through slides. Narration plays. Deck advances automatically. Something might break.

**What the presenter needs:**

| Control | Necessity | Implementation |
|---------|-----------|-----------------|
| **Skip narration** | Required | Right-click or double-click on audio element pauses/stops playback, allows manual advance. OR: spacebar + Shift skips current narration. |
| **Pause narration** | Nice-to-have | Pause button in bottom right corner, visible only to presenter (keyboard shortcut, not visible UI). Space bar pauses; space again resumes. |
| **Restart slide narration** | Required | R key or "replay" button. If presenter messes up the pacing, they can restart the audio without changing slide. |
| **Mute narration** | Required | M key toggles mute on active audio element. Live demo breaks? Mute and continue. |
| **Manual advance override** | Required | If narration glitches and doesn't trigger `audio.ended`, arrow keys force advance. Default: blocked during narration. But Shift+Right forces it anyway. |
| **Auto-advance toggle** | Optional | A key toggles auto-advance on/off. Default: on. Useful if you want to talk over a slide before advancing. |

**UX pattern for kiosk:**

```javascript
// Keyboard shortcuts (presenter only, not visible on screen)
document.addEventListener('keydown', (e) => {
  if (e.code === 'Space' && !e.shiftKey) {
    // Pause/resume current narration
    const audio = audioElements[currentSlide];
    if (audio.paused) audio.play();
    else audio.pause();
  }
  if (e.code === 'KeyR') {
    // Restart narration for current slide
    const audio = audioElements[currentSlide];
    audio.currentTime = 0;
    audio.play();
  }
  if (e.code === 'KeyM') {
    // Mute toggle
    const audio = audioElements[currentSlide];
    audio.muted = !audio.muted;
  }
  if (e.code === 'ArrowRight' && e.shiftKey) {
    // Force advance (override narration gate)
    advanceSlide(1);
  }
});
```

**Visible UI:** Minimal. Just the slide counter (Slide 3 of 8) in bottom left. No play/pause buttons visible—all control is keyboard, so presenter looks smooth in front of audience.

**What NOT to include:**
- Clickable play/pause buttons (breaks the illusion of automatic advance).
- Progress bar on audio (too technical, distracting).
- Volume slider (mute only, via keyboard).

---

## 5. THE SINGLE BIGGEST RISK

**Network failure during audio generation, OR audio file corruption during GitHub Pages deployment.**

More specifically: You generate all 8 MP3 files locally. You test them in the HTML. They work. You push to GitHub Pages. The GitHub CDN serves them. Live demo day. You click. Audio element loads... and doesn't play. The file fetch failed. Or the file was corrupted during upload. Or the CDN is slow and audio doesn't start before you advance.

**Why this is THE risk:**
- Everything else has a fallback (keyboard override for manual advance, restart button, skip shortcut).
- Audio playback has no fallback. If the MP3 doesn't load, you're narrating without a voice, or you're silent while the slide sits there.
- It's not a logic bug. It's infrastructure.

**Mitigation:**
1. Test audio playback on actual GitHub Pages URL (not localhost) 48 hours before live demo.
2. Add a fallback: if audio fails to load after 2 seconds, log it and allow manual advance. Show a subtle warning icon.
3. Have a written script printout as backup. Presenter can ad-lib narration if audio fails.
4. Deploy with cache-busting headers so stale files don't serve: `?v=20260223` appended to src.

```javascript
// Simple fallback
const audio = document.getElementById(`narration-${slide}`);
audio.addEventListener('error', () => {
  console.error(`Audio failed to load: slide-${slide}.mp3`);
  isNarrating = false; // Allow manual advance
  showWarning('Narration unavailable. Click to continue.');
});

// Timeout as backup
setTimeout(() => {
  if (!audio.ended && !audio.paused) return;
  if (audio.networkState === audio.NETWORK_NO_SOURCE) {
    isNarrating = false;
  }
}, 2000);
```

**Other risks (secondary):**
- Jenny Neural voice not loading (less likely; edge-tts is stable).
- Timing misalignment between narration length and slide content (fixable in script).
- Browser autoplay policy blocks audio (rare, but test on actual Chrome in incognito).

---

## 6. BUILD ESTIMATE

**Break-down by phase:**

### Phase 1: Script Finalization (2 hours)
- Read the narration script from scout.md (it's already written).
- Extract narration text for each slide into a clean CSV or JSON file.
- Mark [PAUSE] beats as silent gaps (0.5 seconds per pause).
- Final read-through: ensure timing matches slide content (20-45 sec per slide).

**Time:** 1 hour scripting + 1 hour testing narration pacing with a quick TTS run.

### Phase 2: Audio Generation (1 hour)
- Write the batch bash script (15 min).
- Generate all 8 MP3 files (10 min actual generation time, but do it once, verify files exist and play).
- Spot-check 3-4 files in a media player to confirm quality (15 min).

**Time:** ~1 hour including retries if a file needs re-gen.

### Phase 3: HTML Wiring (4 hours)
- Copy present-job-coach.html to a new branch.
- Add `<audio id="narration-X" src="/assets/audio/slide-X.mp3"></audio>` for each slide in the HTML (15 min, repetitive).
- Wire up the JS for narration-gated advance: `isNarrating` flag + `audio.ended` listener (1 hour).
- Add keyboard shortcuts for presenter control (Shift+R, M for mute, Spacebar for pause) (45 min).
- Add fallback error handling + console logging (30 min).
- Test locally on localhost (30 min).

**Time:** ~4 hours.

### Phase 4: Testing & Deployment (3 hours)
- Deploy to GitHub Pages (5 min).
- Test on actual GitHub Pages URL (not localhost): audio loads, plays, triggers advance (30 min).
- Test keyboard overrides: Shift+Right forces advance, Space pauses, R restarts narration (30 min).
- Test offline (add service worker or verify browser cache) (1 hour).
- Test in browser incognito (autoplay policy) (15 min).
- Test on actual display/projector if possible, or ask someone else to run through it on their machine (30 min).

**Time:** ~3 hours.

### Total: 10 hours

**Realistic buffer:** +2 hours for unexpected issues (audio file doesn't load, timing is off, keyboard bindings conflict, etc.).

**Best-case (if everything goes smoothly):** 8 hours.  
**Worst-case (audio generation fails, GitHub Pages sync issues):** 14 hours.

**By which day?** If you start Monday morning, you're done Wednesday night. If you start Wednesday and live demo is Friday, it's tight but doable (17 of 24 hours heads-down work + testing).

---

## SUMMARY FOR JIM

**Go/no-go:** Go. This is straightforward. You've already built the infrastructure in brian-chores.html (edge-tts, Jenny Neural, offline-capable). You're reusing the pattern.

**Path forward:**
1. Script is done. Extract narration text into a clean file.
2. Generate 8 MP3s via edge-tts (batch script provided above).
3. Wire HTML with audio elements + `audio.ended` listener + presenter keyboard shortcuts.
4. Deploy to GitHub Pages and test on actual URL (this is the only real risk point).
5. Have script printout + backup plan for audio failure.

**Effort:** 10 hours, 3 engineers (you), no blockers.

**Confidence:** 90%. The only failure mode is network/file corruption during demo, which you can mitigate with fallbacks and 48-hour pre-test.

**What you're getting:** A silent deck becomes a narrated, paced, presenter-controlled kiosk mode that looks automatic but has full keyboard escape hatches. Audience sees smooth, timed reveal. Presenter has control invisible to audience. Exactly what you need for a live show.

---

