extends RichTextLabel

var initial_text

func _ready() -> void:
	initial_text = text


func _on_mouse_entered() -> void:
	text = "[main_menu_title]" + initial_text + "[/main_menu_title]" 


func _on_mouse_exited() -> void:
	text = initial_text
