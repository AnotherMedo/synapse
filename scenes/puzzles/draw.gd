extends Control

@onready var n_0_1 = $"../MarginContainer/HBoxContainer/Tree/0_1/Button"
@onready var n_not = $"../MarginContainer/HBoxContainer/Tree/NOT/Button"
@onready var n_and = $"../MarginContainer/HBoxContainer/Tree/AND_OR Tree/AND/Button"
@onready var n_or = $"../MarginContainer/HBoxContainer/Tree/AND_OR Tree/OR/Button"
@onready var n_nand = $"../MarginContainer/HBoxContainer/Tree/NAND_NOR Tree/NAND/Button"
@onready var n_nor = $"../MarginContainer/HBoxContainer/Tree/NAND_NOR Tree/NOR/Button"
@onready var n_xor = $"../MarginContainer/HBoxContainer/Tree/XOR/Button"



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
