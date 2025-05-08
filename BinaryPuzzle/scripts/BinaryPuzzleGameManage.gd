extends Node2D

const LogicGate = preload("res://BinaryPuzzle/scripts/LogicGate.gd")
const TILE_SIZE = 16;

var is_out_of_barrier:bool = false
const grid_placement_barrier = Rect2(32,0,224,128)
const hidden_position: Vector2 = Vector2(-32,-32)

var selected_logic_gate = null;
var logic_gate_instance: LogicGate;

const not_gate = preload("res://BinaryPuzzle/LogicGates/SimpleLogicGate.tscn");
const and_gate = preload("res://BinaryPuzzle/LogicGates/AndLogicGate.tscn");
const or_gate = preload("res://BinaryPuzzle/LogicGates/OrLogicGate.tscn");

var not_gate_quantity = 2
var and_gate_quantity = 2
var or_gate_quantity = 1
var not_gate_quantity_label: Label
var and_gate_quantity_label: Label
var or_gate_quantity_label: Label

#-----------------------------------------------General Methods

func get_mouse_pos_snapped_to_grid() -> Vector2:
	var mouse_pos: Vector2 = get_global_mouse_position() + Vector2(TILE_SIZE/2,TILE_SIZE/2)
	
	mouse_pos = mouse_pos.snappedf(TILE_SIZE) - Vector2(TILE_SIZE/2,TILE_SIZE/2)
	
	return mouse_pos
	
func get_selected_node():
	logic_gate_instance = selected_logic_gate.instantiate()
	logic_gate_instance.tree_exited.connect(
		func():
			#add back to the quantity when destroyed
			match selected_logic_gate:
				not_gate:
					not_gate_quantity += 1	
				and_gate:
					and_gate_quantity += 1
				or_gate:
					or_gate_quantity += 1
					
			update_gate_quantity_texts()
	)
	add_child(logic_gate_instance)
	
func select_node(node_scene: PackedScene):
	selected_logic_gate = node_scene
	get_selected_node()
	
func place_down_selected_logic_gate():
	
	logic_gate_instance.place_down()
	logic_gate_instance = null
	
	#bring down the quantity
	match selected_logic_gate:
		not_gate:
			not_gate_quantity -= 1
		and_gate:
			and_gate_quantity -= 1
		or_gate:
			or_gate_quantity -= 1
			
	update_gate_quantity_texts()

func update_gate_quantity_texts():
	not_gate_quantity_label.text = str(not_gate_quantity)
	and_gate_quantity_label.text = str(and_gate_quantity)
	or_gate_quantity_label.text = str(or_gate_quantity)

#----------------------------------------------Godot Events

func _ready() -> void:
	var not_button: Button = $"GateSelection/ScrollContainer/VBoxContainer/ColorRect/NotButton"
	var and_button: Button = $"GateSelection/ScrollContainer/VBoxContainer/ColorRect3/AndButton"
	var or_button: Button = $"GateSelection/ScrollContainer/VBoxContainer/ColorRect2/OrButton"
	
	not_gate_quantity_label = $"GateSelection/ScrollContainer/VBoxContainer/ColorRect/Label"
	and_gate_quantity_label = $"GateSelection/ScrollContainer/VBoxContainer/ColorRect3/Label"
	or_gate_quantity_label = $"GateSelection/ScrollContainer/VBoxContainer/ColorRect2/Label"
	
	update_gate_quantity_texts()
	
	not_button.pressed.connect(
		func(): 
			if not_gate_quantity > 0:
				select_node(not_gate))
	or_button.pressed.connect(
		func(): 
			if or_gate_quantity > 0:
				select_node(or_gate)) 
	and_button.pressed.connect(
		func(): 
			if and_gate_quantity > 0:
				select_node(and_gate))

func _process(delta: float) -> void:
	var grid_position = get_mouse_pos_snapped_to_grid()
	
	if is_instance_valid(logic_gate_instance):
		logic_gate_instance.global_position = grid_position
		
		if !grid_placement_barrier.has_point(grid_position):
			logic_gate_instance.global_position = hidden_position

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT 
		and event.is_pressed() 
		and logic_gate_instance
		and logic_gate_instance.is_placeable()
		and grid_placement_barrier.has_point(logic_gate_instance.global_position)):
			
			place_down_selected_logic_gate()
