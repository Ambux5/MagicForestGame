extends Node3D
## Bridges the imported .glb model's AnimationPlayer to the player controller.
## Adjust model_scale / model_offset / model_rotation in the Inspector
## if the model is the wrong size, position, or faces the wrong direction.

@export var model_scale:    Vector3 = Vector3(1.0, 1.0, 1.0)
@export var model_offset:   Vector3 = Vector3.ZERO
@export var model_rotation: Vector3 = Vector3.ZERO   # degrees


func _ready() -> void:
	call_deferred("_setup_model")


func _setup_model() -> void:
	# Apply transform overrides to the glb child
	for child in get_children():
		if child is Node3D:
			child.scale            = model_scale
			child.position         = model_offset
			child.rotation_degrees = model_rotation

	# Find the AnimationPlayer anywhere in the model hierarchy and register it
	var ap := _find_anim_player(self)
	if ap == null:
		return

	var player_node := get_parent().get_parent()   # ModelRoot → MeshRoot → Player
	if player_node and player_node.has_method("set_wizard_animation_player"):
		player_node.set_wizard_animation_player(ap)


# Recursively searches the subtree for the first AnimationPlayer
func _find_anim_player(node: Node) -> AnimationPlayer:
	for child in node.get_children():
		if child is AnimationPlayer:
			return child as AnimationPlayer
		var found := _find_anim_player(child)
		if found:
			return found
	return null
