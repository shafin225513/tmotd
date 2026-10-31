extends Area3D

func pick_up(_socket: Node3D) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("collect_powder"):
		player.collect_powder()
		queue_free()
