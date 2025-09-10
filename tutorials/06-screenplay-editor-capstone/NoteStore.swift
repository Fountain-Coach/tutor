import FountainStore

struct Note: Codable, Identifiable {
    let id: UUID
    var text: String
}

let store = FountainStore<Note>(filename: "notes.json")

func save(_ text: String) throws {
    try store.save(Note(id: UUID(), text: text))
}
