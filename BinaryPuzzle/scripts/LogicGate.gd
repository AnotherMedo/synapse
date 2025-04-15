extends Node2D

const invalid_position_color: Color = Color(.75,0,0,1)
const valid_position_color: Color = Color(0,.75,0,1)
const no_modular_color: Color = Color(1,1,1,1)

var sprites: Array[Sprite2D]

var overlappingBodies: int = 0
var area2d: Area2D

func _ready() -> void:
	area2d = $"ColliderArea";
	sprites = get_sprite_children()
	
	set_modular_color_on_sprites(valid_position_color)
	
	start_detecting_placeability()
	
func get_sprite_children() -> Array[Sprite2D]:
	var sprites: Array[Sprite2D] = []
	for child in get_children():
		if child is Sprite2D:
			sprites.append(child)
	return sprites

func set_modular_color_on_sprites(color: Color) -> void:
	for sprite in sprites:
		sprite.modulate = color

#-----------------------------------------------placeability

func is_placeable() -> bool:
	return overlappingBodies == 0

func start_detecting_placeability() -> void:
	if (!area2d):
		push_error("missing area2d for logic gate")
		return
		
	area2d.area_entered.connect(on_collision_enter)
	area2d.area_exited.connect(on_collision_exit)
	
func place_down() -> void:
	stop_detecting_placeability()
	set_modular_color_on_sprites(no_modular_color)

func stop_detecting_placeability() -> void:
	if (!area2d):
		push_error("missing area2d for logic gate")
		return
		
	area2d.area_entered.disconnect(on_collision_enter)
	area2d.area_exited.disconnect(on_collision_exit)

func on_collision_enter(area: Area2D) -> void:
	overlappingBodies += 1
	
	set_modular_color_on_sprites(invalid_position_color) 
	
func on_collision_exit(area: Area2D) -> void:
	overlappingBodies -= 1
	
	if overlappingBodies <= 0:
		set_modular_color_on_sprites(valid_position_color) 
