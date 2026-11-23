class_name LogEntries
## Auto-written logbook lines, one per discoverable clue.

const LINES := {
	"lighthouse": "Climbed the tower. Lens turns smooth on its weights.",
	"cottage": "Stove draws well. Found 1970s oceanography logs on the shelf.",
	"shipwreck": "East stack: old trawler wreck. Canister stamped PROJECT PELAGIC 1974 wedged in the hull.",
	"seacave": "West echo cave: red acoustic buoy in the arch. Battery pack still warm. Shouldn't be.",
}

## Entry text for a given day, built from what was found that day.
static func compose(day: int) -> String:
	var parts: Array = [Days.get_day(day).barometer.replace("Barometer: ", "Glass ")]
	for id in LINES:
		if GameState.discovered_day.get(id, -1) == day:
			parts.append(LINES[id])
	if parts.size() == 1:
		parts.append("Quiet day. Nothing new to record.")
	return " ".join(parts)
