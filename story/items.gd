class_name Items
## Satchel items: story objects only. No combining, crafting or weight.

const DATA := {
	"canister": {"name": "Pelagic canister", "desc": "Orange waterproof canister stamped PROJECT PELAGIC 1974. Sealed. Heavy for its size."},
	"tape_1": {"name": "Cassette: \"Walt, Jan 1976\"", "desc": "Taped inside the buoy hatch. Pencil label. Plays in the cottage cassette player."},
	"cable_tag": {"name": "Brass cable tag", "desc": "From the north cove cable hut. Stamped PELAGIC / ARRAY 2 / USN / DO NOT DISTURB. Salt-green."},
	"tape_2": {"name": "Cassette: \"J.H., Nov 1974\"", "desc": "Cassette from a field recorder wedged behind the vault ladder. Plays in the cottage cassette player."},
	"uni_logs": {"name": "University logbooks", "desc": "1970s oceanography logs from the cottage shelf: hydrophone readings, tide corrections, and a name: J. Haskell."},
}

static func title(id: String) -> String:
	return DATA.get(id, {}).get("name", id)

static func desc(id: String) -> String:
	return DATA.get(id, {}).get("desc", "")
