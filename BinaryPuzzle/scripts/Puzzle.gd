class_name Puzzle
extends Resource

const PuzzleTest = preload("res://BinaryPuzzle/scripts/PuzzleTest.gd")

var name: String

var num_inputs:int
var num_outputs:int

var tests: Array[PuzzleTest]
