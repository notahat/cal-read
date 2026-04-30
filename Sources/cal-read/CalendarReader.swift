import EventKit
import Foundation

// Provides read-only access to Apple Calendar via EventKit.
// Responsible only for fetching and formatting data; output is handled by callers.
struct CalendarReader {
    private let store: EKEventStore

    // Requests full read access to calendar events, blocking until the user responds.
    // Returns nil if access is denied or an error occurs.
    static func create() -> CalendarReader? {
        let store = EKEventStore()
        let semaphore = DispatchSemaphore(value: 0)
        var accessGranted = false

        store.requestFullAccessToEvents { granted, _ in
            accessGranted = granted
            semaphore.signal()
        }
        semaphore.wait()

        return accessGranted ? CalendarReader(store: store) : nil
    }

    private init(store: EKEventStore) {
        self.store = store
    }

    func listCalendars() -> [CalendarInfo] {
        store.calendars(for: .event).map {
            CalendarInfo(name: $0.title, type: typeName(for: $0.type))
        }
    }

    func fetchEvents(from startDate: Date, to endDate: Date, calendarNames: [String]) -> [EventInfo] {
        let matchingCalendars = resolveCalendars(calendarNames)
        guard calendarNames.isEmpty || !matchingCalendars.isEmpty else {
            return []
        }

        let predicate = store.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendarNames.isEmpty ? nil : matchingCalendars
        )
        return store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map(formatEvent)
    }

    private func resolveCalendars(_ names: [String]) -> [EKCalendar] {
        guard !names.isEmpty else { return [] }
        return store.calendars(for: .event).filter { names.contains($0.title) }
    }

    private func formatEvent(_ event: EKEvent) -> EventInfo {
        EventInfo(
            title: event.title ?? "",
            start: formatDate(event.startDate, isAllDay: event.isAllDay),
            end: formatDate(event.endDate, isAllDay: event.isAllDay),
            calendar: event.calendar.title,
            notes: event.notes.flatMap { $0.isEmpty ? nil : $0 }
        )
    }

    private func formatDate(_ date: Date, isAllDay: Bool) -> String {
        isAllDay
            ? ISO8601DateFormatter.dateOnly.string(from: date)
            : ISO8601DateFormatter.withTimezone.string(from: date)
    }

    private func typeName(for type: EKCalendarType) -> String {
        switch type {
        case .local: return "local"
        case .calDAV: return "calDAV"
        case .exchange: return "exchange"
        case .subscription: return "subscription"
        case .birthday: return "birthday"
        @unknown default: return "unknown"
        }
    }
}

private extension ISO8601DateFormatter {
    static let dateOnly: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()

    static let withTimezone: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = .current
        return formatter
    }()
}
