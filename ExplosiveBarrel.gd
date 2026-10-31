extends RigidBody3D

var carry_socket: Node3D = null
var is_being_carried: bool = false

func _physics_process(delta: float) -> void:
	if is_being_carried and carry_socket:
		# Smoothly interpolate position and rotation to match the player's CarrySocket
		global_transform = global_transform.interpolate_with(
			carry_socket.global_transform,
			delta * 20.0
		)

func pick_up(socket: Node3D) -> void:
	carry_socket = socket
	is_being_carried = true
	
	# Disable physics forces while holding
	freeze = true
	
	# Prevent barrel collision from pushing player physics
	$CollisionShape3D.disabled = true

func drop() -> void:
	is_being_carried = false
	carry_socket = null
	
	# Re-enable physics and gravity
	freeze = false
	$CollisionShape3D.disabled = false
	
	# Inherit a small forward push on drop
	linear_velocity = Vector3.ZERO
