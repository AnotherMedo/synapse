extends Node2D

const LogicGate = preload("res://BinaryPuzzle/scripts/LogicGate.gd")
const Source = preload("res://BinaryPuzzle/scripts/Source.gd")
const EndPoint = preload("res://BinaryPuzzle/scripts/EndPoint.gd")
const Puzzle = preload("res://BinaryPuzzle/scripts/Puzzle.gd")
const PuzzleTest = preload("res://BinaryPuzzle/scripts/PuzzleTest.gd")

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

const TestDisplay = preload("res://BinaryPuzzle/scripts/TestDisplay.gd");
var testDisplayer: TestDisplay

var puzzle: Puzzle
var is_checking_puzzle: bool = false

var sources: Array[Source]
var endpoints: Array[EndPoint]

const source = preload("res://BinaryPuzzle/LogicGates/Source.tscn");
const endpoint = preload("res://BinaryPuzzle/LogicGates/EndPoint.tscn");

@export var start_pos_sources: Vector2
@export var start_pos_endpoint: Vector2

#-----------------------------------------------General Methods

func get_mouse_pos_snapped_to_grid() -> Vector2:
	var mouse_pos: Vector2 = get_global_mouse_position() + Vector2(TILE_SIZE/2,TILE_SIZE/2)
	
	mouse_pos = mouse_pos.snappedf(TILE_SIZE) - Vector2(TILE_SIZE/2,TILE_SIZE/2)
	
	return mouse_pos
	
func get_selected_node():
	logic_gate_instance = selected_logic_gate.instantiate()
	logic_gate_instance.on_destroy.connect(
		func(logic_gate: LogicGate):
			#add back to the quantity when destroyed
			match logic_gate.chosen_logic:
				LogicGate.Logic.NOT:
					not_gate_quantity += 1	
				LogicGate.Logic.AND:
					and_gate_quantity += 1
				LogicGate.Logic.OR:
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
				
	puzzle = AndPuzzle()
	load_puzzle()
	
	var check_answer_button: Button = $"CheckAnswerButton"
	
	check_answer_button.pressed.connect(check_puzzle)
	
	testDisplayer = $"Tests"
	testDisplayer.display_tests(puzzle.tests)
	

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

#----------------------------------------------------------Puzzle

func load_puzzle():
	for i in range(puzzle.num_inputs):
		var source_instance : Source = source.instantiate()
		add_child(source_instance)
		source_instance.global_position = start_pos_sources + Vector2.RIGHT * i * TILE_SIZE
		sources.append(source_instance)
		
	for i in range(puzzle.num_outputs):
		var endpoint_instance: EndPoint = endpoint.instantiate()
		add_child(endpoint_instance)
		endpoint_instance.global_position = start_pos_endpoint + Vector2.RIGHT * i * TILE_SIZE
		endpoints.append(endpoint_instance)

func check_puzzle() -> bool:
	if (is_checking_puzzle): 
		return false
		
	is_checking_puzzle = true
	
	var passed_puzzle: bool = true
	
	for test in puzzle.tests:
		passed_puzzle = passed_puzzle and await check_test_passes(test)
		
	print("Puzzle check is: ", passed_puzzle)
	is_checking_puzzle = false
	return passed_puzzle
	
func check_test_passes(test: PuzzleTest) -> bool:
	
	for i in range(puzzle.num_inputs):
		sources[i].change_source_val(test.input_vals[i])
		
		await get_tree().create_timer(.5).timeout
		
	var is_test_passed = true
	
	for i in range(puzzle.num_outputs):
		is_test_passed = (endpoints[i].current_val == test.output_vals[i]) and is_test_passed
		
	return is_test_passed
	
	
func create_puzzle_test(inputs: Array[bool], outputs: Array[bool]) -> PuzzleTest:
	var test = PuzzleTest.new()
	test.output_vals.append_array(outputs)
	test.input_vals.append_array(inputs)
	return test
	
func NotPuzzle():
	var puzzle = Puzzle.new()
	puzzle.num_inputs = 1
	puzzle.num_outputs = 1
	
	var test_1 = create_puzzle_test([false],[true])
	
	var test_2 = create_puzzle_test([true],[false])
	
	puzzle.tests.append_array([test_1, test_2])

	return puzzle
	
func AndPuzzle():
	var puzzle = Puzzle.new()
	puzzle.num_outputs = 1
	puzzle.num_inputs = 2
	
	var test_1 = create_puzzle_test([false,false],[false])
	var test_2 = create_puzzle_test([false,true],[false])
	var test_3 = create_puzzle_test([true,false],[false])
	var test_4 = create_puzzle_test([true,true],[true])
	
	puzzle.tests.append_array([test_1, test_2, test_3, test_4])
	
	return puzzle
	
func OrPuzzle():
	var puzzle = Puzzle.new()
	puzzle.num_outputs = 1
	puzzle.num_inputs = 2
	
	var test_1 = create_puzzle_test([false,false],[false])
	var test_2 = create_puzzle_test([false,true],[true])
	var test_3 = create_puzzle_test([true,false],[true])
	var test_4 = create_puzzle_test([true,true],[true])
	
	puzzle.tests.append_array([test_1, test_2, test_3, test_4])

	return puzzle
