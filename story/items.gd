class_name Items
## Satchel items: story objects only. No combining, crafting or weight.

const DATA := {
	"canister": {"name": "Pelagic canister", "desc": "Orange waterproof canister stamped PROJECT PELAGIC 1974. Sealed. Heavy for its size."},
	"tape_1": {"name": "Cassette: \"Walt, Jan 1976\"", "desc": "Taped inside the buoy hatch. Pencil label. Plays in the cottage cassette player."},
	"uni_logs": {"name": "University logbooks", "desc": "1970s oceanography logs from the cottage shelf: hydrophone readings, tide corrections, and a name: J. Haskell."},
}

static func title(id: String) -> String:
	return DATA.get(id, {}).get("name", id)

static func desc(id: String) -> String:
	return DATA.get(id, {}).get("desc", "")
