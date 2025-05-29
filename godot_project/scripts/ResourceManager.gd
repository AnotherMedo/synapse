extends Node

# Global resource management singleton
# Add this as an AutoLoad singleton in Project Settings
# OR add this node to your scene and add it to the "resource_manager" group

# Signals
signal resource_spawned(resource_node)
signal resource_mined(resource_node)
signal resources_deposited(amount)
signal request_resource_spawn

# Resource types
enum ResourceType { CRYSTAL, METAL, ENERGY }

# Resource tracking
var active_resources: Array[Node2D] = []
var total_resources_collected: int = 0
var resources_in_world: int = 0

# Resource collection breakdown
var collected_breakdown = {
	ResourceType.CRYSTAL: 0,
	ResourceType.METAL: 0,
	ResourceType.ENERGY: 0
}

# Resource spawning settings
var max_resources_in_world: int = 12
var resource_spawn_timer: Timer
var spawn_cooldown: float = 5.0

# Hub settings
var hub_position: Vector2 = Vector2(50, 50)
var hub_node: Node2D

# Resource properties
var resource_properties = {
	ResourceType.CRYSTAL: {
		"name": "Crystal",
		"color": Color.CYAN,
		"rarity": 0.5,  # 50% spawn chance
		"value": 1,
		"mining_time_multiplier": 1.0
	},
	ResourceType.METAL: {
		"name": "Metal",
		"color": Color.GRAY,
		"rarity": 0.3,  # 30% spawn chance
		"value": 2,
		"mining_time_multiplier": 1.5
	},
	ResourceType.ENERGY: {
		"name": "Energy Core",
		"color": Color.YELLOW,
		"rarity": 0.2,  # 20% spawn chance
		"value": 3,
		"mining_time_multiplier": 2.0
	}
}

func _ready():
	print("ResourceManager initialized")
	
	# Add to group so it can be found
	add_to_group("resource_manager")
	
	setup_spawn_timer()

func setup_spawn_timer():
	resource_spawn_timer = Timer.new()
	resource_spawn_timer.wait_time = spawn_cooldown
	resource_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(resource_spawn_timer)
	resource_spawn_timer.start()

func register_resource(resource_node: Node2D):
	"""Register a resource with the global manager"""
	if resource_node and resource_node not in active_resources:
		active_resources.append(resource_node)
		resources_in_world += 1
		resource_spawned.emit(resource_node)
		
		var resource_type = get_resource_type(resource_node)
		var type_name = resource_properties[resource_type].name
		print("Resource registered: ", type_name, " at ", resource_node.global_position)

func unregister_resource(resource_node: Node2D):
	"""Remove a resource from tracking (when mined)"""
	if resource_node in active_resources:
		active_resources.erase(resource_node)
		resources_in_world -= 1
		resource_mined.emit(resource_node)
		
		var resource_type = get_resource_type(resource_node)
		var type_name = resource_properties[resource_type].name
		print("Resource mined: ", type_name, ", remaining: ", resources_in_world)

func get_resource_type(resource_node: Node2D) -> ResourceType:
	"""Get the type of a resource node"""
	if resource_node and resource_node.has_meta("resource_type"):
		return resource_node.get_meta("resource_type")
	else:
		return ResourceType.CRYSTAL  # Default

func get_nearest_resource(from_position: Vector2) -> Node2D:
	"""Find the nearest resource to a given position"""
	var nearest_resource: Node2D = null
	var nearest_distance: float = INF
	
	# Clean up invalid resources first
	active_resources = active_resources.filter(func(r): return r and is_instance_valid(r))
	resources_in_world = active_resources.size()
	
	for resource in active_resources:
		if resource and is_instance_valid(resource):
			var distance = from_position.distance_to(resource.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_resource = resource
	
	return nearest_resource

func get_nearest_resource_of_type(from_position: Vector2, resource_type: ResourceType) -> Node2D:
	"""Find the nearest resource of a specific type"""
	var nearest_resource: Node2D = null
	var nearest_distance: float = INF
	
	for resource in active_resources:
		if resource and is_instance_valid(resource):
			if get_resource_type(resource) == resource_type:
				var distance = from_position.distance_to(resource.global_position)
				if distance < nearest_distance:
					nearest_distance = distance
					nearest_resource = resource
	
	return nearest_resource

func get_all_resources() -> Array[Node2D]:
	"""Get all active resources"""
	# Clean up invalid resources
	active_resources = active_resources.filter(func(r): return r and is_instance_valid(r))
	resources_in_world = active_resources.size()
	return active_resources

func get_resources_by_type(resource_type: ResourceType) -> Array[Node2D]:
	"""Get all resources of a specific type"""
	var filtered_resources: Array[Node2D] = []
	
	for resource in active_resources:
		if resource and is_instance_valid(resource):
			if get_resource_type(resource) == resource_type:
				filtered_resources.append(resource)
	
	return filtered_resources

func deposit_resources(amount: int, resource_breakdown: Dictionary = {}):
	"""Called when resources are deposited at hub"""
	total_resources_collected += amount
	
	# Update breakdown if provided
	if resource_breakdown.size() > 0:
		for type in ResourceType.values():
			if type in resource_breakdown:
				collected_breakdown[type] += resource_breakdown[type]
	
	resources_deposited.emit(amount)
	print("Resources deposited: ", amount, " Total collected: ", total_resources_collected)
	
	# Print breakdown if available
	if resource_breakdown.size() > 0:
		print("Breakdown:")
		for type in ResourceType.values():
			if type in resource_breakdown and resource_breakdown[type] > 0:
				var type_name = resource_properties[type].name
				print("  ", type_name, ": ", resource_breakdown[type])

func set_hub_position(pos: Vector2):
	"""Set the hub position"""
	hub_position = pos

func set_hub_node(node: Node2D):
	"""Set reference to the hub node"""
	hub_node = node

func should_spawn_resource() -> bool:
	"""Check if we should spawn a new resource"""
	return resources_in_world < max_resources_in_world

func _on_spawn_timer_timeout():
	"""Timer callback to check for resource spawning"""
	if should_spawn_resource():
		request_resource_spawn.emit()

func get_random_resource_type() -> ResourceType:
	"""Get random resource type based on rarity weights"""
	var rand_value = randf()
	var cumulative_chance = 0.0
	
	for type in ResourceType.values():
		cumulative_chance += resource_properties[type].rarity
		if rand_value <= cumulative_chance:
			return type
	
	return ResourceType.CRYSTAL  # Fallback

func get_spawn_position(avoid_positions: Array[Vector2] = [], min_distance: float = 80.0) -> Vector2:
	"""Get a valid spawn position for a resource"""
	var spawn_pos: Vector2
	var attempts = 0
	var max_attempts = 30
	
	while attempts < max_attempts:
		spawn_pos = Vector2(
			randf_range(100, 600),
			randf_range(100, 450)
		)
		
		var valid_position = true
		
		# Check distance from hub
		if spawn_pos.distance_to(hub_position) < min_distance:
			valid_position = false
		
		# Check distance from other avoid positions
		for avoid_pos in avoid_positions:
			if spawn_pos.distance_to(avoid_pos) < min_distance:
				valid_position = false
				break
		
		# Check distance from existing resources
		for resource in active_resources:
			if resource and is_instance_valid(resource):
				if spawn_pos.distance_to(resource.global_position) < 60.0:
					valid_position = false
					break
		
		if valid_position:
			return spawn_pos
		
		attempts += 1
	
	# Fallback position if no valid position found
	return Vector2(randf_range(200, 400), randf_range(200, 300))

func get_resource_value(resource_type: ResourceType) -> int:
	"""Get the value/worth of a resource type"""
	return resource_properties[resource_type].value

func get_resource_name(resource_type: ResourceType) -> String:
	"""Get the display name of a resource type"""
	return resource_properties[resource_type].name

func get_resource_color(resource_type: ResourceType) -> Color:
	"""Get the color associated with a resource type"""
	return resource_properties[resource_type].color

func get_mining_time_multiplier(resource_type: ResourceType) -> float:
	"""Get how much longer this resource takes to mine"""
	return resource_properties[resource_type].mining_time_multiplier

func get_stats() -> Dictionary:
	"""Get current resource statistics"""
	return {
		"active_resources": resources_in_world,
		"total_collected": total_resources_collected,
		"max_resources": max_resources_in_world,
		"collection_breakdown": collected_breakdown.duplicate(),
		"spawn_cooldown": spawn_cooldown
	}

func get_detailed_stats() -> Dictionary:
	"""Get detailed statistics including resource type counts"""
	var type_counts = {}
	var type_positions = {}
	
	for type in ResourceType.values():
		type_counts[type] = 0
		type_positions[type] = []
	
	# Count resources by type
	for resource in active_resources:
		if resource and is_instance_valid(resource):
			var type = get_resource_type(resource)
			type_counts[type] += 1
			type_positions[type].append(resource.global_position)
	
	return {
		"basic_stats": get_stats(),
		"resource_counts_by_type": type_counts,
		"resource_positions_by_type": type_positions,
		"total_value_collected": calculate_total_value()
	}

func calculate_total_value() -> int:
	"""Calculate total value of all collected resources"""
	var total_value = 0
	for type in ResourceType.values():
		total_value += collected_breakdown[type] * resource_properties[type].value
	return total_value

# Debug and utility functions
func force_spawn_resource_type(resource_type: ResourceType, position: Vector2 = Vector2.ZERO):
	"""Debug function to spawn a specific resource type"""
	var spawn_pos = position if position != Vector2.ZERO else get_spawn_position()
	request_resource_spawn.emit()  # This will be handled by the scene
	print("Force spawning ", resource_properties[resource_type].name, " at ", spawn_pos)

func clear_all_resources():
	"""Debug function to remove all resources"""
	for resource in active_resources.duplicate():
		if resource and is_instance_valid(resource):
			unregister_resource(resource)
			resource.queue_free()
	
	active_resources.clear()
	resources_in_world = 0
	print("All resources cleared")

func set_max_resources(new_max: int):
	"""Change the maximum number of resources in the world"""
	max_resources_in_world = new_max
	print("Max resources set to: ", new_max)

func set_spawn_cooldown(new_cooldown: float):
	"""Change how often new resources spawn"""
	spawn_cooldown = new_cooldown
	if resource_spawn_timer:
		resource_spawn_timer.wait_time = spawn_cooldown
	print("Spawn cooldown set to: ", new_cooldown, " seconds")
