# Dictionary to map calendar keys to their corresponding names.
# One word calendars don't need to be added; calendar.jobs would map to Jobs by default.
# calendar.hello_world should be added.
CALENDAR_NAMES = {"calendar.home": "Home"}
# Day names shown in the calendar list.
DAY_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
# Max entries to send to the ESPHome device.
MAX_ENTRIES = 8


def iso_key(val, fallback="9999-12-31T23:59:59"):
    """Return a lexicographic key for ISO timestamps without importing datetime."""
    if val is None:
        return fallback
    v = str(val)
    return v.replace("Z", "+00:00")


def day_from_date(date_str):
    try:
        return int(str(date_str).split("-")[2])
    except Exception:
        return 0


def weekday_from_date(date_str):
    """
    Calculate weekday (0=Mon) using Zeller-like arithmetic without imports.
    Assumes date_str like YYYY-MM-DD.
    """
    try:
        parts = str(date_str).split("-")
        y = int(parts[0])
        m = int(parts[1])
        d = int(parts[2])
        if m < 3:
            m += 12
            y -= 1
        # Zeller congruence: h = (d + 13(m+1)//5 + K + K//4 + J//4 + 5J) % 7
        K = y % 100
        J = y // 100
        h = (d + (13 * (m + 1)) // 5 + K + K // 4 + J // 4 + 5 * J) % 7
        # Convert to 0=Monday mapping
        return (h + 5) % 7
    except Exception:
        return 0


def convert_calendar_format(data, today):
    # Group events by date and count entries
    events_by_date = {}
    entrie_count = 0
    closest_end_time = None

    for calendar_key, events_list in data.items():
        for event in events_list["events"]:
            if "description" in event:
                event.pop("description")

            parts = event["start"].split("T")
            event_date = parts[0]
            event_time = parts[1] if len(parts) > 1 else None

            # Move multi-day events that started before today up to today
            if event_date < today:
                event["start"] = today if event_time is None else f"{today}T{event_time}"
                event_date = today

            # Friendly calendar name
            event["calendar_name"] = CALENDAR_NAMES.get(
                calendar_key, calendar_key.split(".")[1].capitalize()
            )

            # Split location into name/address lines
            if "location" in event:
                location_lines = event["location"].split("\n")
                if len(location_lines) >= 1:
                    event["location_name"] = location_lines[0]
                event.pop("location")

            # Bucket events by date
            events_by_date.setdefault(event_date, []).append(event)

    sorted_dates = sorted(events_by_date.keys())
    result = []

    for date in sorted_dates:
        all_day_events = []
        other_events = []
        for event in events_by_date[date]:
            if entrie_count == MAX_ENTRIES:
                break
            if "T" not in event["start"]:
                all_day_events.append(event)
            else:
                other_events.append(event)
            entrie_count += 1

        if other_events and date == today:
            closest_end_time = sorted(
                other_events, key=lambda item: iso_key(item.get("end")), reverse=False
            )[0].get("end")

        if all_day_events or other_events:
            other_events.sort(
                key=lambda item: iso_key(item.get("start")), reverse=False
            )
            day_item = {
                "date": date,
                "day": day_from_date(date),
                # Cast to int because bools upset some ESPHome configs
                "is_today": int(date == today),
                "day_name": DAY_NAMES[weekday_from_date(date)],
                "all_day": all_day_events,
                "other": other_events,
            }
            result.append(day_item)

    return (result, closest_end_time)


input_data = data["calendar"]
today = data["now"]
converted_data = convert_calendar_format(input_data, today)
output["entries"] = converted_data[0]
output["closest_end_time"] = converted_data[1]
