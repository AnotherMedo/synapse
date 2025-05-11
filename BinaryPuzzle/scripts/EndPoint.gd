extends Node2D

const _Input = preload("res://BinaryPuzzle/scripts/Input.gd")
const Output = preload("res://BinaryPuzzle/scripts/Output.gd")

var connected_input: _Input

var val_sprite: ColorRect

var current_val: bool 

func _ready() -> void:
	connected_input = $"LogicGateInput"
	val_sprite = $"ColorRect"
	
	current_val = false
	val_sprite.color = Output.false_color
	
	connected_input.recieve.connect(change_source_val)
	
func change_source_val(message: Output.Message) -> void:
	current_val = message.sent_val
	
	if current_val:
		val_sprite.color = Output.true_color
	else:
		val_sprite.color = Output.false_color
