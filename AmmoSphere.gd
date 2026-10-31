extends Area3D

func pick_up(_socket: Node3D) -> void:
	# Signal/notify player that ammo was collected
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("collect_ammo"):
		player.collect_ammo()
		queue_free()
