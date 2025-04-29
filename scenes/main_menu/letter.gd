extends RichTextLabel

var move_range: int = 75
var rot_base_angle: float = 0.03
var rot_angle_range = [0.8, 1.2]
var move_time: float = 1
var rot_base_time: float = 0.8
var rot_time_range = [0.8, 1.2]
var delay: int = 0
@onready var control = $".."


# Base stolen from: https://stackoverflow.com/questions/76855479/move-object-with-tween-back-and-forth-with-godot-4
func add_movement_tween():
	# Calculating the difference between the control node and the current node
	var offset = position.y - control.position.y
	# Using offset to correct difference between the control node and the current node
	var start_y = position.y - offset
	var end_y = position.y + move_range - offset
	# Up and down text movemement
	var mov_tween := create_tween().set_loops()
	mov_tween.tween_property(control, "position:y", end_y, move_time)\
		.from(start_y)\
		.set_trans(Tween.TRANS_CIRC)\
		.set_ease(Tween.EASE_IN)
	mov_tween.tween_property(control, "position:y", start_y, move_time)\
		.from(end_y)\
		.set_trans(Tween.TRANS_CIRC)\
		.set_ease(Tween.EASE_OUT)

func add_rotation_tween():
	# Adding randomness to the angle and time of the rotation
	var rot_rand_time = randf_range(rot_time_range[0], rot_time_range[1]) * rot_base_time
	var rot_rand_angle = randf_range(rot_angle_range[0], rot_angle_range[1]) * rot_base_angle
	# Back and forth rotation
	var rot_tween = create_tween().set_loops()
	rot_tween.tween_property(control, "rotation", rot_rand_angle * TAU, rot_rand_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	rot_tween.tween_property(control, "rotation", -rot_rand_angle * TAU, rot_rand_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

# The tween only start after a short delay.
# This allows to unsync them easily.
func _on_delay_timeout() -> void:
	add_movement_tween()
	add_rotation_tween()
