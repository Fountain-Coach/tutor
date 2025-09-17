# 01 – Hello Csound

This lesson isn’t just about “making it work.” It’s about making music, right now — with Csound as the synthesizer and FountainAI as your composer companion. You’ll start from a single sine wave and build toward musical intent, while keeping the path to AI‑assisted composition only one step away.

Template‑first workflow: `setup.sh` scaffolds a minimal Swift package locally. You’ll generate a tiny `.csd` score and run a lightweight `CsoundPlayer` simulator that renders a short tone — then you’ll shape that tone musically, and see how AI can help you explore variations and ideas.

> No Binary Assets: only the text-based `hello.csd` file is bundled. Generated audio stays in memory and is not committed.

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
FountainAI can help you explore. In upstream mode you can ask the LLM for `.csd` variations (“make a mellow pad with two detuned oscillators” or “turn this motif into a 2‑bar arpeggio”).

If you want to try it:

```bash
./setup.sh --upstream --profile ai
export LLM_GATEWAY_URL=http://localhost:8080/api/v1
export FOUNTAIN_AI_KEY=YOUR_API_KEY
```

Then adapt a simple Swift call to request a new `.csd` instrument body or score (see [05 – AI Integration with OpenAPI](../05-ai-integration-openapi/README.md)). Paste the result into `hello.csd` and iterate. The AI is not the composer — you are — but it’s a great partner for fast “what‑ifs.”

Prompts you can try:
- “Write a Csound instrument with a slow attack, release, and subtle vibrato.”
- “Give me a 4‑note motif at 120 BPM as Csound score lines.”
- “Detune two oscillators by 3 cents and add a gentle low‑pass.”

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
