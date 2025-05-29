extends Node2D

# Resource types
enum ResourceType { CRYSTAL, METAL, ENERGY }

# Global resource management
var total_resources_collected = 0
var hub_position = Vector2(50, 50)

# Resource spawning
var resource_scene: PackedScene
var max_resources = 12
var current_resource_count = 0

# UI references - COMPACT VERSION
var ui_container: Control
var status_label: Label
var progress_bar: ProgressBar
var inventory_labels: Dictionary = {}
var total_label: Label

# Resource manager reference
var resource_manager: Node

# Resource properties
var resource_properties = {
	ResourceType.CRYSTAL: {
		"name": "Crystal",
		"color": Color.CYAN,
		"rarity": 0.5,
		"value": 1
	},
	ResourceType.METAL: {
		"name": "Metal",
		"color": Color.GRAY,
		"rarity": 0.3,
		"value": 2
	},
	ResourceType.ENERGY: {
		"name": "Energy Core",
		"color": Color.YELLOW,
		"rarity": 0.2,
		"value": 3
	}
}

# Constants
const UPGRADE_RESOURCE_REQUIREMENT = 5

func _ready():
	print("OpenWorldScene loading...")
	
	# Set up resource manager
	setup_resource_manager()
	
	# Set up the hub position
	setup_hub()
	
	# Initialize existing resources
	setup_existing_resources()
	
	# Setup the robot (with delay to ensure everything is ready)
	call_deferred("setup_robot")
	
	# Start resource spawning
	spawn_initial_resources()
	
	# Setup COMPACT UI
	setup_compact_ui()
	
	# Start UI update timer
	var ui_timer = Timer.new()
	ui_timer.wait_time = 0.3  # Update UI more frequently for responsiveness
	ui_timer.timeout.connect(update_robot_ui)
	add_child(ui_timer)
	ui_timer.start()
	
	print("OpenWorldScene loaded successfully!")

func setup_resource_manager():
	# Check if ResourceManager exists as singleton
	var singletons = Engine.get_singleton_list()
	if "ResourceManager" in singletons:
		resource_manager = Engine.get_singleton("ResourceManager")
		print("Using ResourceManager singleton")
	else:
		# Look for ResourceManager in scene
		resource_manager = get_tree().get_first_node_in_group("resource_manager")
		if not resource_manager:
			# Create ResourceManager
			print("Creating ResourceManager in scene")
			var rm_script = preload("res://scripts/ResourceManager.gd")
			resource_manager = Node.new()
			resource_manager.name = "ResourceManager"
			resource_manager.set_script(rm_script)
			add_child(resource_manager)
	
	# Connect resource manager signals
	if resource_manager:
		if resource_manager.has_signal("request_resource_spawn"):
			resource_manager.request_resource_spawn.connect(_on_resource_spawn_requested)
		resource_manager.set_hub_position(hub_position)

func setup_hub():
	# Create a visual indicator for the hub
	var hub_marker = StaticBody2D.new()
	hub_marker.name = "Hub"
	hub_marker.global_position = hub_position
	
	# Add visual representation
	var hub_sprite = Sprite2D.new()
	hub_sprite.texture = create_hub_sprite()
	hub_marker.add_child(hub_sprite)
	
	# Add collision for detection
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 25.0
	collision.shape = circle
	hub_marker.add_child(collision)
	
	add_child(hub_marker)
	print("Hub created at: ", hub_position)

func create_hub_sprite() -> ImageTexture:
	# Create a yellow hub sprite
	var image = Image.create(50, 50, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	# Draw hub as yellow building
	for x in range(5, 45):
		for y in range(15, 45):
			image.set_pixel(x, y, Color(1.0, 0.9, 0.2, 1.0))  # Yellow building
	
	# Draw roof (darker yellow)
	for x in range(3, 47):
		for y in range(10, 17):
			image.set_pixel(x, y, Color(0.8, 0.7, 0.1, 1.0))  # Dark yellow roof
	
	# Draw door (brown)
	for x in range(20, 30):
		for y in range(32, 45):
			image.set_pixel(x, y, Color(0.6, 0.4, 0.2, 1.0))  # Brown door
	
	# Draw windows (light blue)
	for x in range(10, 18):
		for y in range(20, 28):
			image.set_pixel(x, y, Color(0.7, 0.9, 1.0, 1.0))  # Left window
	for x in range(32, 40):
		for y in range(20, 28):
			image.set_pixel(x, y, Color(0.7, 0.9, 1.0, 1.0))  # Right window
	
	# Add "HUB" text indicator
	image.set_pixel(22, 12, Color.BLACK)
	image.set_pixel(27, 12, Color.BLACK)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func create_enhanced_resource_sprite(resource_type: ResourceType) -> ImageTexture:
	"""Create resource sprite based on type"""
	var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	var props = resource_properties[resource_type]
	var main_color = props.color
	var light_color = Color(
		min(main_color.r + 0.3, 1.0), 
		min(main_color.g + 0.3, 1.0), 
		min(main_color.b + 0.3, 1.0), 
		1.0
	)
	
	var center = Vector2(12, 12)
	for x in range(24):
		for y in range(24):
			var pos = Vector2(x, y)
			var dist_to_center = pos.distance_to(center)
			
			match resource_type:
				ResourceType.CRYSTAL:
					# Crystal shape - angular
					if dist_to_center < 8:
						if (x + y) % 3 == 0:
							image.set_pixel(x, y, light_color)
						else:
							image.set_pixel(x, y, main_color)
					elif dist_to_center < 10:
						image.set_pixel(x, y, Color(main_color.r, main_color.g, main_color.b, 0.6))
				
				ResourceType.METAL:
					# Cube shape - geometric
					if x >= 6 and x <= 18 and y >= 6 and y <= 18:
						if x == 6 or x == 18 or y == 6 or y == 18:
							image.set_pixel(x, y, light_color)  # Edges
						elif (x + y) % 2 == 0:
							image.set_pixel(x, y, main_color)  # Fill pattern
						else:
							image.set_pixel(x, y, Color(main_color.r * 0.8, main_color.g * 0.8, main_color.b * 0.8, 1.0))
				
				ResourceType.ENERGY:
					# Glowing orb - smooth gradient
					if dist_to_center < 9:
						var glow_intensity = 1.0 - (dist_to_center / 9.0)
						var glow_color = Color(
							main_color.r * glow_intensity + 1.0 * (1.0 - glow_intensity),
							main_color.g * glow_intensity + 1.0 * (1.0 - glow_intensity),
							main_color.b * glow_intensity,
							glow_intensity
						)
						image.set_pixel(x, y, glow_color)
	
	# Add type-specific highlights
	match resource_type:
		ResourceType.CRYSTAL:
			# Sharp crystal highlights
			image.set_pixel(10, 8, Color.WHITE)
			image.set_pixel(11, 8, Color.WHITE)
			image.set_pixel(14, 16, Color.WHITE)
		ResourceType.METAL:
			# Metallic reflections
			for i in range(8, 12):
				image.set_pixel(i, 10, Color.WHITE)
			for i in range(14, 18):
				image.set_pixel(i, 16, light_color)
		ResourceType.ENERGY:
			# Energy core highlights
			image.set_pixel(12, 9, Color.WHITE)
			image.set_pixel(12, 15, Color.WHITE)
			image.set_pixel(9, 12, Color.WHITE)
			image.set_pixel(15, 12, Color.WHITE)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func setup_existing_resources():
	# Count existing resources and set up their properties
	for child in get_children():
		if child.name.begins_with("Resource") and child is StaticBody2D:
			var resource_type = get_random_resource_type()
			setup_enhanced_resource_node(child, resource_type)
			current_resource_count += 1
			# Register with resource manager
			if resource_manager and resource_manager.has_method("register_resource"):
				resource_manager.register_resource(child)

func setup_enhanced_resource_node(resource_node: StaticBody2D, resource_type: ResourceType):
	"""Setup a resource node with type and properties"""
	
	# Add visual representation
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = create_enhanced_resource_sprite(resource_type)
	resource_node.add_child(sprite)
	
	# Store resource type in metadata
	resource_node.set_meta("resource_type", resource_type)
	resource_node.set_meta("resource_name", resource_properties[resource_type].name)
	
	# Add glowing effect for rare resources
	if resource_type == ResourceType.ENERGY:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(sprite, "modulate", Color(1.3, 1.3, 1.0, 1.0), 1.5)
		tween.tween_property(sprite, "modulate", Color.WHITE, 1.5)
	elif resource_type == ResourceType.METAL:
		# Subtle metallic shine
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(sprite, "modulate", Color(1.1, 1.1, 1.1, 1.0), 2.0)
		tween.tween_property(sprite, "modulate", Color.WHITE, 2.0)
	
	# Ensure proper collision shape
	var collision = resource_node.get_node_or_null("CollisionShape2D")
	if collision and not collision.shape:
		var circle = CircleShape2D.new()
		circle.radius = 12.0
		collision.shape = circle
	
	print("Created ", resource_properties[resource_type].name, " at ", resource_node.global_position)

func get_random_resource_type() -> ResourceType:
	"""Get random resource type based on rarity weights"""
	var rand_value = randf()
	var cumulative_chance = 0.0
	
	for type in ResourceType.values():
		cumulative_chance += resource_properties[type].rarity
		if rand_value <= cumulative_chance:
			return type
	
	return ResourceType.CRYSTAL  # Fallback

func setup_robot():
	var robot = get_node_or_null("Robot")
	if robot:
		robot.set_hub_position(hub_position)
		print("Robot configured with hub at: ", hub_position)
		
		# Connect robot signals for UI updates
		if robot.has_signal("phase_changed"):
			robot.phase_changed.connect(_on_robot_phase_changed)
		if robot.has_signal("resource_collected"):
			robot.resource_collected.connect(_on_robot_resource_collected)
		
		# Show initial hint
		show_interaction_hint("Pick up the robot and place it near resources to start mining!")
		
		# DON'T auto-upgrade for normal gameplay
		# robot.force_upgrade()
	else:
		print("No robot found in scene")

func spawn_initial_resources():
	# Spawn additional resources if needed
	while current_resource_count < max_resources:
		spawn_random_enhanced_resource()

func spawn_random_enhanced_resource():
	"""Spawn a resource with random type based on rarity"""
	var resource = StaticBody2D.new()
	var resource_type = get_random_resource_type()
	
	resource.name = "Resource" + str(current_resource_count + 1)
	
	# Get spawn position
	var resource_pos = get_valid_spawn_position()
	resource.global_position = resource_pos
	
	# Setup the resource
	setup_enhanced_resource_node(resource, resource_type)
	
	add_child(resource)
	current_resource_count += 1
	
	# Register with resource manager
	if resource_manager and resource_manager.has_method("register_resource"):
		resource_manager.register_resource(resource)
	
	print("Spawned ", resource_properties[resource_type].name, " at: ", resource_pos)

func get_valid_spawn_position() -> Vector2:
	"""Get a valid spawn position avoiding other objects - FIXED VERSION"""
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
		if spawn_pos.distance_to(hub_position) < 80:
			valid_position = false
		
		# Check distance from existing resources - FIXED: Only check Node2D objects
		for child in get_children():
			if child is Node2D and child.name.begins_with("Resource"):
				if spawn_pos.distance_to(child.global_position) < 60.0:
					valid_position = false
					break
		
		# Check distance from player and robot - FIXED: Check if they exist and are Node2D
		var player = get_node_or_null("Player")
		var robot = get_node_or_null("Robot")
		if player and player is Node2D and spawn_pos.distance_to(player.global_position) < 80.0:
			valid_position = false
		if robot and robot is Node2D and spawn_pos.distance_to(robot.global_position) < 80.0:
			valid_position = false
		
		if valid_position:
			return spawn_pos
		
		attempts += 1
	
	# Fallback position
	return Vector2(randf_range(200, 500), randf_range(200, 350))

func setup_compact_ui():
	"""Create COMPACT UI for robot status"""
	
	# Main UI container - MUCH SMALLER
	ui_container = Control.new()
	ui_container.name = "CompactUI"
	ui_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	ui_container.z_index = 100
	add_child(ui_container)
	
	# Compact background panel
	var bg_panel = ColorRect.new()
	bg_panel.size = Vector2(200, 85)  # Much smaller!
	bg_panel.position = Vector2(-210, 10)  # Top-right corner
	bg_panel.color = Color(0, 0, 0, 0.8)
	ui_container.add_child(bg_panel)
	
	# Robot status - single line
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Robot: Pickupable"
	status_label.position = Vector2(-205, 15)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	ui_container.add_child(status_label)
	
	# Compact progress bar
	progress_bar = ProgressBar.new()
	progress_bar.size = Vector2(190, 12)  # Smaller
	progress_bar.position = Vector2(-205, 35)
	progress_bar.max_value = UPGRADE_RESOURCE_REQUIREMENT
	progress_bar.value = 0
	ui_container.add_child(progress_bar)
	
	# Compact inventory - horizontal layout
	var inventory_container = Control.new()
	inventory_container.position = Vector2(-205, 52)
	ui_container.add_child(inventory_container)
	
	var x_offset = 0
	for type in ResourceType.values():
		var label = Label.new()
		label.name = "Inv" + str(type)
		label.text = "C:0"  # Short format
		label.position = Vector2(x_offset, 0)
		label.add_theme_color_override("font_color", resource_properties[type].color)
		inventory_container.add_child(label)
		inventory_labels[type] = label
		x_offset += 45  # Horizontal spacing
	
	# Total collected - bottom line
	total_label = Label.new()
	total_label.text = "Total: 0"
	total_label.position = Vector2(-205, 70)
	total_label.add_theme_color_override("font_color", Color.YELLOW)
	ui_container.add_child(total_label)
	
	# Compact instructions - bottom of screen
	var instructions = Label.new()
	instructions.text = "WASD: Move | Enter: Interact | Space: Debug Spawn"
	instructions.position = Vector2(10, get_viewport().size.y - 30)
	instructions.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	instructions.z_index = 50
	add_child(instructions)

func update_robot_ui():
	"""Update COMPACT UI with current robot status"""
	var robot = get_node_or_null("Robot")
	if not robot:
		return
	
	var status = robot.get_robot_status()
	
	# Update status - compact format
	if status_label:
		var phase_short = "Pick" if status.phase == "PICKUPABLE" else "Auto"
		var state_short = ""
		match status.state:
			"IDLE": state_short = "Idle"
			"MOVING_TO_RESOURCE": state_short = "→Res"
			"MINING": state_short = "Mine"
			"MOVING_TO_HUB": state_short = "→Hub"
			"DEPOSITING": state_short = "Drop"
		
		status_label.text = "Robot: " + phase_short + " | " + state_short
	
	# Update progress bar
	if progress_bar:
		progress_bar.value = status.total_resources
		if status.phase == "AUTONOMOUS":
			progress_bar.modulate = Color.GOLD
		else:
			progress_bar.modulate = Color.WHITE
	
	# Update inventory - compact format
	for type in ResourceType.values():
		if type in inventory_labels:
			var label = inventory_labels[type]
			var inventory = status.get("inventory", {})
			var count = inventory.get(type, 0)

			var short_name = ""
			match type:
				ResourceType.CRYSTAL: short_name = "C"
				ResourceType.METAL: short_name = "M"
				ResourceType.ENERGY: short_name = "E"
			label.text = short_name + ":" + str(count)
	
	# Update total
	if total_label:
		total_label.text = "Total: " + str(total_resources_collected)

func show_interaction_hint(message: String, duration: float = 2.5):
	"""Show temporary hint message - SMALLER"""
	var hint_label = Label.new()
	hint_label.text = message
	hint_label.position = Vector2(get_viewport().size.x / 2 - 100, get_viewport().size.y - 60)
	hint_label.add_theme_color_override("font_color", Color.YELLOW)
	hint_label.z_index = 200
	
	# Smaller background
	var bg = ColorRect.new()
	bg.size = Vector2(200, 25)
	bg.position = Vector2(-50, -3)
	bg.color = Color(0, 0, 0, 0.7)
	hint_label.add_child(bg)
	
	add_child(hint_label)
	
	# Auto-remove after duration
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): 
		hint_label.queue_free()
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

func _input(event):
	# Debug controls
	if event.is_action_pressed("ui_accept"):  # Enter key
		# Force robot upgrade for testing
		var robot = get_node_or_null("Robot")
		if robot and robot.phase == robot.RobotPhase.PICKUPABLE:
			robot.force_upgrade()
			print("Debug: Robot upgraded!")
			show_interaction_hint("Robot upgraded for testing!")
	
	elif event.is_action_pressed("ui_select"):  # Space key
		# Spawn new resource for testing
		spawn_random_enhanced_resource()
		print("Debug: New resource spawned!")
		show_interaction_hint("New resource spawned!")
	
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		# Cycle through resource types for testing
		var types = [ResourceType.CRYSTAL, ResourceType.METAL, ResourceType.ENERGY]
		var random_type = types[randi() % types.size()]
		spawn_specific_resource_type(random_type)

func spawn_specific_resource_type(resource_type: ResourceType):
	"""Debug function to spawn specific resource type"""
	var resource = StaticBody2D.new()
	resource.name = "DebugResource" + str(randi())
	resource.global_position = get_global_mouse_position()
	
	setup_enhanced_resource_node(resource, resource_type)
	add_child(resource)
	
	if resource_manager and resource_manager.has_method("register_resource"):
		resource_manager.register_resource(resource)
	
	var type_name = resource_properties[resource_type].name
	show_interaction_hint("Spawned " + type_name + "!")

func resource_deposited(amount: int):
	# Called when robot deposits resources at hub (simple version)
	total_resources_collected += amount
	
	# Spawn new resources to maintain the world
	spawn_resources_to_maintain_world()
	
	print("Total resources collected: ", total_resources_collected)

func resource_deposited_detailed(resource_breakdown: Dictionary):
	"""Handle detailed resource deposit information"""
	var total_deposited = 0
	
	print("Resources deposited:")
	for type in ResourceType.values():
		var amount = resource_breakdown.get(type, 0)
		if amount > 0:
			total_deposited += amount
			var type_name = resource_properties[type].name
			print("  ", type_name, ": ", amount)
	
	total_resources_collected += total_deposited
	
	# Show compact breakdown hint
	var breakdown_hint = "Deposited: "
	for type in ResourceType.values():
		var amount = resource_breakdown.get(type, 0)
		if amount > 0:
			var short_name = resource_properties[type].name[0]  # First letter
			breakdown_hint += short_name + str(amount) + " "
	
	show_interaction_hint(breakdown_hint, 2.0)
	
	# Spawn new resources to maintain world
	spawn_resources_to_maintain_world()

func spawn_resources_to_maintain_world():
	"""Maintain resource count in world"""
	var current_count = count_active_resources()
	while current_count < max_resources:
		spawn_random_enhanced_resource()
		current_count += 1

func count_active_resources() -> int:
	"""Count currently active resources in scene - FIXED VERSION"""
	var count = 0
	for child in get_children():
		if child is StaticBody2D and child.name.begins_with("Resource"):
			count += 1
	return count

func _on_resource_spawn_requested():
	# Called by ResourceManager when it wants to spawn a resource
	if count_active_resources() < max_resources:
		spawn_random_enhanced_resource()

func _on_robot_phase_changed(new_phase: String):
	"""Handle robot phase changes"""
	match new_phase:
		"AUTONOMOUS":
			show_interaction_hint("Robot upgraded! Working autonomously!", 3.0)
		"PICKUPABLE":
			show_interaction_hint("Robot needs to be carried", 2.0)

func _on_robot_resource_collected(resource_type: int, amount: int):
	"""Handle robot collecting resources"""
	var type_name = resource_properties[resource_type].name
	show_interaction_hint("Collected " + str(amount) + " " + type_name, 1.5)
