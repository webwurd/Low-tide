extends SceneTree
## Renders every procedurally generated sound to a WAV for listening.
##   godot --headless -s tools/export_audio.gd -- [out_dir]     (default: res://audio/preview)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var out := ProjectSettings.globalize_path("res://audio/preview")
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	var catalog: Dictionary = root.get_node("AudioDirector").catalog()
	var names := catalog.keys()
	names.sort()
	for nm in names:
		var stream: AudioStreamWAV = catalog[nm]
		var err := stream.save_to_wav("%s/%s.wav" % [out, nm])
		var secs := float(stream.data.size() / 2) / stream.mix_rate
		print("%-22s %5.2fs  %s%s" % [nm, secs, "loop " if stream.loop_mode == AudioStreamWAV.LOOP_FORWARD else "     ", "OK" if err == OK else "ERR %d" % err])
	print("wrote %d files to %s" % [names.size(), out])
	quit(0)
