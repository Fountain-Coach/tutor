# 03 – Data Persistence with FountainStore

This tutorial demonstrates how to persist simple data using **FountainStore**. You will create a minimal `Note` model, save instances, and load them back into memory.

## 1. Scaffold the project
Run the setup script, which uses the FountainAI app-creation template from the [the-fountainai](https://github.com/Fountain-Coach/the-fountainai) repo:

```bash
./setup.sh
```

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
swift build
swift run
```

