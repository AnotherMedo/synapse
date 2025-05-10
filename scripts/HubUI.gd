extends Control
class_name HubUI

const BINARY_PUZZLE_SCENE := preload("res://scenes/BinaryPuzzleScene.tscn")
@onready var _money_label: Label = $"%MoneyLabel"
@onready var _binary_button: Button = $"%BinaryButton"
@onready var _buy_pickaxe_button: Button = $"%BuyPickaxeButton"
@onready var _buy_miner_button: Button = $"%BuyMinerButton"
@onready var _pickaxe_price_label: Label = $"%PickaxePriceLabel"
@onready var _miners_price_label: Label = $"%MinersPriceLabel"

var pickaxe_level: int = 0
var miner_count: int = 0

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	_binary_button.pressed.connect(_on_binary_button_pressed)
	_buy_pickaxe_button.pressed.connect(_on_buy_pickaxe_pressed)
	_buy_miner_button.pressed.connect(_on_buy_miner_pressed)

	ResourceMan.resources_changed.connect(_update_money_display)
	_update_money_display(ResourceMan.resources)
	_update_buttons()

func open() -> void:
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _on_binary_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to(BINARY_PUZZLE_SCENE)

func _on_buy_pickaxe_pressed() -> void:
	var cost := int(10.0 * pow(1.2, pickaxe_level))
	if ResourceMan.spend(cost):
		pickaxe_level += 1
		print("Pickaxe upgraded to level %d" % pickaxe_level)
		_update_buttons()
	else:
		print("Not enough money to upgrade pickaxe.")

func _on_buy_miner_pressed() -> void:
	var cost := int(10.0 * pow(1.2, miner_count))
	if ResourceMan.spend(cost):
		miner_count += 1
		print("Miner count increased to %d" % miner_count)
		_update_buttons()
	else:
		print("Not enough money to add miners.")

func _update_money_display(value: int) -> void:
	_money_label.text = "Money: %d" % value

func _update_buttons() -> void:
	var pickaxe_cost := int(5.0 * pow(1.2, pickaxe_level))
	var miner_cost := int(5.0 * pow(1.2, miner_count))

	_buy_pickaxe_button.text = "Upgrade Pickaxe: %d" % pickaxe_level
	_pickaxe_price_label.text = "$%d" % pickaxe_cost

	_buy_miner_button.text = "Add miners: %d" % miner_count
	_miners_price_label.text = "$%d" % miner_cost
