extends Node
class_name ResourceManager

## Emitted every time the amount changes.
signal resources_changed(new_value: int)

## Current amount of money the player owns.
var resources: int = 0: # for debug purposes
	set = _set_resources

func _set_resources(value: int) -> void:
	resources = max(0, value)            # never go negative
	emit_signal("resources_changed", resources)

## +amount (use a negative number to subtract, but prefer spend()).
func add(amount: int) -> void:
	_set_resources(resources + amount)

## Tries to take amount; returns **true** on success.
func spend(amount: int) -> bool:
	if amount <= resources:
		_set_resources(resources - amount)
		return true
	return false

## Utility so you don’t have to duplicate comparisons everywhere.
func can_afford(amount: int) -> bool:
	return amount <= resources
