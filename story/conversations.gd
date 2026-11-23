class_name Conversations
## Placeholder M2 radio content, lifted from the Milestone 1 prototype.
## Real writing lands in M4/M6 via the dialogue system.

const SPEAKER := "CH-16 // CLARA (COAST GUARD DISPATCH)"

static var _json: Dictionary = {}
static var _loaded := false

const JSON_PATH := "res://dialogue/dialogue.json"
const SPEAKERS := {"clara": SPEAKER, "arthur": "ARTHUR"}

static func reload() -> void:
	_loaded = false
	_json = {}

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(JSON_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(JSON_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_json = parsed
	else:
		push_error("dialogue.json failed to parse")

## Resolve a conversation id to a ready-to-play dictionary. JSON conversations
## are lists of variants; the first whose `when` holds wins. Options are
## filtered by their own `when` and capped at two (the radio UI shows 1 / 2).
static func get_conv(id: String) -> Dictionary:
	_load()
	var convs: Dictionary = _json.get("convs", {})
	if convs.has(id):
		for v in convs[id]:
			if Conditions.check(v.get("when", [])):
				return _normalize(id, v)
		return {}
	if id == "opening":
		id = "morning_d1"
	if DATA.has(id):
		return DATA[id]
	return DAILY.get(id, {})

static func _normalize(id: String, v: Dictionary) -> Dictionary:
	var opts: Array = []
	for o in v.get("options", []):
		if Conditions.check(o.get("when", [])) and opts.size() < 2:
			opts.append(o)
	return {"id": id, "speaker": SPEAKERS.get(v.get("speaker", "clara"), SPEAKER),
		"priority": int(v.get("priority", 2)), "text": v.get("text", ""), "options": opts}

static func reactions() -> Array:
	_load()
	return _json.get("reactions", [])

static func tape(id: String) -> Dictionary:
	_load()
	return _json.get("tapes", {}).get(id, {})

const DATA := {
	"morning_d1": {
		"id": "morning_d1", "speaker": SPEAKER, "priority": 2,
		"text": "Gannet Rock, this is Station Penobscot. Tide's dropping fast. If you want to inspect the outer sea stacks before noon, now's your window.",
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

# --- Daily check-ins and evening calls. PLACEHOLDER TEXT: rewritten in M6. ---
static func _c(id: String, text: String, a: String, ar: String, at := 0, b := "", br := "", bt := 0) -> Dictionary:
	var opts: Array = [{"text": a, "reply": ar, "trust": at}]
	if b != "":
		opts.append({"text": b, "reply": br, "trust": bt})
	return {"id": id, "speaker": SPEAKER, "priority": 2, "text": text, "options": opts}

const DAILY := {
	"dusk_nudge": {"id": "dusk_nudge", "speaker": SPEAKER, "priority": 1, "options": [],
		"text": "Light's going, Arthur. Stay on high ground and get that lamp lit."},
	"forced_home": {"id": "forced_home", "speaker": SPEAKER, "priority": 1, "options": [],
		"text": "Dark and bitter out there. Get in by the stove, Arthur. The rock will keep till morning."},
	"evening_d1": {"id": "evening_d1", "speaker": SPEAKER, "priority": 2,
		"text": "Beam's turning pretty from here. How was your first day on the rock, really?",
		"options": [
			{"text": "Lonelier than I expected. But I like it.", "reply": "That's honest. Most keepers say it takes three days to stop listening for company.", "trust": 1},
			{"text": "Busy. Plenty to log.", "reply": "All business. Fine. Get some sleep, Arthur.", "trust": 0}]},
	"morning_d2": {"id": "morning_d2", "speaker": SPEAKER, "priority": 2,
		"text": "Morning, Arthur. Flat calm and grey out here. Anything strange wash up overnight?",
		"options": [
			{"text": "Quiet night. Lamp held.", "reply": "Good. Keep it that way.", "trust": 0},
			{"text": "That canister's still bothering me.", "reply": "Leave it dry and don't pry at it. I mean that kindly.", "trust": 1}]},
	"evening_d2": {"id": "evening_d2", "speaker": SPEAKER, "priority": 2,
		"text": "You went quiet out in that cave. Everything all right?",
		"options": [
			{"text": "The buoy was warm, Clara. I'm not imagining that.", "reply": "...I know you're not. Let's talk about it tomorrow.", "trust": 1},
			{"text": "Just the echoes getting to me.", "reply": "Mm. Sleep it off.", "trust": -1}]},
	"morning_d3": {"id": "morning_d3", "speaker": SPEAKER, "priority": 2,
		"text": "Fog's down to the waterline. You won't see your own boots. Listen for the bell buoys.",
		"options": [
			{"text": "I'll keep the foghorn on my left.", "reply": "Good. Don't trust the beam in this; trust your ears.", "trust": 0},
			{"text": "Is there a reason you keep warning me?", "reply": "Habit. My father used to say the rock bites the careless.", "trust": 1}]},
	"evening_d3": {"id": "evening_d3", "speaker": SPEAKER, "priority": 2,
		"text": "Found anything in the north cove? The old charts show a cable there.",
		"options": [
			{"text": "A cable, running straight into the sea.", "reply": "Right. Leave that to the people who laid it.", "trust": 1},
			{"text": "Nothing worth reporting.", "reply": "Alright, Arthur.", "trust": -1}]},
	"morning_d4": {"id": "morning_d4", "speaker": SPEAKER, "priority": 2,
		"text": "Gale warning's up. Bars are done for the day. Stay near the stove and keep the lamp trimmed.",
		"options": [
			{"text": "Understood. I'll sit tight.", "reply": "Good. I'll be on the radio all day if you need me.", "trust": 1},
			{"text": "I could still check the tower.", "reply": "On the summit, in daylight, with a rope. Not otherwise.", "trust": 0}]},
	"evening_d4": {"id": "evening_d4", "speaker": SPEAKER, "priority": 2,
		"text": "Long day. Storms make people talk. My father worked the Pelagic boats, you know.",
		"options": [
			{"text": "Tell me about him.", "reply": "Another night. The wind's about to take the line.", "trust": 1},
			{"text": "Pelagic. The canister. You knew.", "reply": "Not tonight, Arthur. Please.", "trust": 0}]},
	"morning_d5": {"id": "morning_d5", "speaker": SPEAKER, "priority": 2,
		"text": "Clear as glass. And the tables say this is the lowest water of the winter. Spring low.",
		"options": [
			{"text": "Then the south reef will be open.", "reply": "For about an hour. Watch the clock like it owes you money.", "trust": 0},
			{"text": "You sound nervous.", "reply": "I sound careful. There's a difference.", "trust": 1}]},
	"evening_d5": {"id": "evening_d5", "speaker": SPEAKER, "priority": 2,
		"text": "You were down on the reef a long time. What did you see?",
		"options": [
			{"text": "A cable vault. And a name: June.", "reply": "...I see.", "trust": 1},
			{"text": "Rocks. Weed. Nothing.", "reply": "Alright.", "trust": -1}]},
	"morning_d6": {"id": "morning_d6", "speaker": SPEAKER, "priority": 2,
		"text": "Cold one. Arthur, I owe you a straight conversation.",
		"options": [
			{"text": "I'm listening.", "reply": "Not over the radio. Tonight.", "trust": 1},
			{"text": "I think I already know.", "reply": "Then you know why I couldn't say.", "trust": 0}]},
	"evening_d6": {"id": "evening_d6", "speaker": SPEAKER, "priority": 2,
		"text": "I kept that buoy alive. I told myself it was duty.",
		"options": [
			{"text": "It was grief, Clara.", "reply": "Yes. It was.", "trust": 1},
			{"text": "You should have told me.", "reply": "I know. I'm sorry.", "trust": 0}]},
	"morning_d7": {"id": "morning_d7", "speaker": SPEAKER, "priority": 2,
		"text": "Last morning of your watch. I wanted to hear your voice before the relief boat.",
		"options": [
			{"text": "Hearing yours, too.", "reply": "Then we're square.", "trust": 1},
			{"text": "Let's finish what we started.", "reply": "Alright. Whatever you decide, I'll abide by it.", "trust": 0}]},
	"evening_d7": {"id": "evening_d7", "speaker": SPEAKER, "priority": 2,
		"text": "Light's on. Whatever you decide about the tapes, I'll be here on sixteen.",
		"options": [
			{"text": "Thank you, Clara.", "reply": "Goodnight, Arthur.", "trust": 1},
			{"text": "Goodnight.", "reply": "Goodnight.", "trust": 0}]},
}
