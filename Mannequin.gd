extends CharacterBody3D

@export var speed: float = 3.5
@export var player_path: NodePath = "../Player"

@onready var notifier: VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D
@onready var touch_area: Area3D = $TouchArea

var player: CharacterBody3D

func _ready() -> void:
	if player_path:
		player = get_node_or_null(player_path)
		
	if touch_area:
		touch_area.body_entered.connect(_on_touch_area_body_entered)

func _physics_process(delta: float) -> void:
	if not player:
		return

	# Grounding gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = -0.1

	var target_pos := Vector3(player.global_position.x, global_position.y, player.global_position.z)

	if is_observed_by_player():
		# Freeze completely ONLY when flashlight is ON and player is directly looking at it
		velocity.x = 0
		velocity.z = 0
	else:
		# In ALL other cases (Light Off OR Looking Away with Light On), move directly into player
		var direction := (target_pos - global_position).normalized()
		
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		# Smooth turn toward player
		var target_angle := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, delta * 10.0)

	move_and_slide()

func is_observed_by_player() -> bool:
	# Must be on screen
	if not notifier or not notifier.is_on_screen():
		return false

	# Flashlight must be ON
	if not player or not player.has_node("Head/Flashlight"):
		return false
		
	var flashlight = player.get_node("Head/Flashlight")
	if not flashlight or not flashlight.visible:
		return false

	# Line of sight check
	var space_state := get_world_3d().direct_space_state
	var player_head_pos = player.get_node("Head").global_position if player.has_node("Head") else player.global_position
	
	var query := PhysicsRayQueryParameters3D.create(
		player_head_pos,
		global_position + Vector3(0, 0.5, 0)
	)
	query.exclude = [player.get_rid(), get_rid()]

	var result := space_state.intersect_ray(query)

	if result.is_empty() or result.collider == self:
		return true

	return false

func _on_touch_area_body_entered(body: Node3D) -> void:
	if body == player:
		print("GAME OVER - Mannequin caught you!")
