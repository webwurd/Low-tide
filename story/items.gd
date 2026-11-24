class_name Items
## Satchel items: story objects only. No combining, crafting or weight.

const DATA := {
	"canister": {"name": "Pelagic canister", "desc": "Orange waterproof canister stamped PROJECT PELAGIC 1974. Sealed. Heavy for its size."},
	"tape_1": {"name": "Cassette: \"Walt, Jan 1976\"", "desc": "Taped inside the buoy hatch. Pencil label. Plays in the cottage cassette player."},
	"cable_tag": {"name": "Brass cable tag", "desc": "From the north cove cable hut. Stamped PELAGIC / ARRAY 2 / USN / DO NOT DISTURB. Salt-green."},
	"tape_2": {"name": "Cassette: \"J.H., Nov 1974\"", "desc": "Cassette from a field recorder wedged behind the vault ladder. Plays in the cottage cassette player."},
	"tape_3": {"name": "Cassette: \"Walt, Oct 1977\"", "desc": "Found under a loose floorboard beneath the cottage bed. Label in Walt's hand."},
	"tape_4": {"name": "Cassette: \"Walt, last\"", "desc": "Kept in the lantern-room locker. The label just says: For whoever's next."},
	"tape_5": {"name": "Cassette: \"T. Dunmore, boat log\"", "desc": "From a biscuit tin in the north cove hut. A Coast Guard boatswain's dictated log."},
	"tape_6": {"name": "Cassette: \"C.D., Oct 1997\"", "desc": "Taped under the west buoy's service hatch, beside a fresh Coast Guard-issue battery."},
	"uni_logs": {"name": "University logbooks", "desc": "1970s oceanography logs from the cottage shelf: hydrophone readings, tide corrections, and a name: J. Haskell."},
}

static func title(id: String) -> String:
	return DATA.get(id, {}).get("name", id)

static func desc(id: String) -> String:
	return DATA.get(id, {}).get("desc", "")
