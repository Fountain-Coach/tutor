# 01 – Hello Csound

This lesson isn’t just about “making it work.” It’s about making music, right now — with Csound as the synthesizer and FountainAI as your composer companion. You’ll start from a single sine wave and build toward musical intent, while keeping the path to AI‑assisted composition only one step away.

Template‑first workflow: `setup.sh` scaffolds a minimal Swift package locally. You’ll generate a tiny `.csd` score and run a lightweight `CsoundPlayer` simulator that renders a short tone — then you’ll shape that tone musically, and see how AI can help you explore variations and ideas.

> No Binary Assets: only the text-based `hello.csd` file is bundled. Generated audio stays in memory and is not committed.

## Quick Recipes (Copy/Paste)

- Easiest: use the wrapper script in this folder:
  - `./run.sh tone` — print sample count
  - `./run.sh hear` — play the tone (macOS)
  - `./run.sh motif` — 3‑note motif (printed)
  - `./run.sh motif-hear` — motif and play
  - `./run.sh motif-score [--tempo 90] [--duo]` — write motif.ly (and motif_duo.ly when --duo)
  - `./run.sh triad [--quality minor]` — play a triad (major default)
  - `./run.sh triad-score [--quality minor] [--tempo 72]` — write triad.ly

Cheat Sheet (if you prefer raw env vars):
- `CS_PLAY=1` — audition the generated samples (macOS `afplay` or writes temp WAV)
- `CS_MOTIF=1` — use 3‑note motif (edit in `Sources/HelloCsound/Motif.swift`)
- `CS_TRIAD=1` — play/export a major triad (set `TRIAD_QUALITY=minor` for minor)
- `LY_EXPORT=1` — write a `.ly` file next to the tutorial (motif.ly / triad.ly / motif_duo.ly)
- `LY_DUO=1` — add a simple bass pedal under the motif (writes `motif_duo.ly`)
- `LY_TEMPO=<bpm>` — engraving tempo for LilyPond tokens (default 120)

## Before You Begin
- Install the Tutor CLI and add to PATH (see docs/tutor-cli.md and docs/shells-and-git.md):
  - `Scripts/install-tutor.sh`
  - `export PATH=$HOME/.local/bin:$PATH` (add via `~/.zshrc` on macOS)
- Run all commands from `tutorials/01-hello-csound/`.
- If needed, make the script executable:
  ```bash
  chmod +x setup.sh
  ```

## 1. Scaffold the Project
Run the setup script, which generates a minimal local Swift package in this folder and copies the `hello.csd` score:

```bash
./setup.sh
```

Expected: `Sources/HelloCsound/hello.csd`, `CsoundPlayer.swift`, and `main.swift` appear. Open the folder in Xcode with `xed .` (macOS) or your editor of choice.

## 2. Hear A First Tone (Musical Seed)
`CsoundPlayer` loads the bundled `hello.csd` and produces a short sine wave — a musical seed you’ll shape into something more expressive:

```swift
let samples = try CsoundPlayer().play()
print("Generated sample count: \(samples.count)")
```

## 3. Build and Run (Hear It)
Compile the project. By default the program renders samples and prints a count. To also hear the tone, enable playback with `CS_PLAY=1`:

```bash
tutor build
tutor run
```

Examples:

```bash
tutor build
tutor run                       # prints sample count only
CS_PLAY=1 tutor run             # also plays the tone
```

Expected: The console prints the generated sample count. With `CS_PLAY=1`, you hear the short tone rendered from the generated samples. On macOS, playback uses `afplay`; if sound output isn’t available, a WAV file is written to your temp folder (and `afplay` may print an error).

### About `afplay` (macOS)
- `afplay` is Apple’s command‑line audio player at `/usr/bin/afplay`.
- Used here to audition a temporary WAV rendered from the generated samples.
- Basic usage examples:
  - `afplay file.wav`
  - `afplay -v 0.8 file.wav` (set volume 0.0–1.0)
- If `afplay` isn’t available or audio output is restricted (CI, headless), the tutorial prints the temp WAV path so you can play it with another tool.

## 4. Tell A Story With Sound
Music is shaped intent. Start from the included `hello.csd` and try tiny, meaningful changes:

- Shape the amplitude with a simple envelope (fade in/out).
- Change pitch to create a motif (e.g., 440 ➔ 494 ➔ 523).
- Layer two partials to hint at timbre.

Example: add a short envelope inside instrument 1.

```csound
instr 1
  kenv linseg 0, 0.05, 1, 0.8, 1, 0.15, 0
  a1   oscili 0.5 * kenv, 440
  out  a1
endin
```

Try multiple score lines to suggest motion:

```csound
i 1 0.00 0.4  ; A4
i 1 0.45 0.4  ; B4
i 1 0.90 0.6  ; C5 (longer)
```

Re‑run `tutor run` and listen to the printed sample count change with duration. You’re sketching the arc of a phrase.

## 5. Your AI Composer Companion (Optional)
You can ask a local FountainAI Gateway to draft `.csd` ideas for you (“make a mellow pad with two detuned oscillators” or “turn this motif into a 2‑bar arpeggio”).

First, run the Gateway locally from source; see: [Run the FountainAI Gateway Locally](../../docs/run-gateway-locally.md). Important: set a provider key (e.g., `OPENAI_API_KEY`) in your shell before starting the Gateway so it can reach an LLM.

Quick path (no client install):

```bash
export LLM_GATEWAY_URL=http://localhost:8080/api/v1
export FOUNTAIN_AI_KEY=local-dev-key   # omit if auth is disabled for dev

# Ask for a .csd and write it into this tutorial
curl "$LLM_GATEWAY_URL/generate" \
  -H "Authorization: Bearer $FOUNTAIN_AI_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "fountain-medium",
    "messages": [{"role":"user","content":"Return a complete Csound .csd with a gentle envelope and a 3-note motif at 120 BPM. Output only .csd."}]
  }' \
  | jq -r '.content // .choices[0].message.content' \
  > Sources/HelloCsound/hello.csd

./run.sh hear
```

If you prefer typed Swift clients, scaffold upstream with `--profile ai` and adapt a small Swift call (see [05 – AI Integration with OpenAPI](../05-ai-integration-openapi/README.md)). Paste results into `hello.csd` and iterate. The AI is not the composer — you are — but it’s a great partner for fast “what‑ifs.”

### Why A Gateway? (Perspective)
- Creative iteration: ask for envelopes, motifs, or full `.csd` variations in seconds — then edit by ear. It’s a fast “composer companion”.
- Separation of concerns: Csound rendering stays local and deterministic; the Gateway only drafts text (scores/instrument code).
- Policy and safety: one place to enforce model choice, rate limits, and content policies (now or later).
- Reproducibility: keep prompts next to source; re‑materialize `.csd` on demand for a given model/version.
- Collaboration: share prompts/snippets across the team without coupling to an editor or DAW.

Local vs remote (clarity): FountainAI is local — you run the Gateway on your machine and tutorials run locally. The only remote hop is the Gateway’s outbound HTTPS request to a model provider (e.g., OpenAI) using your API key. If you unplug the provider, everything still builds and runs; you just won’t receive generated text until you restore a provider key.

When to stay local (no Gateway):
- You’re shaping a sound or phrase by hand; you want fully offline, deterministic iteration.

When to use the Gateway:
- You’re exploring idea space (motifs, envelopes, instrument scaffolds), need many quick drafts, or want centralized policy and logging.

Or use the built-in wrapper for a single command:

```bash
./run.sh ai-csd "Return a complete Csound .csd with a gentle envelope and a 3-note motif at 120 BPM. Output only .csd." && ./run.sh hear
```

Tip: See [Run the FountainAI Gateway Locally](../../docs/run-gateway-locally.md) for source build steps and a single copy/paste curl.

## 6. Run Tests
Execute the unit tests:

```bash
tutor test
```

Expected: Tests pass, confirming `CsoundPlayer` loads `hello.csd` without error.

## 7. Exercise — From Motif To Phrase (Hands-On)
Turn the three-note motif into something you can tweak live:

1) Generate the motif helper and switch mode

```bash
./setup.sh
CS_MOTIF=1 tutor run
```

2) Tweak the motif in `Sources/HelloCsound/Motif.swift`

```swift
// Try your own pitches/durations (Hz, seconds)
let csd = makeMotifCSD(
  frequencies: [440, 494, 523, 587],
  durations:   [0.40, 0.40, 0.60, 0.80]
)
```

3) Re‑run and listen to length/shape changes

```bash
CS_MOTIF=1 tutor run
```

Ideas to explore next:
- Use smaller steps for a calmer contour; larger leaps for tension.
- Repeat and vary the last note (rhythmic echo) to suggest a cadence.
- Layer two parts by duplicating `i` lines with small time offsets.

## 8. Classic Score With LilyPond (Optional)
Prefer traditional notation? Export the motif to a LilyPond `.ly` file and engrave a PDF if you have LilyPond installed.

1) Export the motif to `motif.ly` (offline)

```bash
CS_MOTIF=1 LY_EXPORT=1 tutor run
```

2) Engrave with LilyPond (installed separately)

```bash
lilypond motif.ly   # produces motif.pdf
```

Notes:
- Export maps the motif frequencies to nearest equal‑tempered pitches and durations at 120 BPM.
- You can set the export tempo with `LY_TEMPO`, e.g., `LY_TEMPO=90` for slower note values.
- The exporter also supports dotted durations when they are the closest fit.
- You can change the motif arrays in `Sources/HelloCsound/Motif.swift` and re‑export.
- LilyPond isn’t bundled; install it via your package manager or from lilypond.org.

## 9. Triads As Chords (Optional)
Explore harmony with simple triads and export them as chord notation.

1) Render a triad and (optionally) export a LilyPond chord

```bash
CS_TRIAD=1 TRIAD_QUALITY=minor tutor run
CS_TRIAD=1 TRIAD_QUALITY=major LY_EXPORT=1 LY_TEMPO=72 tutor run  # writes triad.ly
```

2) Engrave with LilyPond (installed separately)

```bash
lilypond triad.ly
```

Notes:
- Root defaults to C4 (261.63 Hz), held for 1 second.
- `TRIAD_QUALITY` accepts `major` (default) or `minor`.
- Export maps to the nearest equal‑tempered pitches and duration tokens (supports dotted).

## 10. Two‑Voice Accompaniment (Optional)
Add a simple bass accompaniment (pedal tone) beneath your motif and engrave both voices.

1) Export the duo score (melody + bass)

```bash
CS_MOTIF=1 LY_EXPORT=1 LY_DUO=1 tutor run   # writes motif_duo.ly
```

2) Engrave with LilyPond

```bash
lilypond motif_duo.ly
```

Notes:
- The duo uses a pedal note one octave (or more) below the motif’s first pitch.
- This keeps the harmony grounded while you explore melodic contour — a classic sketching technique.
- Customize the bass root by editing the code path (search for `bassRoot` in the generated `main.swift`) or extend the helper to follow chord roots.

## From Sine To Soundscape (Mental Model)
```
hello.csd ──▶ CsoundPlayer.play() ──▶ [sine wave samples]
```

Evolve the score from a single tone to a contour (envelope), to a motive (multiple `i` events), to timbre (layers/filters). The fewer variables you change at once, the clearer your musical decisions.

## Troubleshooting
- Permission denied: `chmod +x setup.sh` and re-run.
- `hello.csd not found`: re-run `./setup.sh` to restore the score file.
- Build errors: ensure Swift 6.1+ is installed and re-check with `swift --version`.

## Next Steps
Continue to [02 – Hello FountainAI](../01-hello-fountainai/README.md) to explore a SwiftUI greeting.

## See Also
- [Dependency Management Deep Dive](../../docs/dependency-management-deep-dive.md)

## Excursus: Csound Studio (Advanced Preview)
If you want to see where this lesson is heading, try the Csound Studio excursus — a richer SwiftUI app with chat, drop‑zone, LilyPond export, and optional Toolsmith integration.

- Path: `./excursus/csound-studio/`
- Build: `cd tutorials/01-hello-csound/excursus/csound-studio && ./run.sh build`
- Run: `./run.sh run`
- Tests: `./run.sh test`

Notes
- It’s intentionally outside the mainline CI to avoid mixing advanced dependencies into beginner steps.
- The embedded provisioning script can prepare a Linux VM image (opt‑in) for LilyPond/Csound inside a Toolsmith sandbox.
