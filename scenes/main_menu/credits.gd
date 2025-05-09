extends Control

func _process(delta: float) -> void:
	# If escape is pressed we quit the menu
	if Input.is_action_pressed("escape"):
		visible = false


func _on_button_pressed() -> void:
	visible = false
