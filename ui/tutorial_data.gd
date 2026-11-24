class_name TutorialData
## Controls tutorial pages, shared by the New Watch setup and the pause menu.

static func pages() -> Array:
	return [
		{"title": "1 / 3   Moving about", "rows": [
			["ACTION", "KEYBOARD + MOUSE", "GAMEPAD"],
			["Walk", "W A S D", "Left stick"],
			["Look", "Mouse", "Right stick"],
			["Brisk walk (uses stamina)", "Hold Shift", "Press L3"],
			["Inspect / use", "E  (hold for winding & lighting)", "A  (hold)"],
			["Release the mouse / pause", "Esc", "Start"],
		], "text": ""},
		{"title": "2 / 3   Your tools", "rows": [
			["ACTION", "KEYBOARD + MOUSE", "GAMEPAD"],
			["Pocket watch (hold)", "Q", "Left bumper"],
			["Binoculars (hold)", "Right mouse  or  B", "Left trigger"],
			["Radio: answer 1 / 2", "1  /  2", "D-pad left / right"],
			["Radio: dismiss", "X", "B"],
			["Journal: log, satchel, tapes", "Tab  (A / D turn pages)", "View / Back"],
			["Assist readout (clock + tide)", "F1", "Y"],
		], "text": ""},
		{"title": "3 / 3   A day on Gannet Rock", "rows": [], "text":
			"MORNING   Brew the coffee, read the barometer and the tide table, wind the clockwork weights in the lighthouse, then check in with Clara on the radio. Time stands still while you are indoors.\n\n" +
			"EXPEDITION   Step outside and the clock runs: one game minute per second. Sandbars appear at low water and drown above two metres. Watch the pocket watch and the painted tide marks on the pier pilings. If the sea catches you, you lose time, not the game.\n\n" +
			"IN FOG   Bell buoys ring around the island: 1 strike is north, 2 east, 3 south, 4 west. Walk toward the sound and keep the beam behind you.\n\n" +
			"EVENING   Light the lamp in the lantern room, write the log at the cottage desk, call Clara, and turn in. Sitting in the armchair or on the lantern bench lets you wait for the tide."},
	]
