# 03 – Data Persistence with FountainStore

This tutorial demonstrates how to persist simple data using **FountainStore**. You will create a minimal `Note` model, save instances, and load them back into memory.

## 1. Define a data model
Create a struct conforming to `Codable` so it can be serialized to disk:

```swift
struct Note: Codable, Identifiable {
    let id: UUID
    var text: String
}
```

## 2. Initialize the store
Instantiate a store that writes to a JSON file:

```swift
let store = FountainStore<Note>(filename: "notes.json")
```

## 3. Save a note
Construct a new note and persist it:

```swift
let note = Note(id: UUID(), text: "Remember the milk")
try store.save(note)
```

## 4. Load all notes
Retrieve every note stored on disk:

```swift
let notes: [Note] = try store.load()
```

## 5. Retrieve a specific note
Find a note by its identifier after loading:

```swift
if let first = notes.first(where: { $0.id == note.id }) {
    print(first.text)
}
```

With these building blocks you can manage persistent collections of notes in your FountainAI apps.

