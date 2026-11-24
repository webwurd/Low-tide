class_name TutorialData
## Controls tutorial pages, shared by the New Watch setup and the pause menu.

static func pages() -> Array:
	return [
		{"title": "1 / 3   Moving about", "rows": [
			["Action", "Keyboard and mouse", "Gamepad"],
			["Walk", "W A S D", "Left stick"],
			["Look", "Mouse", "Right stick"],
			["Brisk walk (uses stamina)", "Hold Shift", "Press L3"],
			["Inspect / use", "E  (hold for winding & lighting)", "A  (hold)"],
			["Release the mouse / pause", "Esc", "Start"],
		], "text": ""},
		{"title": "2 / 3   Your tools", "rows": [
			["Action", "Keyboard and mouse", "Gamepad"],
			["Pocket watch (hold)", "Q", "Left bumper"],
			["Binoculars (hold)", "Right mouse  or  B", "Left trigger"],
			["Radio: answer 1 / 2", "1  /  2", "D-pad left / right"],
			["Radio: dismiss", "X", "B"],
			["Journal: log, satchel, tapes", "Tab  (A / D turn pages)", "View / Back"],
			["Assist readout (clock + tide)", "F1", "Y"],
		], "text": ""},
		{"title": "3 / 3   A day on Gannet Rock", "rows": [], "text":
			"Morning. Brew the coffee, read the barometer and the tide table, wind the clockwork weights in the lighthouse, then check in with Clara on the radio. Time stands still while you are indoors.\n\n" +
			"Expedition. Step outside and the clock runs: one game minute per second. Sandbars appear at low water and drown above two metres. Watch the pocket watch and the painted tide marks on the pier pilings. If the sea catches you, you lose time, not the game.\n\n" +
			"In fog. Bell buoys ring around the island: 1 strike is north, 2 east, 3 south, 4 west. Walk toward the sound and keep the beam behind you.\n\n" +
			"Evening. Light the lamp in the lantern room, write the log at the cottage desk, call Clara, and turn in. Sitting in the armchair or on the lantern bench lets you wait for the tide."},
	]

## The same pages for one input device ("kb" or "pad"): the unused column is dropped,
## so a player only sees the controls they use.
static func pages_for(device: String) -> Array:
	var col := 2 if device == "pad" else 1
	var out: Array = []
	for pg in pages():
		var rows: Array = []
		for r in pg["rows"]:
			rows.append([r[0], r[col]])
		out.append({"title": pg["title"], "rows": rows, "text": pg["text"]})
	return out
