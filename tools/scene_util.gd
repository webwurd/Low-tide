class_name SceneUtil
## Helpers for the asset factory: save meshes as .res, build node trees and
## pack them into .tscn scenes that open normally in the editor.

const MODELS := "res://assets/models/"

static func save_mesh(mesh: Mesh, name: String) -> Mesh:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MODELS))
	var p := MODELS + name + ".res"
	ResourceSaver.save(mesh, p, ResourceSaver.FLAG_COMPRESS)
	mesh.take_over_path(p)
	return mesh

## Commits a MeshKit, saves it and reports its size.
static func kit_mesh(kit: MeshKit, name: String, lods := true) -> Mesh:
	var tris := kit.tri_count()
	var m := save_mesh(kit.commit(lods), name)
	print("    model %-22s %6d tris" % [name, tris])
	return m

static func mesh_node(parent: Node, mesh: Mesh, node_name: String, xf := Transform3D.IDENTITY,
		shadows := true, prop := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.transform = xf
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if prop != "":
		mi.set_meta("prop", prop)
	parent.add_child(mi)
	return mi

static func body(parent: Node, node_name: String, shapes: Array, xf := Transform3D.IDENTITY) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.name = node_name
	b.transform = xf
	parent.add_child(b)
	var k := 0
	for s in shapes:
		var cs := CollisionShape3D.new()
		cs.name = "Shape%d" % k
		cs.shape = s[0]
		cs.transform = s[1]
		b.add_child(cs)
		k += 1
	return b

static func box_shape(size: Vector3) -> BoxShape3D:
	var s := BoxShape3D.new(); s.size = size; return s

static func interactable(parent: Node, node_name: String, id: String, title: String, pos: Vector3,
		radius: float, conv := "", hold := 0.0) -> Interactable:
	var it := Interactable.new()
	it.name = node_name
	it.id = id; it.title = title; it.radius = radius; it.conversation = conv; it.hold_time = hold
	it.position = pos
	parent.add_child(it)
	return it

static func marker(parent: Node, node_name: String, pos: Vector3) -> Marker3D:
	var m := Marker3D.new()
	m.name = node_name
	m.position = pos
	parent.add_child(m)
	return m

static func save_scene(root: Node, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	_own(root, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		push_error("pack failed " + path)
	ResourceSaver.save(ps, path)
	print("    scene ", path)
	root.free()

static func _own(n: Node, owner: Node) -> void:
	for c in n.get_children():
		c.owner = owner
		_own(c, owner)
