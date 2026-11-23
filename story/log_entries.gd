class_name LogEntries
## Auto-written logbook lines, one per discoverable clue.

const LINES := {
	"lighthouse": "Climbed the tower. Lens turns smooth on its weights.",
	"cottage": "Stove draws well. Found 1970s oceanography logs on the shelf.",
	"shipwreck": "East stack: old trawler wreck. Canister stamped PROJECT PELAGIC 1974 wedged in the hull.",
	"cable": "North cove: an armored cable runs from a stone hut out under the sea. Brass tag: PELAGIC ARRAY 2.",
	"vault": "South reef at the spring low: a flooded cable vault. A field recorder wedged behind the ladder, initials J.H.",
	"floorboard": "Under the bed, a loose floorboard and a cassette in Walt's handwriting.",
	"locker": "Lantern-room locker: Walt's last tape, left for whoever's next.",
	"tin": "North cove hut: a biscuit tin with a Coast Guard boat log on cassette.",
	"buoy_service": "West buoy: fresh service marks, a Coast Guard-issue battery, and a cassette taped under the hatch.",
	"seacave": "West echo cave: red acoustic buoy in the arch. Battery pack still warm. Shouldn't be.",
}

const FLAG_LINES := {
	"reported_canister": "Told Clara about the canister.",
	"withheld_canister": "Said nothing to Clara about the canister. Not sure why.",
	"reported_buoy": "Told Clara the buoy was warm.",
	"withheld_buoy": "Kept the buoy to myself.",
	"heard_tape_1": "Played the cassette from the buoy: Walt, talking to his wife June, a year after she was lost.",
	"reported_cable": "Told Clara about the cable and its tag.",
	"withheld_cable": "Kept the cable to myself.",
	"reported_vault": "Told Clara about the vault and the recorder.",
	"withheld_vault": "Told Clara there was nothing in the vault.",
	"heard_tape_2": "Played the field recorder from the vault: June, her last recording.",
	"heard_tape_3": "Played Walt's 1977 tape: the Navy's settlement offer, and June's sister, Ruth.",
	"heard_tape_4": "Played Walt's last tape. He wanted the tapes to reach Ruth Whitcomb in Providence.",
	"heard_tape_5": "Played Tom Dunmore's boat log: he said one hour; they said two.",
	"heard_tape_6": "Played Clara's own tape from the buoy.",
	"clara_shared_father": "Clara told me her father worked the Pelagic boats.",
	"told_clara_wife": "Told Clara about Maren.",
	"clara_admitted": "Clara told me everything.",
	"clara_partial": "Clara told me some of it.",
	"clara_stonewalled": "Clara would not talk.",
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
