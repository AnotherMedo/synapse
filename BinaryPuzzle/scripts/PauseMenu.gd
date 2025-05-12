extends Node

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # 'ui_cancel' is Escape by default
		toggle_pause()

func toggle_pause():
	self.visible = not self.visible

func _ready():
	var resume_button : Button = $"Buttons/VBoxContainer/ResumeButton"
	var pause_button: Button = $"Buttons/VBoxContainer/MenuButton"
	
	resume_button.pressed.connect(toggle_pause)
	pause_button.pressed.connect(load_puzzle_selection_menu)
	
func load_puzzle_selection_menu():
	var target_scene = load("res://scenes/puzzles/puzzle_tree.tscn").instantiate()
	
	get_tree().root.add_child(target_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = target_scene
