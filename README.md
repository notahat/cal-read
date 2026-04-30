# cal-read

A read-only command-line tool for querying Apple Calendar events. Designed to be
called by AI assistants (e.g. Claude Code) that need structured access to calendar
data.

## Usage

```
cal-read [--from DATE] [--to DATE] [--calendar NAME] [--list-calendars]
```

| Flag | Description |
|------|-------------|
| `--from DATE` | Start of date range (YYYY-MM-DD). Defaults to today. |
| `--to DATE` | End of date range (YYYY-MM-DD). Defaults to 7 days from today. |
| `--calendar NAME` | Restrict results to this calendar. Repeatable. |
| `--list-calendars` | List available calendar names and exit. |

## Output

All output is JSON. Events include `title`, `start`, `end`, `calendar`, and `notes`
(omitted if empty). Datetimes use ISO 8601 with local timezone offset; all-day events
use date-only format (`YYYY-MM-DD`).

```json
[
  {
    "calendar": "Work",
    "end": "2026-05-01T10:00:00+10:00",
    "start": "2026-05-01T09:00:00+10:00",
    "title": "Team standup"
  }
]
```

Errors output `{"error": "..."}` to stdout with a non-zero exit code.

## Building

Requires Swift 5.9+ and macOS 14+.

```sh
swift build -c release
```

The binary will be at `.build/release/cal-read`.

## Permissions

On first run, macOS will prompt for calendar access. The tool requests read-only
access and cannot modify calendar data.
