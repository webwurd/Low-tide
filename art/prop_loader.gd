class_name PropLoader
## Hybrid art hook. Every generated model in a scene is a MeshInstance3D
## tagged with meta "prop" = its asset name. If an artist drops
## res://assets/models/<name>.glb into the project, that model replaces the
## generated one at load time (same transform), with no code or scene edits.

const MODELS := "res://assets/models/"

static func apply_overrides(root: Node) -> void:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D and n.has_meta("prop"):
			var glb: String = MODELS + str(n.get_meta("prop")) + ".glb"
			if ResourceLoader.exists(glb):
				var scene: PackedScene = load(glb)
				var inst := scene.instantiate() as Node3D
				inst.name = n.name + "_art"
				inst.transform = (n as Node3D).transform
				n.get_parent().add_child(inst)
				(n as MeshInstance3D).visible = false
