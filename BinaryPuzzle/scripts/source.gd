extends Node

const Output = preload("res://BinaryPuzzle/scripts/Output.gd")

var connected_output: Output

var val_sprite: ColorRect 
var switch_val_button: Button

var current_val: bool 

func _ready() -> void:
	connected_output = $"LogicGateInput"
	val_sprite = $"ColorRect"
	switch_val_button = $"ColorRect/Button"
	
	current_val = false
	val_sprite.color = Output.false_color
	switch_val_button.pressed.connect(switch_source_val)
	
func change_source_val(new_val: bool) -> void:
	current_val = new_val
	
	var message = Output.Message.new()
	message.sent_val = current_val
	message.sender_id = 0
	
	connected_output.send.emit(message)
	if new_val:
		val_sprite.color = Output.true_color
	else:
		val_sprite.color = Output.false_color

func switch_source_val() -> void:
	change_source_val(!current_val)
