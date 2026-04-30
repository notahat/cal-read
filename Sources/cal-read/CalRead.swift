import ArgumentParser
import Foundation

@main
struct CalRead: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cal-read",
        abstract: "Query events from Apple Calendar. Always outputs JSON.",
        discussion: """
            Outputs a JSON array of events. Each event has:
              title    – event title (string)
              start    – ISO 8601 datetime, or YYYY-MM-DD for all-day events
              end      – ISO 8601 datetime, or YYYY-MM-DD for all-day events
              calendar – calendar name (string)
              notes    – event notes (string, omitted if empty)

            Errors output {"error": "..."} to stdout with a non-zero exit code.
            """
    )

    @Option(name: .long, help: "Start date (YYYY-MM-DD). Defaults to today.")
    var from: String?

    @Option(name: .long, help: "End date (YYYY-MM-DD). Defaults to 7 days from today.")
    var to: String?

    @Option(name: .long, help: "Restrict results to this calendar name. Repeatable.")
    var calendar: [String] = []

    @Flag(name: .long, help: "List available calendar names and exit.")
    var listCalendars = false

    mutating func run() throws {
        guard let reader = CalendarReader.create() else {
            printJSON(ErrorResponse(error: "Calendar access denied"))
            throw ExitCode(1)
        }

        if listCalendars {
            printJSON(reader.listCalendars())
            return
        }

        let (startDate, endDate) = try parseDateRange()
        printJSON(reader.fetchEvents(from: startDate, to: endDate, calendarNames: calendar))
    }

    private func parseDateRange() throws -> (Date, Date) {
        let today = Calendar.current.startOfDay(for: Date())
        let defaultEnd = Calendar.current.date(byAdding: .day, value: 7, to: today)!

        let startDate = try from.map { try parseDate($0) } ?? today
        let endDate = try to.map { try parseDate($0, endOfDay: true) } ?? defaultEnd

        return (startDate, endDate)
    }

    private func parseDate(_ string: String, endOfDay: Bool = false) throws -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        guard let date = formatter.date(from: string) else {
            printJSON(ErrorResponse(error: "Invalid date '\(string)'. Use YYYY-MM-DD format."))
            throw ExitCode(1)
        }

        let startOfDay = Calendar.current.startOfDay(for: date)
        if endOfDay {
            return Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        }
        return startOfDay
    }
}

private func printJSON<T: Encodable>(_ value: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? encoder.encode(value),
          let string = String(data: data, encoding: .utf8)
    else { return }
    print(string)
}
