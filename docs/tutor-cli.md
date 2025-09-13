# Tutor CLI

A small Swift command-line tool to scaffold, build, run, and test tutorials without Xcode.

## Install

- One‑time install to `~/.local/bin/tutor`:
  - `Scripts/install-tutor.sh`
- Ensure `~/.local/bin` is on your PATH:
  - `export PATH=$HOME/.local/bin:$PATH`
  - Add permanently (zsh): `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc`

Or install via the CLI itself (after building it once):

- `cd tools/tutor-cli && swift build -c release && .build/release/tutor install`

## Usage

- From any tutorial folder:
  - Build: `tutor build`
  - Run: `tutor run`
  - Test: `tutor test`
- Help:
  - `tutor --help`
  - `tutor help`
- Options:
  - `--dir <path>` to target a different folder
  - `--verbose` or `-v` to print SwiftPM verbose output
  - `--no-progress` to disable the live status line
  - `--quiet` to suppress Swift output and show only status
  - `--json-summary` to emit a final JSON summary to stdout (pair with `--quiet` for machine use)
  - `--ci` to emit GitHub Actions annotations for diagnostics
  - `--midi` to emit events as MIDI SysEx on a virtual source (macOS)
  - `--midi-virtual-name <name>` to name the virtual MIDI source (default `TutorCLI`)
  - Auto-parallelism: if `--jobs/-j` is not provided, uses CPU cores
  - `--` to pass flags to underlying `swift` (e.g., `-- -c release`)

## Status & Machine Readability

- Live status files are written to `<tutorial>/.tutor/` during `build`, `run`, or `test`:
  - `status.json` — current phase, status, elapsed, and final exit code; safe to poll.
  - `events.ndjson` — newline‑delimited JSON event stream (log, phase changes, warnings, errors).
- Query status at any time:
  - Human: `tutor status --dir <tutorial>`
  - JSON: `tutor status --dir <tutorial> --json`
  - Watch: `tutor status --dir <tutorial> --watch`
- Control files:
  - `--no-status-file` to skip writing `status.json`
  - `--status-file <path>` and `--event-file <path>` to override defaults

## Local Server (Agents)

- Minimal endpoints for automation:
  - `tutor serve [--dir <path>] [--port <n>|--port 0] [--no-auth] [--dev] [--socket <path>]`
- Default bind: `127.0.0.1:<port>`; when `--port 0`, the OS picks a random port.
- A bearer token is generated in `<tutorial>/.tutor/token` and required unless `--no-auth` is passed.
- Endpoints:
  - `GET /health` → `{ "ok": true }`
  - `GET /status` → contents of `.tutor/status.json`
  - `GET /summary` → JSON summary (same as `--json-summary`)
  - `GET /events` → Server-Sent Events (SSE) stream; emits an event per `.tutor/events.ndjson` line
- Dev profile: add `--dev` to disable auth locally. Otherwise, a token in `.tutor/token` is required.
- Optional MIDI mirroring from server: `--midi [--midi-virtual-name <name>]` to broadcast events as SysEx via a virtual MIDI source.
- Unix socket mode: `--socket <path>` starts a Unix domain socket that streams SSE lines (no HTTP headers) for sandboxed environments.

OpenAPI Spec:
- (Optional) You can keep a spec in your repo for reference; the server focuses on minimal endpoints for agents.

### Unix Socket Client Examples

- socat (quickest):
  - `socat - UNIX-CONNECT:/tmp/tutor.sse`
- Python 3 (portable):
  ```python
  # unix_sse_client.py
  import socket, sys
  path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/tutor.sse"
  s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
  s.connect(path)
  buf = b""
  while True:
      data = s.recv(4096)
      if not data: break
      buf += data
      while b"\n\n" in buf:
          chunk, buf = buf.split(b"\n\n", 1)
          print(chunk.decode(errors="ignore"))
  ```
  - Run server: `tutor serve --dir <tutorial> --socket /tmp/tutor.sse --dev`
  - Run client: `python3 unix_sse_client.py /tmp/tutor.sse`

- Swift (POSIX):
  ```swift
  // unix_sse_client.swift
  import Foundation
  import Darwin

  let path = CommandLine.arguments.dropFirst().first ?? "/tmp/tutor.sse"

  // Create AF_UNIX stream socket
  let fd = socket(AF_UNIX, SOCK_STREAM, 0)
  guard fd >= 0 else { perror("socket"); exit(1) }

  var addr = sockaddr_un()
  addr.sun_family = sa_family_t(AF_UNIX)
  // Copy path into sun_path (ensure it fits)
  let bytes = [UInt8](path.utf8)
  if bytes.count >= MemoryLayout.size(ofValue: addr.sun_path) { fatalError("Path too long") }
  withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
    let buf = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: UInt8.self)
    for (i, b) in bytes.enumerated() { buf[i] = b }
    buf[bytes.count] = 0
  }
  let len = socklen_t(MemoryLayout.size(ofValue: addr.sun_family) + bytes.count + 1)
  var a = addr
  let res = withUnsafePointer(to: &a) {
    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(fd, $0, len) }
  }
  if res != 0 { perror("connect"); exit(2) }

  var buffer = Data()
  var tmp = [UInt8](repeating: 0, count: 4096)
  while true {
    let n = read(fd, &tmp, tmp.count)
    if n <= 0 { break }
    buffer.append(tmp, count: n)
    while let range = buffer.range(of: Data("\n\n".utf8)) {
      let chunk = buffer.subdata(in: 0..<range.lowerBound)
      if let s = String(data: chunk, encoding: .utf8) {
        print(s)
      }
      buffer.removeSubrange(0..<range.upperBound)
    }
  }
  ```
  - Build: `swiftc unix_sse_client.swift -o unix-sse`
  - Run: `./unix-sse /tmp/tutor.sse`

### Native Viewer (Teatro‑Style)

- Launch the macOS viewer for status/events:
  - `tutor viewer` (run from a tutorial folder)
- Shows status (phase, elapsed, exit code, errors) and live events.
- If `.tutor` is empty, run `tutor doctor` or any `tutor build/test` to seed files.

## MIDI Output (Experimental)

- macOS only: the CLI can expose a virtual MIDI source and send each event as a compact SysEx message (manufacturer ID 0x7D), compatible with FountainAI's `SSEOverMIDI`.
- Enable: `tutor build --midi` (or with any subcommand).
- Connect your DAW or MIDI monitor to the virtual port (default `TutorCLI`).
- Customize name: `--midi-virtual-name "TutorCLI-Status"`.
- Payload: a truncated JSON blob inside SysEx for status, warnings, errors, and final summary.
 - Internals: when the FountainAI package is present, the CLI links `SSEOverMIDI`; otherwise it falls back to a CoreMIDI shim that emits the same wire format.

## Error Taxonomy & Hints

- On failure, the CLI classifies errors and provides concise hints.
- Categories: `DEPENDENCY_NETWORK`, `RESOLVE_GRAPH`, `COMPILE`, `LINK`, `TEST`, `RUNTIME`, `UNKNOWN`.
- Get a one‑shot machine summary:
  - `tutor build --json-summary --quiet`
  - Output includes `category`, `hint`, counts, and first errors/warnings.

## Live Status Feedback

- The CLI shows a live status line with spinner and elapsed time.
- Phases include: resolving, fetching/updating, compiling, linking, testing, and running.
- Use `--verbose` to see detailed SwiftPM lines while the status updates.

## Scaffold (advanced)

- Scaffold an app target inside a cloned FountainAI monorepo (used by `setup.sh --upstream`):
  - `tutor scaffold --repo /path/to/the-fountainai --app HelloFountainAI`

## Environment

- Builds set local caches to avoid macOS permission issues:
  - `.modulecache/` and `.swift-module-cache/` in the tutorial folder
- AI UI uses env vars:
  - `LLM_GATEWAY_URL` (default `http://localhost:8080/api/v1`)
  - `FOUNTAIN_AI_KEY` (optional bearer token)

## Notes

- The CLI is preferred. Profiles in `setup.sh` still control which FountainAI products your app depends on.
- See also: `docs/dependency-management-deep-dive.md` for profiles and SwiftPM behavior.
- Roadmap: `docs/tutor-cli-roadmap.md` tracks ongoing improvements.

## CI Usage (GitHub Actions)

- Example job that annotates logs and publishes a summary artifact:

```yaml
name: Tutor CI (example)
on: [push, pull_request]
jobs:
  tutor:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build Tutor CLI
        run: |
          cd tools/tutor-cli
          swift build -c release
          .build/release/tutor install
          echo "$HOME/.local/bin" >> $GITHUB_PATH
      - name: Build tutorial with CI annotations
        working-directory: tutorials/01-hello-fountainai
        run: |
          set +e
          tutor build --ci --quiet --json-summary > summary.json || true
          mkdir -p .tutor
          cp summary.json .tutor/summary.json || true
      - name: Upload artifacts (status/events/summary)
        uses: actions/upload-artifact@v4
        with:
          name: tutor-status
          path: |
            tutorials/01-hello-fountainai/.tutor/status.json
            tutorials/01-hello-fountainai/.tutor/events.ndjson
            tutorials/01-hello-fountainai/.tutor/summary.json
```

- Tips:
  - Use `--ci` to emit `::error` and `::warning` annotations for parsed diagnostics.
  - Pair with `--quiet` and `--json-summary` to keep logs succinct and capture structured results.
  - Upload `.tutor/` artifacts for PR triage and debugging.
