extends Node

@onready var credits = $"../Credits"
@onready var options = $"../Options"


func _on_start_button_pressed() -> void:
	print("Should redirect to main scene.")

func _on_options_button_pressed() -> void:
	options.visible = true

func _on_credits_button_pressed() -> void:
	credits.visible = true

func _on_quit_button_pressed() -> void:
	get_tree().quit()
