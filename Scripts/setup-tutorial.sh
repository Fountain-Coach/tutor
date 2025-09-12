#!/usr/bin/env bash
set -euo pipefail

# setup-tutorial.sh — scaffold a minimal local Swift package for a tutorial
#
# Usage:
#   Scripts/setup-tutorial.sh <AppName> [BundleID] [--local|--upstream]
#   SETUP_MODE=upstream Scripts/setup-tutorial.sh <AppName> [BundleID]
#
# Notes:
# - Local mode (default) creates a tiny SPM executable with main.swift in this folder.
# - Upstream mode tries to invoke the FountainAI monorepo's scaffolder, then
#   copies the generated main.swift here. If it fails, we fall back to local.

APP_NAME=""
BUNDLE_ID=""
MODE="${SETUP_MODE:-local}"  # local | upstream
PROFILE="basic"               # basic | ai | persist | midi2 | capstone | full-client

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --upstream)
      MODE="upstream"; shift ;;
    --local)
      MODE="local"; shift ;;
    --profile)
      PROFILE="${2:-basic}"; shift 2 ;;
    --bundle-id)
      BUNDLE_ID="${2:-}"; shift 2 ;;
    -h|--help)
      echo "Usage: $(basename "$0") <AppName> [BundleID] [--local|--upstream]"; exit 0 ;;
    *)
      if [[ -z "$APP_NAME" ]]; then APP_NAME="$1";
      elif [[ -z "$BUNDLE_ID" ]]; then BUNDLE_ID="$1";
      fi
      shift ;;
  esac
done

if [[ -z "$APP_NAME" ]]; then
  echo "Usage: $(basename "$0") <AppName> [BundleID] [--local|--upstream]" >&2
  exit 2
fi

TARGET_DIR="$(pwd)"
PKG_FILE="$TARGET_DIR/Package.swift"
SRC_DIR="$TARGET_DIR/Sources/$APP_NAME"
MAIN_FILE="$SRC_DIR/main.swift"

generate_local() {
  if [[ "${USE_FOUNTAIN_DEPS:-0}" == "1" ]]; then
    # Determine target dependencies based on profile
    TARGET_DEPS=()
    case "$PROFILE" in
      basic)
        # no external deps
        ;;
      ai)
        TARGET_DEPS+=(".product(name: \"LLMGatewayAPI\", package: \"the-fountainai\")")
        ;;
      persist)
        TARGET_DEPS+=(".product(name: \"PersistAPI\", package: \"the-fountainai\")")
        TARGET_DEPS+=(".product(name: \"FountainStoreClient\", package: \"the-fountainai\")")
        ;;
      midi2)
        TARGET_DEPS+=(".product(name: \"MIDI2Models\", package: \"the-fountainai\")")
        TARGET_DEPS+=(".product(name: \"MIDI2Core\", package: \"the-fountainai\")")
        TARGET_DEPS+=(".product(name: \"SSEOverMIDI\", package: \"the-fountainai\")")
        TARGET_DEPS+=(".product(name: \"FlexBridge\", package: \"the-fountainai\")")
        ;;
      capstone)
        TARGET_DEPS+=(".product(name: \"LLMGatewayAPI\", package: \"the-fountainai\")")
        TARGET_DEPS+=(".product(name: \"PersistAPI\", package: \"the-fountainai\")")
        TARGET_DEPS+=(".product(name: \"FountainStoreClient\", package: \"the-fountainai\")")
        TARGET_DEPS+=(".product(name: \"MIDI2Models\", package: \"the-fountainai\")")
        TARGET_DEPS+=(".product(name: \"MIDI2Core\", package: \"the-fountainai\")")
        TARGET_DEPS+=(".product(name: \"SSEOverMIDI\", package: \"the-fountainai\")")
        TARGET_DEPS+=(".product(name: \"FlexBridge\", package: \"the-fountainai\")")
        ;;
      full-client)
        TARGET_DEPS+=(".product(name: \"GatewayAPI\", package: \"the-fountainai\")")
        TARGET_DEPS+=(".product(name: \"LLMGatewayAPI\", package: \"the-fountainai\")")
        TARGET_DEPS+=(".product(name: \"PersistAPI\", package: \"the-fountainai\")")
        TARGET_DEPS+=(".product(name: \"SemanticBrowserAPI\", package: \"the-fountainai\")")
        ;;
    esac
    # Join without leading comma, with real newlines (no escape sequences)
    DEPS_JOINED=""
    for dep in "${TARGET_DEPS[@]}"; do
      if [[ -z "$DEPS_JOINED" ]]; then
        DEPS_JOINED="$dep"
      else
        DEPS_JOINED="$DEPS_JOINED,
                $dep"
      fi
    done

    cat > "$PKG_FILE" <<EOF
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "$APP_NAME",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "$APP_NAME", targets: ["$APP_NAME"])
    ],
    dependencies: [
        .package(url: "https://github.com/Fountain-Coach/the-fountainai.git", branch: "main")
    ],
    targets: [
        .executableTarget(name: "$APP_NAME", dependencies: [$DEPS_JOINED]),
        .testTarget(
            name: "${APP_NAME}Tests",
            dependencies: ["$APP_NAME"],
            path: "Tests/${APP_NAME}Tests"
        )
    ]
)
EOF
  else
    cat > "$PKG_FILE" <<EOF
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "$APP_NAME",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "$APP_NAME", targets: ["$APP_NAME"])
    ],
    targets: [
        .executableTarget(name: "$APP_NAME"),
        .testTarget(
            name: "${APP_NAME}Tests",
            dependencies: ["$APP_NAME"],
            path: "Tests/${APP_NAME}Tests"
        )
    ]
)
EOF
  fi

  mkdir -p "$SRC_DIR"
  # Always ensure a Greeter for tests; harmless if unused by main
  cat > "$SRC_DIR/Greeter.swift" <<'SWIFT'
import Foundation

public func greet() -> String {
    return "Hello, FountainAI!"
}
SWIFT

  # Write main.swift: AI UI for profiles with LLM, otherwise simple greet()
  if [[ "${USE_FOUNTAIN_DEPS:-0}" == "1" && ( "$PROFILE" == "ai" || "$PROFILE" == "capstone" || "$PROFILE" == "full-client" ) ]]; then
    # Prefer App.swift for @main; remove any main.swift copied from upstream
    rm -f "$MAIN_FILE"
    cat > "$SRC_DIR/App.swift" <<'SWIFT'
import SwiftUI
import LLMGatewayAPI

@main
struct AppEntry: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var prompt: String = "Say hello to FountainAI"
    @State private var responseText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LLM Gateway Chat").font(.title2)
            TextField("Your prompt", text: $prompt)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button(isLoading ? "Asking…" : "Ask") {
                    Task { await ask() }
                }
                .disabled(isLoading || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Divider()
            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            ScrollView { Text(responseText).frame(maxWidth: .infinity, alignment: .leading) }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }

    func ask() async {
        isLoading = true; defer { isLoading = false }
        do {
            let base = ProcessInfo.processInfo.environment["LLM_GATEWAY_URL"] ?? "http://localhost:8080/api/v1"
            guard let url = URL(string: base) else { errorMessage = "Invalid LLM_GATEWAY_URL"; return }
            let token = ProcessInfo.processInfo.environment["FOUNTAIN_AI_KEY"]
            let client = LLMGatewayClient(baseURL: url, bearerToken: token)
            let req = ChatRequest(model: "gpt-4o-mini", messages: [ChatMessage(role: "user", content: prompt)])
            let result = try await client.chat(req)
            responseText = String(describing: result)
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
SWIFT
  else
    cat > "$MAIN_FILE" <<'SWIFT'
import Foundation

print(greet())
SWIFT
  fi
  mkdir -p "$TARGET_DIR/Tests/${APP_NAME}Tests"
  cat > "$TARGET_DIR/Tests/${APP_NAME}Tests/${APP_NAME}Tests.swift" <<EOF
import XCTest
@testable import $APP_NAME

final class ${APP_NAME}Tests: XCTestCase {
    func testGreetReturnsHello() {
        XCTAssertEqual(greet(), "Hello, FountainAI!")
    }
}
EOF
  # No shell shims or Makefiles; use the Swift Tutor CLI (see docs/tutor-cli.md).
  echo "Generated Package.swift and main.swift for $APP_NAME in $TARGET_DIR (local mode)"
}

attempt_upstream() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  local repodir="$tmpdir/the-fountainai"
  cleanup() { rm -rf "$tmpdir"; }
  echo "Fetching FountainAI monorepo…"
  git clone --depth 1 https://github.com/Fountain-Coach/the-fountainai.git "$repodir" >/dev/null
  echo "Attempting Swift-based scaffold (tutor)…"
  (
    cd "$(dirname "$0")/../tools/tutor-cli" && \
    export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" && \
    export SDKROOT="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)}" && \
    export CLANG_MODULE_CACHE_PATH="$PWD/.modulecache" && mkdir -p "$CLANG_MODULE_CACHE_PATH" && \
    swift run -c release tutor scaffold \
      -Xcc -fmodules-cache-path=$PWD/.modulecache \
      -Xswiftc -module-cache-path -Xswiftc $PWD/.swift-module-cache \
      --repo "$repodir" --app "$APP_NAME"
  ) || (
    # Fallback: build ad-hoc with swiftc to avoid SwiftPM manifest compilation
    echo "swift run failed; attempting direct swiftc build…" >&2; \
    cd "$(dirname "$0")/../tools/tutor-cli" && \
    export SDKROOT="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)}" && \
    mkdir -p .build && \
    swiftc Sources/TutorCLI/main.swift -o .build/tutor 2>/dev/null && \
    ./.build/tutor scaffold --repo "$repodir" --app "$APP_NAME"
  ) && {
  if [[ -f "$repodir/apps/$APP_NAME/main.swift" ]]; then
    mkdir -p "$SRC_DIR"
    cp "$repodir/apps/$APP_NAME/main.swift" "$MAIN_FILE"
    echo "Copied generated main.swift from upstream scaffold."
  fi
    USE_FOUNTAIN_DEPS=1 generate_local
    echo "Prepared local package using scaffolded main.swift."
    cleanup; return 0
  }
  echo "scaffold-cli path failed; will try Perl-based patcher…" >&2

  # Perl-based patcher as a robust fallback (avoids awk issues on macOS)
  echo "Scaffolding via Perl-based patcher…"
  mkdir -p "$repodir/apps/$APP_NAME"
  cat > "$repodir/apps/$APP_NAME/main.swift" <<'SWIFT'
import SwiftUI
import FountainAICore
import FountainAIAdapters
import LLMGatewayAPI

@main
struct AppEntry: App {
    @State private var settings = AppSettings()
    @State private var vm: AskViewModel? = nil
    @State private var settingsStore = DefaultSettingsStore(keychain: KeychainDefault())
    var body: some Scene {
        WindowGroup { MainView(vm: vm, onAsk: ask).onAppear { configure() } }
    }
    private func makeLLM() -> LLMService {
        let token: String? = (try? settingsStore.getSecret(for: settings.apiKeyRef ?? "")).flatMap { String(data: $0, encoding: .utf8) }
        switch settings.provider {
        case .openai:
            if let token, !token.isEmpty { return OpenAIAdapter(apiKey: token) } else { return MockLLMService() }
        case .customHTTP, .localServer:
            guard let urlStr = settings.baseURL, let url = URL(string: urlStr) else { return MockLLMService() }
            let client = LLMGatewayClient(baseURL: url, bearerToken: token)
            return LLMGatewayAdapter(client: client)
        }
    }
    private func configure() { do { settings = try settingsStore.load() } catch { }; vm = AskViewModel(llm: makeLLM(), browser: MockBrowserService()) }
    private func ask(_ q: String) async -> String { await vm?.ask(question: q); return await vm?.answer ?? "" }
}
struct MainView: View {
    let vm: AskViewModel?; let onAsk: (String) async -> String
    @State private var q = ""; @State private var a = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ask").font(.title2)
            TextField("Your question", text: $q)
            Button("Get Answer") { Task { a = await onAsk(q) } }
            Divider(); ScrollView { Text(a).frame(maxWidth: .infinity, alignment: .leading) }
        }.padding().frame(minWidth: 600, minHeight: 400)
    }
}
final class MockLLMService: LLMService { func chat(model: String, messages: [FountainAICore.ChatMessage]) async throws -> String { "(mock) " + (messages.last?.content ?? "") } }
final class MockBrowserService: BrowserService { func analyze(url: String, corpusId: String?) async throws -> (title: String?, summary: String?) { (nil, nil) } }
SWIFT

  perl -0777 -i -pe "BEGIN{\$app='$APP_NAME'}; s/(let\s+fullProducts[\s\S]*?=\s*\[)([\s\S]*?)(\n\s*\])/
  \$1\$2\n    .executable(name: \"\$app\", targets: [\"\$app\"]),\n\$3/s" "$repodir/Package.swift"

  perl -0777 -i -pe "BEGIN{\$app='$APP_NAME'}; s/(let\s+leanProducts[\s\S]*?=\s*\[)([\s\S]*?)(\n\s*\])/
  \$1\$2\n    .executable(name: \"\$app\", targets: [\"\$app\"]),\n\$3/s" "$repodir/Package.swift"

  perl -0777 -i -pe "BEGIN{\$app='$APP_NAME'}; s/(let\s+fullTargets[\s\S]*?=\s*\[)([\s\S]*?)(\n\s*\])/
  \$1\$2\n    .executableTarget(\n        name: \"\$app\",\n        dependencies: [\"FountainAIAdapters\", \"FountainAICore\"],\n        path: \"apps\/\$app\"\n    ),\n\$3/s" "$repodir/Package.swift"

  perl -0777 -i -pe "BEGIN{\$app='$APP_NAME'}; s/(let\s+leanTargets[\s\S]*?=\s*\[)([\s\S]*?)(\n\s*\])/
  \$1\$2\n    .executableTarget(\n        name: \"\$app\",\n        dependencies: [\"FountainAIAdapters\", \"FountainAICore\"],\n        path: \"apps\/\$app\"\n    ),\n\$3/s" "$repodir/Package.swift"

  # Copy scaffolded main.swift into tutorial; keep local Package.swift for portability
  mkdir -p "$SRC_DIR"
  cp "$repodir/apps/$APP_NAME/main.swift" "$MAIN_FILE" || true
  echo "Copied generated main.swift from Perl-based scaffold."
  USE_FOUNTAIN_DEPS=1 generate_local
  echo "Prepared local package using scaffolded main.swift."
  cleanup; return 0
}

if [[ "$MODE" == "upstream" ]]; then
  if ! attempt_upstream; then
    # If a non-basic profile was requested, include upstream deps even on fallback
    if [[ "$PROFILE" != "basic" ]]; then USE_FOUNTAIN_DEPS=1; fi
    generate_local
  fi
else
  # In local mode, include upstream deps when a richer profile is requested
  if [[ "$PROFILE" != "basic" ]]; then USE_FOUNTAIN_DEPS=1; fi
  generate_local
fi
