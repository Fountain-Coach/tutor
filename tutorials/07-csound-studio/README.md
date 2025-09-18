# 07 – Csound Studio (Chat + Drop)

A small macOS SwiftUI app that combines two panes:
- Left: Chat with an LLM about Csound (ask for instruments/scores); paste or insert generated `.csd`.
- Right: Drag & Drop area for `.csd` files — play the result and optionally export/engrave a LilyPond score.

Everything runs locally. The only remote hop is the Gateway’s outbound HTTPS call to your provider (e.g., OpenAI) using your API key.

## Run Locally (SwiftUI App)

```bash
cd tutorials/07-csound-studio
./run.sh open     # macOS: opens the SwiftPM project in Xcode
# or
./run.sh build && ./run.sh run
```

- Playback uses `afplay` (macOS) from a temporary WAV file. If audio isn’t available, the WAV path is printed.
- LilyPond PDFs require `lilypond` installed; exporting still writes a `.ly` file if LilyPond isn’t present.

## Optional: LLM Chat

To request `.csd` from a local Gateway (no Docker), run the Gateway from source and export your provider key:

```bash
# From repo root
export OPENAI_API_KEY="sk-..."
Scripts/run-gateway-source.sh start --dev --no-auth

# Then in another terminal
cd tutorials/07-csound-studio
export LLM_GATEWAY_URL=http://127.0.0.1:8080/api/v1
export FOUNTAIN_AI_KEY=local-dev-key
./run.sh run
```

Inside the app, type a prompt (e.g., “Write a Csound .csd with a gentle envelope and a 3‑note motif at 120 BPM. Output only .csd.”) and click “Ask”. If the Gateway is healthy, the chat pane shows the response and you can paste it into the right pane to play/export.

## Project Layout

- `Sources/CsoundStudio/App.swift` — SwiftUI entry.
- `Sources/CsoundStudio/MainSplitView.swift` — two‑pane layout (chat + drop).
- `Sources/CsoundStudio/ChatView.swift` — simple Gateway chat client (local Gateway).
- `Sources/CsoundStudio/DropZoneView.swift` — drag/drop `.csd`, play/export.
- `Sources/CsoundStudio/CsoundPlayer.swift` — minimal simulator for `.csd` → samples.
- `Sources/CsoundStudio/Playback.swift` — writes WAV + tries `afplay`.
- `Sources/CsoundStudio/LilyPond.swift` — export `.ly` and try engraving via `lilypond`.

## Test

```bash
./run.sh test
```

Runs a minimal unit test that verifies `CsoundPlayer` can synthesize samples from a tiny in‑memory `.csd`.

