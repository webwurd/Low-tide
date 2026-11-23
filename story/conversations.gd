class_name Conversations
## Placeholder M2 radio content, lifted from the Milestone 1 prototype.
## Real writing lands in M4/M6 via the dialogue system.

const SPEAKER := "CH-16 // CLARA (COAST GUARD DISPATCH)"

static func get_conv(id: String) -> Dictionary:
	return DATA.get(id, {})

const DATA := {
	"opening": {
		"id": "opening", "speaker": SPEAKER, "priority": 2,
		"text": "Gannet Rock, this is Station Rockland. Tide's dropping fast. If you want to inspect the outer sea stacks before noon, now's your window.",
		"options": [
			{"text": "Copy that, Clara. Heading up to check the lighthouse first.",
			 "reply": "Roger. Give me a shout if anything strange washed up during last night's squall.", "trust": 1},
			{"text": "I see the East and West sandbars emerging now. Going for a walk.",
			 "reply": "Keep an eye on your pocket watch, Arthur. Don't let the Atlantic trap you out there.", "trust": 0},
		],
	},
	"lighthouse": {
		"id": "lighthouse", "speaker": SPEAKER, "priority": 1,
		"text": "I see your beam sweeping clear through the fog bank, Arthur. Clockwork weights holding steady?",
		"options": [
			{"text": "Wound it an hour ago. Lens is turning smooth.",
			 "reply": "Good. Keep an eye on the tide chart. Low water should expose the outer bars right about now.", "trust": 0},
			{"text": "Fog's thick enough to chew, but the lamp cuts right through.",
			 "reply": "That's why they pay you the big bucks. Stay off the sandbars once the tide turns.", "trust": 1},
		],
	},
	"cottage": {
		"id": "cottage", "speaker": SPEAKER, "priority": 1,
		"text": "Sounds warm in there. Did you find the spare kerosene cans in the stone shed?",
		"options": [
			{"text": "Stove's roaring and coffee's on. Plenty of fuel.",
			 "reply": "Jealous. All I've got is burnt machine coffee and static on channel 16.", "trust": 1},
			{"text": "Found some old 1970s oceanography logs on the shelf.",
			 "reply": "Huh... yeah, the university used Gannet Rock before automation. Mostly weather balloons and drift buoys.", "trust": 0},
		],
	},
	"shipwreck": {
		"id": "shipwreck", "speaker": SPEAKER, "priority": 1,
		"text": "Wait, you walked all the way out to the East Stack? What did you find wedged in the hull?",
		"options": [
			{"text": "An orange canister marked 'PROJECT PELAGIC - 1974'.",
			 "reply": "...Keep that dry and bring it back before the sandbar floods. Don't open it out in the salt spray.", "trust": 1},
			{"text": "Just an old trawler wreck, Clara. Looks like it's been here decades.",
			 "reply": "Watch the water level behind you! Once the tide turns, that sandbar disappears in minutes.", "trust": -1},
		],
	},
	"seacave": {
		"id": "seacave", "speaker": SPEAKER, "priority": 1,
		"text": "Echo Cave? Your signal's bouncing off the walls. What's sitting in the arch?",
		"options": [
			{"text": "A rusted acoustic buoy. Its battery pack is still warm.",
			 "reply": "Warm? Nobody's serviced offshore buoys out there since the station closed. Head back to high ground, Arthur.", "trust": 1},
			{"text": "Just tangled kelp and barnacles. Acoustics are eerie in here.",
			 "reply": "Don't linger. Check your pocket watch. The Atlantic doesn't wait for sightseers.", "trust": -1},
		],
	},
	"sandbar_warning": {
		"id": "sandbar_warning", "speaker": SPEAKER, "priority": 0,
		"text": "Careful crossing that sandbar, Arthur. Keep one eye on your pocket watch so you make it back before high tide.",
		"options": [],
	},
	"swept": {
		"id": "swept", "speaker": SPEAKER, "priority": 2,
		"text": "Arthur! My tide monitor spiked. Did you just get cut off on the sandbar?",
		"options": [
			{"text": "Misjudged the swell. Back on the dock, just soaked boots.",
			 "reply": "Watch that pocket watch! Once the water tops two meters those bars are no place to be.", "trust": 0},
			{"text": "I'm fine, Clara. Water came in faster than the chart predicted.",
			 "reply": "Tides don't mess around out there. Wait for falling water before crossing again.", "trust": 0},
		],
	},
}
