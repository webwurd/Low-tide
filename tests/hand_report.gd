extends SceneTree
## Dev tool: prints per-pose metrics (penetration into the palm, fingertip
## positions, pinch gap) while tuning anim/poses/*.tres, then the hand checks.
##   godot --headless -s tests/hand_report.gd
var checks := 0
var failures := 0
func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
	print(("  ok:   " if cond else "  FAIL: ") + msg)
func _initialize() -> void:
	_go.call_deferred()
func _go() -> void:
	var r := HandRig.new(1.0)
	root.add_child(r)
	HandTests.report(r)
	r.free()
	HandTests.run(self)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
