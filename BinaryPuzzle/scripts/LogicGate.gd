extends Node2D

enum Logic {NOT, AND, OR}

const Input_ = preload("res://BinaryPuzzle/scripts/Input.gd")
const Output = preload("res://BinaryPuzzle/scripts/Output.gd")

const invalid_position_color: Color = Color(.75,0,0,1)
const valid_position_color: Color = Color(0,.75,0,1)
const no_modular_color: Color = Color(1,1,1,1)

var sprites: Array[Sprite2D]

var overlappingBodies: int = 0
var area2d: Area2D

var inputs: Array[Input_]
var outputs: Array[Output]

@export var chosen_logic: Logic

var chosen_logic_callable: Callable

func _ready() -> void:
	area2d = $"ColliderArea";
	sprites = get_sprite_children()
	
	set_modular_color_on_sprites(valid_position_color)
	
	start_detecting_placeability()
	
	get_inputs_outputs()
	
	match chosen_logic:
		Logic.NOT:
			chosen_logic_callable = not_logic
		Logic.AND:
			chosen_logic_callable = and_logic
		Logic.OR:
			chosen_logic_callable = or_logic
	
func get_sprite_children() -> Array[Sprite2D]:
	var sprites: Array[Sprite2D] = []
	for child in get_children():
		if child is Sprite2D:
			sprites.append(child)
	return sprites

func set_modular_color_on_sprites(color: Color) -> void:
	for sprite in sprites:
		sprite.modulate = color

#-----------------------------------------------placeability

func is_placeable() -> bool:
	return overlappingBodies == 0

"""
Now checks if the logic gate has space or not to be placed
"""
func start_detecting_placeability() -> void:
	if (!area2d):
		push_error("missing area2d for logic gate")
		return
		
	area2d.area_entered.connect(on_collision_enter)
	area2d.area_exited.connect(on_collision_exit)
	
"""
Puts the logic gate down, so no more checking if it's placeable
and it's back to it's basic color
"""
func place_down() -> void:
	stop_detecting_placeability()
	set_modular_color_on_sprites(no_modular_color)
	
	await get_tree().create_timer(.1).timeout
	
	area2d.input_event.connect(
		func(viewport, event, shape_idx):
			if (event is InputEventMouseButton and 
			event.button_index == MOUSE_BUTTON_LEFT and
			event.pressed):
				
				for input in inputs:
					input.disconnect_output()
				for output in outputs:
					output.disconnect_input()
				
				queue_free()
	)

"""
No longer checks if the logic gate has space or not to be placed
"""
func stop_detecting_placeability() -> void:
	if (!area2d):
		push_error("missing area2d for logic gate")
		return
		
	area2d.area_entered.disconnect(on_collision_enter)
	area2d.area_exited.disconnect(on_collision_exit)

func on_collision_enter(area: Area2D) -> void:
	overlappingBodies += 1
	
	set_modular_color_on_sprites(invalid_position_color) 
	
func on_collision_exit(area: Area2D) -> void:
	overlappingBodies -= 1
	
	if overlappingBodies <= 0:
		set_modular_color_on_sprites(valid_position_color) 
		
#--------------------------------------------------------------Emitters

"""
Gets all inputs and outputs the logic gate uses
Stores all of them in the inputs and outputs arrays 
"""
func get_inputs_outputs():
	for child in get_children():
		if child is Output:
			outputs.append(child)
		elif child is Input_:
			inputs.append(child)
			child.recieve.connect(update_logic_gate_result)
				
"""
Changes the result outputed by the logic gate
"""
func update_logic_gate_result(message: Output.Message):
	var final_output: bool = chosen_logic_callable.call(inputs)
	
	if final_output:
		set_modular_color_on_sprites(valid_position_color)
	else:
		set_modular_color_on_sprites(invalid_position_color)
	print(final_output)
	message.sent_val = final_output
	
	for output in outputs:
		output.send.emit(message)
		
#-------------------------------------------------------logic functions

func not_logic(inputs: Array[Input_]) -> bool:
	return !inputs[0].current_val

func and_logic(inputs: Array[Input_]) -> bool:
	return inputs[0].current_val and inputs[1].current_val
	
func or_logic(inputs: Array[Input_]) -> bool:
	return inputs[0].current_val or inputs[1].current_val
