extends CharacterBody3D

@export var speed: float = 5.0
@export var mouse_sensitivity: float = 0.003

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Flashlight
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var carry_socket: Node3D = $Head/Camera3D/CarrySocket
@onready var crosshair_ui = $CanvasLayer/CrosshairUI # Adjust path if needed

var held_object: Node3D = null

# Shotgun State
var has_ammo: bool = false
var has_powder: bool = false
var is_shotgun_equipped: bool = false

var total_rounds: int = 14
var current_clip: int = 0 # 2 shots max per load
var is_reloading: bool = false
var reload_timer: float = 0.0

var hud: CanvasLayer = null

func _ready() -> void:
	add_to_group("Player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if camera:
		camera.make_current()
	
	hud = get_tree().get_first_node_in_group("HUD")
	update_hud()

func _unhandled_input(event: InputEvent) -> void:
	# Click inside window to lock cursor & shoot
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if is_shotgun_equipped:
			shoot_shotgun()

	# First-Person Camera Look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		if head:
			head.rotate_x(-event.relative.y * mouse_sensitivity)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))

	# Flashlight Toggle ('T') - ONLY triggers on KEY DOWN
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_T:
		if flashlight:
			flashlight.visible = !flashlight.visible

	# Pick Up / Drop Toggle ('E') - ONLY triggers on KEY DOWN
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_E:
		toggle_pickup()

	# Unlock Cursor ('ESC')
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func toggle_pickup() -> void:
	print("--- E KEY PRESSED ---")
	
	# 1. DROP CURRENTLY HELD ITEM
	if held_object:
		print("Dropping item: ", held_object.name)
		if is_instance_valid(held_object) and held_object.has_method("drop"):
			held_object.drop()
		held_object = null
		is_shotgun_equipped = false
		update_hud()
		return

	# 2. PERFORM DIRECT PHYSICS RAYCAST FROM CAMERA
	var space_state = get_world_3d().direct_space_state
	var ray_origin = camera.global_position
	var ray_end = ray_origin - camera.global_transform.basis.z * 5.0 # 5 meters forward

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [get_rid()] # Don't hit player body
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)

	if not result:
		print("Raycast did NOT collide with anything within 5 meters.")
		return

	var collider = result.collider
	if not collider:
		return

	# Ignore level geometry (CSG Nodes / Static Environment)
	if collider is CSGShape3D or collider.get_parent() is CSGShape3D or collider.is_in_group("Environment"):
		print("Raycast hit environment geometry: ", collider.name)
		return

	print("Raycast HIT: ", collider.name, " (Type: ", collider.get_class(), ")")

	# Check for Shotgun
	var is_shotgun = collider.has_method("can_equip_shotgun") or collider.is_in_group("Shotgun") or "Shotgun" in collider.name
	if is_shotgun:
		if not can_equip_shotgun():
			print("Cannot pick up Shotgun! Need both Ammo and Powder first.")
			return
		equip_shotgun(collider, carry_socket)
		return

	# Check for Pickable Items (on collider or its parent)
	var pickable = collider
	if not pickable.has_method("pick_up") and pickable.get_parent() and pickable.get_parent().has_method("pick_up"):
		pickable = pickable.get_parent()

	if pickable.has_method("pick_up"):
		print("SUCCESS: Picking up ", pickable.name)
		if not (pickable is Area3D):
			held_object = pickable
		pickable.pick_up(carry_socket)
	else:
		print("WARNING: Hit ", collider.name, " but it has no pick_up() method.")

	# 2. INTERACT WITH

func collect_ammo() -> void:
	has_ammo = true
	held_object = null # Ensures hand state is cleared
	update_hud()

func collect_powder() -> void:
	has_powder = true
	held_object = null # Ensures hand state is cleared
	update_hud()

func can_equip_shotgun() -> bool:
	return has_ammo and has_powder

func equip_shotgun(shotgun_node: Node3D, socket: Node3D) -> void:
	held_object = shotgun_node
	is_shotgun_equipped = true
	
	if shotgun_node.has_method("pick_up"):
		shotgun_node.pick_up(socket)

	if current_clip == 0 and total_rounds > 0 and not is_reloading:
		start_reload()
	else:
		update_hud()

func shoot_shotgun() -> void:
	if is_reloading or current_clip <= 0:
		return

	current_clip -= 1
	print("SHOTGUN FIRED! 7 Pellets launched.")

	# Raycast 7 Spread Pellets
	var space_state = get_world_3d().direct_space_state
	for i in range(7):
		var spread := Vector3(
			randf_range(-0.08, 0.08),
			randf_range(-0.08, 0.08),
			-1.0
		).normalized()

		var target_dir = camera.global_transform.basis * spread
		var query = PhysicsRayQueryParameters3D.create(
			camera.global_position,
			camera.global_position + target_dir * 20.0
		)
		query.exclude = [get_rid()]

		var result = space_state.intersect_ray(query)
		if result:
			print("Pellet ", i + 1, " hit: ", result.collider.name)

	if current_clip == 0 and total_rounds > 0:
		start_reload()
	else:
		update_hud()

func start_reload() -> void:
	is_reloading = true
	reload_timer = 10.0
	update_hud()

func _physics_process(delta: float) -> void:
	# Reload Timer Logic
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			reload_timer = 0.0
			is_reloading = false
			current_clip = min(2, total_rounds)
		update_hud()
		update_crosshair_target()

	# Movement
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S): input_dir.y += 1
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	input_dir = input_dir.normalized()

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func update_hud() -> void:
	if not hud:
		hud = get_tree().get_first_node_in_group("HUD")
	if not hud:
		return

	if not is_shotgun_equipped:
		var status = "Shotgun: Missing Items ("
		status += "Ammo: OK " if has_ammo else "Ammo: NEED "
		status += "| Powder: OK)" if has_powder else "| Powder: NEED)"
		hud.update_status(status)
	elif is_reloading:
		hud.update_status("Reloading... %.1fs" % reload_timer)
	else:
		hud.update_status("Shotgun Ammo: %d | Reserve: %d" % [current_clip, total_rounds])
func update_crosshair_target() -> void:
	if not crosshair_ui or not camera:
		return

	# Perform 4-meter aim check straight out of camera
	var space_state = get_world_3d().direct_space_state
	var ray_origin = camera.global_position
	var ray_end = ray_origin - camera.global_transform.basis.z * 4.0 # 4 meters reach

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)

	var found_interactable := false

	if result and result.collider:
		var collider = result.collider
		
		# Ignore raw level geometry CSG nodes
		if not (collider is CSGShape3D or collider.get_parent() is CSGShape3D or collider.is_in_group("Environment")):
			# Check if object can be picked up, equipped, or targeted
			if collider.has_method("pick_up") or collider.get_parent().has_method("pick_up") or collider.is_in_group("Interactable"):
				found_interactable = true

	# Update crosshair color (White = regular, Green = interactable in range)
	crosshair_ui.set_highlight(found_interactable)
