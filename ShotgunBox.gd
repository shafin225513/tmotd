extends RigidBody3D

var carry_socket: Node3D = null
var is_being_carried: bool = false

func pick_up(socket: Node3D) -> void:
	carry_socket = socket
	is_being_carried = true
	freeze = true
	
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true

	# Reparent to carry socket
	if get_parent():
		get_parent().remove_child(self)
	socket.add_child(self)
	transform = Transform3D.IDENTITY

func drop() -> void:
	is_being_carried = false
	freeze = false
	
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = false

	# Reparent back to world root (or scene tree)
	var world = get_tree().current_scene
	if get_parent():
		get_parent().remove_child(self)
	world.add_child(self)
	global_position = carry_socket.global_position
	carry_socket = null
