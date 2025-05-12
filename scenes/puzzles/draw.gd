extends Control

@onready var n_0_1: Button = $"../MarginContainer/HBoxContainer/Tree/0_1/Button"
@onready var n_not: Button = $"../MarginContainer/HBoxContainer/Tree/NOT/Button"
@onready var n_and: Button = $"../MarginContainer/HBoxContainer/Tree/AND_OR Tree/AND/Button"
@onready var n_or: Button = $"../MarginContainer/HBoxContainer/Tree/AND_OR Tree/OR/Button"
@onready var n_nand: Button = $"../MarginContainer/HBoxContainer/Tree/NAND_NOR Tree/NAND/Button"
@onready var n_nor: Button = $"../MarginContainer/HBoxContainer/Tree/NAND_NOR Tree/NOR/Button"
@onready var n_xor: Button = $"../MarginContainer/HBoxContainer/Tree/XOR/Button"

@onready var n_0_1_star: TextureRect = $"../MarginContainer/HBoxContainer/Tree/0_1/Button/TextureRect"
@onready var n_not_star: TextureRect = $"../MarginContainer/HBoxContainer/Tree/NOT/Button/TextureRect"
@onready var n_and_star: TextureRect = $"../MarginContainer/HBoxContainer/Tree/AND_OR Tree/AND/Button/TextureRect"
@onready var n_or_star: TextureRect = $"../MarginContainer/HBoxContainer/Tree/AND_OR Tree/OR/Button/TextureRect"
@onready var n_nand_star: TextureRect = $"../MarginContainer/HBoxContainer/Tree/NAND_NOR Tree/NAND/Button/TextureRect"
@onready var n_nor_star: TextureRect = $"../MarginContainer/HBoxContainer/Tree/NAND_NOR Tree/NOR/Button/TextureRect"
@onready var n_xor_star: TextureRect = $"../MarginContainer/HBoxContainer/Tree/XOR/Button/TextureRect"

const Puzzle = preload("res://BinaryPuzzle/scripts/Puzzle.gd")
const PuzzleTest = preload("res://BinaryPuzzle/scripts/PuzzleTest.gd")

const BinaryPuzzleGameManager = preload("res://BinaryPuzzle/scripts/BinaryPuzzleGameManage.gd")
const binary_puzzle_scene = preload("res://scenes/BinaryPuzzleScene.tscn")

var succeeded_puzzles: Array[String]

func _draw() -> void:
	_connect_nodes(n_0_1, n_not, 30)
	_connect_nodes(n_not, n_and, 30)
	_connect_nodes(n_not, n_or, 30)
	_connect_nodes(n_and, n_nand, 30)
	_connect_nodes(n_or, n_nor, 30)
	_connect_nodes(n_nand, n_xor, 30)
	_connect_nodes(n_nor, n_xor, 30)


func _connect_nodes(node1, node2, margin):
	var offset1 = Vector2(node1.get_size().x / 2,  node1.get_size().y + margin)
	var offset2 = Vector2(node1.get_size().x / 2, - margin)
	draw_line(node1.global_position + offset1, node2.global_position + offset2, Color.WHITE, 1.0)

func _ready() -> void:
	if !succeeded_puzzles:
		succeeded_puzzles = []
		
	for p in succeeded_puzzles:
		set_done(p)
	
	n_0_1.pressed.connect(
		func(): 
			load_scene_with_puzzle(SimplePuzzle())
	)
	
	n_not.pressed.connect(
		func(): 
			load_scene_with_puzzle(NotPuzzle())
	)
	
	n_and.pressed.connect(
		func(): 
			load_scene_with_puzzle(AndPuzzle())
	)
	
	n_or.pressed.connect(
		func(): 
			load_scene_with_puzzle(OrPuzzle())
	)
	
	n_nand.pressed.connect(
		func(): 
			load_scene_with_puzzle(NAndPuzzle())
	)
	
	n_nor.pressed.connect(
		func(): 
			load_scene_with_puzzle(NOrPuzzle())
	)

	n_xor.pressed.connect(
		func(): 
			load_scene_with_puzzle(XOrPuzzle())
	)

func load_scene_with_puzzle(puzzle: Puzzle):
	var target_scene: BinaryPuzzleGameManager = binary_puzzle_scene.instantiate()
	
	target_scene.load_puzzle(puzzle)
	get_tree().root.add_child(target_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = target_scene
	
func create_puzzle_test(inputs: Array[bool], outputs: Array[bool]) -> PuzzleTest:
	var test = PuzzleTest.new()
	test.output_vals.append_array(outputs)
	test.input_vals.append_array(inputs)
	return test
	
func SimplePuzzle():
	var puzzle = Puzzle.new()
	puzzle.name = "0_1"
	
	puzzle.num_inputs = 1
	puzzle.num_outputs = 1
	
	var test_1 = create_puzzle_test([false],[false])
	
	var test_2 = create_puzzle_test([true],[true])
	
	puzzle.tests.append_array([test_1, test_2])

	return puzzle
	
func NotPuzzle():
	var puzzle = Puzzle.new()
	puzzle.name = "not"
	
	puzzle.num_inputs = 1
	puzzle.num_outputs = 1
	
	var test_1 = create_puzzle_test([true],[false])
	
	var test_2 = create_puzzle_test([false],[true])
	
	puzzle.tests.append_array([test_1, test_2])

	return puzzle
	
func AndPuzzle():
	var puzzle = Puzzle.new()
	puzzle.name = "and"
	
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
	puzzle.name = "or"
	
	puzzle.num_outputs = 1
	puzzle.num_inputs = 2
	
	var test_1 = create_puzzle_test([false,false],[false])
	var test_2 = create_puzzle_test([false,true],[true])
	var test_3 = create_puzzle_test([true,false],[true])
	var test_4 = create_puzzle_test([true,true],[true])
	
	puzzle.tests.append_array([test_1, test_2, test_3, test_4])

	return puzzle
	
func NOrPuzzle():
	var puzzle = Puzzle.new()
	puzzle.name = "nor"
	
	puzzle.num_outputs = 1
	puzzle.num_inputs = 2
	
	var test_1 = create_puzzle_test([false,false],[true])
	var test_2 = create_puzzle_test([false,true],[false])
	var test_3 = create_puzzle_test([true,false],[false])
	var test_4 = create_puzzle_test([true,true],[false])
	
	puzzle.tests.append_array([test_1, test_2, test_3, test_4])

	return puzzle
	
func NAndPuzzle():
	var puzzle = Puzzle.new()
	puzzle.name = "nand"
	
	puzzle.num_outputs = 1
	puzzle.num_inputs = 2
	
	var test_1 = create_puzzle_test([false,false],[true])
	var test_2 = create_puzzle_test([false,true],[true])
	var test_3 = create_puzzle_test([true,false],[true])
	var test_4 = create_puzzle_test([true,true],[false])
	
	puzzle.tests.append_array([test_1, test_2, test_3, test_4])

	return puzzle
	
func XOrPuzzle():
	var puzzle = Puzzle.new()
	puzzle.name = "xor"
	
	puzzle.num_outputs = 1
	puzzle.num_inputs = 2
	
	var test_1 = create_puzzle_test([false,false],[false])
	var test_2 = create_puzzle_test([false,true],[true])
	var test_3 = create_puzzle_test([true,false],[true])
	var test_4 = create_puzzle_test([true,true],[false])
	
	puzzle.tests.append_array([test_1, test_2, test_3, test_4])

	return puzzle
	
	
func set_done(puzzle_name: String):
	
	if !succeeded_puzzles.has(puzzle_name):
		succeeded_puzzles.append(puzzle_name)
	
	match puzzle_name:
		"0_1":
			n_0_1_star.show()
		"not":
			n_not_star.show()
		"and":
			n_and_star.show()
		"or":
			n_or_star.show()
		"nand":
			n_nand_star.show()
		"nor":
			n_nor_star.show()
		"xor":
			n_xor_star.show()
	
	
