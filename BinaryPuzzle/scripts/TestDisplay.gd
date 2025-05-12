extends Node

const TestDisplay = preload("res://BinaryPuzzle/scenes/TestDisplay.tscn")
const RedSquare = preload("res://BinaryPuzzle/scenes/RedSquare.tscn")
const GreenSquare = preload("res://BinaryPuzzle/scenes/GreenSquare.tscn")

const PuzzleTest = preload("res://BinaryPuzzle/scripts/PuzzleTest.gd")

var container: Control

func _ready():
	container = $"ScrollContainer/VBoxContainer"

func display_tests(tests: Array[PuzzleTest]):
	for test in tests:
		display_test(test)

func display_test(test: PuzzleTest):
	var display = TestDisplay.instantiate()
	container.add_child(display)
	
	var sources_hbox : HBoxContainer = display.get_node("VBoxContainer/HBoxContainer")
	var endpoint_hbox : HBoxContainer = display.get_node("VBoxContainer/HBoxContainer2")
	
	for s in test.input_vals:
		if s:
			sources_hbox.add_child(GreenSquare.instantiate())
		else:
			sources_hbox.add_child(RedSquare.instantiate())
	
	for e in test.output_vals:
		if e:
			endpoint_hbox.add_child(GreenSquare.instantiate())
		else:
			endpoint_hbox.add_child(RedSquare.instantiate())
