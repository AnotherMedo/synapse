extends Node2D

const LogicGate = preload("res://BinaryPuzzle/scripts/LogicGate.gd")
const GridSystem = preload("res://BinaryPuzzle/scripts/GridSystem.gd")

var selected_logic_gate_scene: PackedScene
var grid_system: GridSystem

const not_gate = preload("res://BinaryPuzzle/LogicGates/SimpleLogicGate.tscn");
const and_gate = preload("res://BinaryPuzzle/LogicGates/AndLogicGate.tscn");
const or_gate = preload("res://BinaryPuzzle/LogicGates/OrLogicGate.tscn");

func _ready() -> void:
	var not_button: Button = $"ScrollContainer/VBoxContainer/ColorRect/NotButton"
	var or_button: Button = $"ScrollContainer/VBoxContainer/ColorRect2/OrButton"
	var and_button: Button = $"ScrollContainer/VBoxContainer/ColorRect3/AndButton"
	
	not_button.pressed.connect(select_not_gate)
	or_button.pressed.connect(select_or_gate)
	and_button.pressed.connect(select_and_gate)

func select_not_gate():
	selected_logic_gate_scene = not_gate
	give_selected_gate_to_grid()
	
func select_and_gate():
	selected_logic_gate_scene = and_gate
	give_selected_gate_to_grid()
	
	
func select_or_gate():
	selected_logic_gate_scene = or_gate
	give_selected_gate_to_grid()
	
	
func give_selected_gate_to_grid():
	if grid_system == null:
		push_error("No gridsystem given to gate_selector")
		return	
		
	grid_system.select_node(selected_logic_gate_scene)
