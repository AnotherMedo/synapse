extends Node2D

const TILE_SIZE = 16;

var selected_logic_gate = preload("res://BinaryPuzzle/LogicGates/SimpleLogicGate.tscn");

var logic_gate_instance: Node2D;

func get_mouse_pos_snapped_to_grid() -> Vector2:
	var mouse_pos: Vector2 = get_global_mouse_position()
	
	return mouse_pos.snappedf(TILE_SIZE) + Vector2(TILE_SIZE/2, TILE_SIZE/2)

func _ready() -> void:
	logic_gate_instance = selected_logic_gate.instantiate()
	add_child(logic_gate_instance)

func _process(delta: float) -> void:
	
	var grid_position = get_mouse_pos_snapped_to_grid()
	
	if is_instance_valid(logic_gate_instance):
		logic_gate_instance.position = grid_position
