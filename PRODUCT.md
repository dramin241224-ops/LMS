# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Self-contained single-file static HTML/CSS/JS (`result/*.html`), 100% offline-capable with authored inline SVG artwork, Web Speech API (`speechSynthesis`) for English pronunciation, and Web Audio API for interactive sound effects—zero external CDN runtime dependencies (no Tailwind CDN).

## Users

- **Primary learners:** Grade 2 Vietnamese primary school students (ages 7–8) studying the *Global Success* English curriculum, practicing phonics, core vocabulary, and simple communicative sentences through play.
- **Primary facilitators:** Primary school English teachers running whole-class interactive activities on classroom Smart TVs, projectors, or interactive whiteboards, alongside parents supporting independent practice at home on tablets, laptops, or desktop PCs.

## Product Purpose

Deliver joyful, play-based interactive English mini-games mapped directly to each textbook unit so young learners master unit phonics, vocabulary recognition, word spelling, and sentence comprehension in a 5–10 minute session. Success means a Grade 2 child understands what to do immediately without lengthy adult explanation, hears and practices accurate English words and sentences, feels encouraged even when guessing wrong, and finishes with genuine pride and smooth in-app replayability.

## Positioning

Offline-resilient, zero-install single-file HTML learning quests purpose-built for Vietnamese Grade 2 English classrooms and home tablets—uniting whole-class Smart TV legibility with a scaffolded 4-stage language acquisition loop (Phonics & Word Discovery → Fast Recognition → Word Spelling → Contextual Sentence Building).

## Operating Context

- **Classroom mode:** Projected or displayed on a bright classroom TV/interactive board, often on school PCs with unreliable or offline internet, operated by teacher click or student walk-up touch while classmates watch from 3–6 meters away.
- **Home mode:** Operated directly by a 7–8 year old using touch on an iPad/tablet or mouse/trackpad on a home computer.

## Capabilities and Constraints

- Each unit ships as a standalone `.html` file inside `result/` (target surface: `result/unit_4_countryside_quest.html` for *Unit 4: In the Countryside*).
- **100% offline operation:** Must never break or lose layout when opened without internet access; no external CSS/JS CDNs, and typography must rely on locally available/offline-safe font stacks.
- **Unit 4 curriculum truth:**
  - Phonics focus: Letter `R / r` (sound `/r/`).
  - Core vocabulary: `rainbow`, `river`, `road`.
  - Core sentence patterns: `There's a ...` (e.g., `There's a rainbow in the sky.`, `There's a river near the road.`) and `I can see a ...` (e.g., `I can see a road.`).
- **4-stage pedagogical flow:**
  1. Stage 1 — Discover & Listen (explore phonics `/r/` and the 3 words with visual & spoken models).
  2. Stage 2 — Spot & Match (fast visual/audio recognition across all 3 words).
  3. Stage 3 — Build the Word (interactive letter/phonics assembly for `road`, `river`, `rainbow`).
  4. Stage 4 — Countryside Sentences (complete/choose contextual sentences for all 3 words), culminating in a star summary and seamless in-app replay (never `location.reload()`).
- **Audio & speech:** Web Speech API (`en-US` / `en-GB` fallback) with replayable speaker buttons on words/sentences plus synthesized Web Audio sound effects and an always-reachable mute toggle; must degrade gracefully with visual phonics cues if a browser lacks speech voices.

## Evidence on Hand

- Existing unit deliverables in `result/`:
  - `result/unit_2_backyard_adventures.html` (*Unit 2: In the Backyard* — `kite`, `bike`, `kitten`)
  - `result/unit_3_seaside_fun.html` (*Unit 3: Seaside Fun* — `sea`, `sail`, `sand`)
  - `result/unit_4_countryside_quest.html` (*Unit 4: In the Countryside* — `road`, `river`, `rainbow`)
- Pedagogical principles in `.agent/skills/education-eng/SKILL.md`: play-based learning, child-psychology empathy, positive reinforcement over punishment, visual prop clarity, and low-stakes assessment.
- No external recorded audio files or external raster asset packs exist; all visuals and sound cues must be authored cleanly inside the deliverable.

## Product Principles

1. **Scaffold Before Testing:** Always let young learners hear, see, and touch the `/r/` sound and words before asking them to identify, spell, or form sentences.
2. **Safe-to-Fail Encouragement:** Incorrect taps trigger gentle, constructive hints and immediate retry—never harsh buzzers, point deductions that feel punitive, or dead ends.
3. **Dual-Distance Ergonomics:** Controls and illustrations must work simultaneously for a child's finger on a tablet and a student reading from the back row of a sunlit classroom.
4. **Single-File Reliability:** Every `.html` game in `result/` is an autonomous teaching tool that opens instantly from any folder or USB stick with zero setup.

## Accessibility & Inclusion

- Pair every state change with clear shape, motion, text, and audio cues—never rely on green/red color alone.
- Support keyboard navigation, touch/click interaction (no desktop-only HTML5 drag-and-drop traps that fail on mobile/touchboards), `prefers-reduced-motion`, and a persistent audio mute control.

