extends Node2D

const GridSystem = preload("res://BinaryPuzzle/scripts/GridSystem.gd")
const GateSelector = preload("res://BinaryPuzzle/scripts/GateSelector.gd")

var grid_system: GridSystem
var gate_selector: GateSelector

func _ready() -> void:
	gate_selector = $"GateSelection"
	grid_system = $"Grid"
	
	gate_selector.grid_system = grid_system
