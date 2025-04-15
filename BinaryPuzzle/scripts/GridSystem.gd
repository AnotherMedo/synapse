extends Node2D

const LogicGate = preload("res://BinaryPuzzle/scripts/LogicGate.gd")
const TILE_SIZE = 16;
const mouse_pos_offset: Vector2 = Vector2(256 / 2 + 16 / 2, 128 / 2 + 24)

var selected_logic_gate = preload("res://BinaryPuzzle/LogicGates/SimpleLogicGate.tscn");
var logic_gate_instance: LogicGate;

#-----------------------------------------------General Methods

func get_mouse_pos_snapped_to_grid() -> Vector2:
	var mouse_pos: Vector2 = get_global_mouse_position() - mouse_pos_offset
	
	return mouse_pos.snappedf(TILE_SIZE) + Vector2(TILE_SIZE/2, TILE_SIZE/2)
	
func get_selected_node():
	logic_gate_instance = selected_logic_gate.instantiate()
	add_child(logic_gate_instance)
	
func select_node(node_scene: PackedScene):
	selected_logic_gate = node_scene
	get_selected_node()

#----------------------------------------------Godot Events

func _ready() -> void:
	get_selected_node()

func _process(delta: float) -> void:
	
	var grid_position = get_mouse_pos_snapped_to_grid()
	
	if is_instance_valid(logic_gate_instance):
		logic_gate_instance.position = grid_position

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT 
		and event.is_pressed() 
		and logic_gate_instance.is_placeable()):
			# this is equivalent to placing the old selected object 
			# as it "drops" the old one where it is
			logic_gate_instance.place_down()
			
			get_selected_node()
