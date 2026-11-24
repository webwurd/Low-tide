class_name Conditions
## Tiny condition language used by dialogue and reactive lines.
## Every entry in a `when` array must hold (AND). Prefix "!" negates.
##   flag:name        has:item          found:landmark_id
##   zone:a,b         loc:cottage       phase:morning|expedition|evening
##   tide:rising|falling
##   trust>=2   day==3   time>=900   tide>=1.5   (ops: >= <= == > <)

const OPS := [">=", "<=", "==", ">", "<"]

static func check(conds: Array) -> bool:
	for c in conds:
		if not _one(String(c)):
			return false
	return true

static func _one(c: String) -> bool:
	c = c.strip_edges()
	if c.begins_with("!"):
		return not _one(c.substr(1))
	for op in OPS:
		var i := c.find(op)
		if i > 0:
			return _cmp(_num(c.left(i)), op, float(c.substr(i + op.length())))
	var colon := c.find(":")
	if colon < 0:
		push_warning("Bad condition: " + c)
		return false
	var kind := c.left(colon)
	var arg := c.substr(colon + 1)
	match kind:
		"flag": return GameState.has_flag(arg)
		"has": return GameState.has_item(arg)
		"found": return GameState.discovered.has(arg)
		"zone": return arg.split(",").has(GameState.zone)
		"loc": return arg.split(",").has(GameState.location)
		"phase": return ["morning", "expedition", "evening"][DayDirector.phase] == arg
		"tide":
			var now: float = TideSystem.current_height
			var later: float = TideSystem.water_height_abs(GameClock.abs_minute() + 5.0)
			return (later > now) == (arg == "rising")
	push_warning("Unknown condition kind: " + c)
	return false

static func _num(key: String) -> float:
	match key.strip_edges():
		"trust": return float(GameState.trust)
		"day": return float(GameClock.day)
		"time": return GameClock.minute_of_day
		"tide": return TideSystem.current_height
	push_warning("Unknown numeric key: " + key)
	return 0.0

static func _cmp(a: float, op: String, b: float) -> bool:
	match op:
		">=": return a >= b
		"<=": return a <= b
		"==": return is_equal_approx(a, b)
		">": return a > b
		_: return a < b
