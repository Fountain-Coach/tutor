# 03 – Data Persistence with FountainStore

Template-first workflow: `setup.sh` scaffolds a minimal Swift package from the FountainAI monorepo; build and run locally to explore the concept.

Persist simple data using **FountainStore** within a minimal SPM app. This tutorial uses the template workflow (no full Gateway/services required) and focuses on saving and loading a tiny `Note` model.

## Before you begin
- Run all commands from `tutorials/03-data-persistence-fountainstore/`.
- If needed, make the script executable:
  ```bash
  chmod +x setup.sh
  ```

## 1. Scaffold the project
By default this tutorial uses the `ai` profile for client libraries. To include persistence libraries, run with the persistence profile:

```bash
./setup.sh --profile persist --upstream
```

Advanced: `./setup.sh --upstream` (or `SETUP_MODE=upstream ./setup.sh`) attempts to scaffold via the upstream monorepo and copy its generated files here; falls back to local if it fails.

## 2. Define a data model
Create a struct conforming to `Codable` so it can be serialized to disk:

```swift
struct Note: Codable, Identifiable {
    let id: UUID
    var text: String
}
```

## 3. Initialize the store
Instantiate a store that writes to a JSON file:

```swift
let store = FountainStore<Note>(filename: "notes.json")
```

## 4. Save a note
Construct a new note and persist it:

```swift
let note = Note(id: UUID(), text: "Remember the milk")
try store.save(note)
```

## 5. Load all notes
Retrieve every note stored on disk:

```swift
let notes: [Note] = try store.load()
```

## 6. Retrieve a specific note
Find a note by its identifier after loading:

```swift
if let first = notes.first(where: { $0.id == note.id }) {
    print(first.text)
}
```

With these building blocks you can manage persistent collections of notes in your FountainAI apps.

## Build and run
Compile and execute the package:

```bash
./build.sh
./run.sh
```

Expected: The program runs without error. Add temporary `print(notes.count)` or `print(first.text)` statements to verify the data roundtrip locally.

## Run tests
```bash
./test.sh
```
Add tests for save/load helpers and edge cases (empty file, corrupt JSON) as you expand functionality.

## Troubleshooting
- Permission denied: `chmod +x setup.sh` and re-run.
- Build errors: ensure Swift 6.1+ is installed; check `swift --version`.
- File not found: ensure the `filename` path is writable (e.g., use a simple filename like `notes.json` in the current directory during development).

## Next steps
Proceed to [04 – Multimedia with MIDI2](../04-multimedia-midi2/README.md) to integrate audio playback and timing updates.

## See also
- [Deep dive: Dependency management with SwiftPM and profiles](../../docs/dependency-management-deep-dive.md)
