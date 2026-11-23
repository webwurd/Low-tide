class_name LogEntries
## Auto-written logbook lines, one per discoverable clue.

const LINES := {
	"lighthouse": "Climbed the tower. Lens turns smooth on its weights.",
	"cottage": "Stove draws well. Found 1970s oceanography logs on the shelf.",
	"shipwreck": "East stack: old trawler wreck. Canister stamped PROJECT PELAGIC 1974 wedged in the hull.",
	"seacave": "West echo cave: red acoustic buoy in the arch. Battery pack still warm. Shouldn't be.",
}

const FLAG_LINES := {
	"reported_canister": "Told Clara about the canister.",
	"withheld_canister": "Said nothing to Clara about the canister. Not sure why.",
	"reported_buoy": "Told Clara the buoy was warm.",
	"withheld_buoy": "Kept the buoy to myself.",
	"heard_tape_1": "Played the cassette from the buoy: Walt, talking to his wife June, a year after she was lost.",
	"told_clara_june": "Told Clara what Walt said about June.",
	"lied_about_tape": "Lied to Clara about the tape.",
}

## Entry text for a given day, built from what was found that day.
static func compose(day: int) -> String:
	var parts: Array = [Days.get_day(day).barometer.replace("Barometer: ", "Glass ")]
	for id in LINES:
		if GameState.discovered_day.get(id, -1) == day:
			parts.append(LINES[id])
	for f in FLAG_LINES:
		if GameState.flag_day.get(f, -1) == day and GameState.has_flag(f):
			parts.append(FLAG_LINES[f])
	if parts.size() == 1:
		parts.append("Quiet day. Nothing new to record.")
	return " ".join(parts)
