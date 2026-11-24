class_name Prologue
## The opening: Arthur's year before Gannet Rock, told in short typed
## fragments with choices, intercut with the crossing by Coast Guard tender.
## FIRST DRAFT (M6.5): placeholder writing in the game's voice, to be
## rewritten with the rest of the story in M6. Choices set backstory flags
## (GameState.flags) and nudge Trust: an Arthur who lets people in starts a
## little warmer with Clara.
##
## Beat kinds:
##   {"text": [lines], "choices": [{"text", "flag", "trust"}]}   typed card
##   {"shot": index, "caption": "...", "seconds": n}             crossing shot
##   {"radio": "speaker", "line": "..."}                         radio over the last shot

static func beats() -> Array:
	return [
		{"shot": 0, "caption": "Penobscot Bay  ·  December 1998  ·  06:40", "seconds": 7.0},
		{"text": [
			"For twenty-six years you taught earth science in a brick school in Bangor.",
			"You could make a room of fifteen-year-olds understand a tide: the moon leaning, the water answering, twice a day, for as long as there has been water.",
			"Ellen came to the last class every June and sat at the back, grading her own stack of papers.",
		], "choices": [
			{"text": "She taught fourth grade, down the hall.", "flag": "ellen_teacher", "trust": 0},
			{"text": "She ran the secondhand bookshop on Exchange Street.", "flag": "ellen_bookshop", "trust": 0},
		]},
		{"shot": 1, "caption": "", "seconds": 6.0},
		{"text": [
			"The diagnosis came in March. You learned its vocabulary the way you would learn a new coastline: slowly, then all at once.",
			"By August the house had gone very quiet.",
		], "choices": [
			{"text": "You left everything exactly where she put it.", "flag": "arthur_kept_house", "trust": 0},
			{"text": "You boxed it all up in a single weekend and couldn't say why.", "flag": "arthur_boxed_house", "trust": 0},
		]},
		{"text": [
			"Your sister called every Sunday. She said you needed people around you.",
			"You told her you needed something to do with your hands.",
		], "choices": [
			{"text": "In the end, you told her where you were going.", "flag": "told_sister", "trust": 1},
			{"text": "You didn't tell anyone.", "flag": "told_nobody", "trust": -1},
		]},
		{"shot": 2, "caption": "", "seconds": 6.0},
		{"text": [
			"The Coast Guard would automate the light on Gannet Rock in the spring. Until then it needed one more winter of a person: someone to wind the clockwork, light the lamp, and keep the log.",
			"The notice asked for reliability, a tolerance for solitude, and no family obligations.",
			"You read the last part twice.",
		], "choices": [
			{"text": "You wrote the letter in pencil first, then in ink.", "flag": "arthur_careful", "trust": 0},
			{"text": "You called the number before you could change your mind.", "flag": "arthur_impulsive", "trust": 0},
		]},
		{"shot": 3, "caption": "Gannet Rock Light  ·  est. 1884", "seconds": 9.0},
		{"radio": "Channel 16, Coast Guard dispatch", "line": "Morning, Gannet Rock. This is Clara. Glad you made it across. You'll be hearing a lot of me this week, so I hope you like talking."},
	]

## The tender's track through the fog for each shot: [from, to, look_ahead].
static func shot_path(index: int) -> Array:
	match index:
		0: return [Vector3(-40, 0, 300), Vector3(-30, 0, 240), Vector3(-10, 4, 0)]
		1: return [Vector3(-26, 0, 200), Vector3(-18, 0, 160), Vector3(-6, 6, 0)]
		2: return [Vector3(-14, 0, 130), Vector3(-8, 0, 95), Vector3(-2, 9, -4)]
		_: return [Vector3(-6, 0, 82), Vector3(-1, 0, 48), Vector3(0, 15, -6)]
