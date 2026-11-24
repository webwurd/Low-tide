class_name Endings
## The three endings: names, epilogue text, and the flag-dependent coda.
## (Shared, verbatim, with the Unity port via the fixtures.)

const DATA := {
	"a": {"name": "THE RIGHT ADDRESS", "body": "Ruth Whitcomb answered in eleven days. She asked first for June's recorder, and then, quietly, for the tapes. They were played at her kitchen table in Providence, and later at a small hearing nobody expected anyone to attend. The Navy's schedule for the fourth of November, 1974, was never entered in any record. Now it is. So is the name of the Coast Guard boatswain who said one hour."},
	"b": {"name": "LEFT QUIET", "body": "By dawn the buoy's battery had gone flat, and the ping on the south reef stopped for the first time in twenty-four years. The tapes went back into the lamp-room locker, where Walt had left them for whoever came next. Arthur took the relief boat home to a house he could finally walk through. On sixteen, in the mornings, Clara still says good morning to the rock."},
	"c": {"name": "ON THE RECORD", "body": "The report went to the Coast Guard with Arthur's signature on it: thorough, accurate, and dated the seventh. It reopened nothing for June, and it ended Clara's career at Station Penobscot. She did not answer on sixteen again. The beam turned all that winter for no one, and the relief boat, when it came, found the radio switched off."},
}

static func ending_name(kind: String) -> String:
	return DATA[kind]["name"]

static func body(kind: String) -> String:
	var text: String = DATA[kind]["body"]
	if kind == "a":
		if GameState.has_flag("clara_admitted"):
			text += " Clara's statement sits beside Arthur's. She signed it Dunmore."
		elif GameState.has_flag("clara_partial"):
			text += " Clara never wrote back, but her father's log was in the envelope."
		else:
			text += " Clara's name is nowhere in the file. Neither of you mentions it."
	return text
