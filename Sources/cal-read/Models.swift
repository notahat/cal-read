import Foundation

struct CalendarInfo: Encodable {
    let name: String
    let type: String
}

// Custom encoding omits the `notes` field when nil rather than encoding null.
struct EventInfo: Encodable {
    let title: String
    let start: String
    let end: String
    let calendar: String
    let notes: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(start, forKey: .start)
        try container.encode(end, forKey: .end)
        try container.encode(calendar, forKey: .calendar)
        try container.encodeIfPresent(notes, forKey: .notes)
    }

    private enum CodingKeys: String, CodingKey {
        case title, start, end, calendar, notes
    }
}

struct ErrorResponse: Encodable {
    let error: String
}
