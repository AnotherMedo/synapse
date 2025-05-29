extends CharacterBody2D

# Robot Phases
enum RobotPhase { PICKUPABLE, AUTONOMOUS }

# State management
enum RobotState { IDLE, MOVING_TO_RESOURCE, MINING, MOVING_TO_HUB, DEPOSITING }

# Resource types
enum ResourceType { CRYSTAL, METAL, ENERGY }

# Signals
signal phase_changed(new_phase)
signal resource_collected(resource_type, amount)
signal resources_deposited(total_amount)
signal upgrade_available(robot)
signal upgrade_unavailable(robot)

# Core Variables
var phase = RobotPhase.PICKUPABLE
var current_state = RobotState.IDLE
var hub_position = Vector2(50, 50)

# How many resource piles to collect before depositing
var MAX_INVENTORY_CAPACITY: int = 5

# Resource system
var resource_inventory = {
	ResourceType.CRYSTAL: 0,
	ResourceType.METAL: 0,
	ResourceType.ENERGY: 0
}

# Robot properties
var SPEED = 100
var MINING_TIME = 2.0
var DETECTION_RADIUS = 80.0
var UPGRADE_THRESHOLD = 10  # Keep for compatibility, but use new upgrade logic
var MINING_RANGE = 30.0

# Upgrade system
var upgrade_ready: bool = false
var upgrade_ready_message_shown: bool = false

# Navigation and movement - IMPROVED
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

var current_target: Node2D = null
var mining = false
var target_position = Vector2.ZERO
var current_resource_target: Node2D = null
var use_direct_movement: bool = false  # Fallback when navigation fails
var stuck_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var STUCK_THRESHOLD: float = 2.0  # Time to detect if stuck
var state_timeout: float = 0.0
var STATE_TIMEOUT_LIMIT: float = 10.0  # Max time in moving states

# Mining system
var mining_timer: float = 0.0
var mining_progress_bar: ProgressBar

# Player interaction
var is_held_by_player: bool = false
var player_reference: Node = null

# Visual components
var sprite: Sprite2D
var detection_area: Area2D
var upgrade_indicator: Sprite2D

# Global resource list (simple approach)
var global_resources: Array[Node2D] = []
var resource_manager: Node = null

func _ready():
	print("Robot initializing...")
	setup_robot()
	setup_navigation()
	setup_detection()
	setup_visuals()
	find_resource_manager()
	
	# Ensure hub position is set - you can change this to your actual hub position
	# For now, using a sensible default that should be visible
	if hub_position == Vector2(50, 50):
		# Try to find hub in scene or use a better default
		var scene_hub = find_hub_in_scene()
		if scene_hub:
			hub_position = scene_hub.global_position
			print("Robot: Found hub at ", hub_position)
		else:
			# Use center of screen as fallback, but NOT (0,0)
			hub_position = Vector2(400, 300)
			print("Robot: Using fallback hub position: ", hub_position)
	
	# Safety check - never allow (0,0) hub position
	if hub_position == Vector2.ZERO:
		hub_position = Vector2(400, 300)
		print("Robot: Fixed invalid hub position to: ", hub_position)
	
	last_position = global_position
	print("Robot ready in phase: ", RobotPhase.keys()[phase], " Hub at: ", hub_position)

func setup_robot():
	"""Initialize core robot components"""
	# Create sprite
	sprite = Sprite2D.new()
	add_child(sprite)
	
	# Create mining progress bar
	mining_progress_bar = ProgressBar.new()
	mining_progress_bar.size = Vector2(40, 6)
	mining_progress_bar.position = Vector2(-20, -25)
	mining_progress_bar.visible = false
	add_child(mining_progress_bar)
	
	# Create upgrade indicator
	upgrade_indicator = Sprite2D.new()
	upgrade_indicator.position = Vector2(0, -35)
	upgrade_indicator.visible = false
	add_child(upgrade_indicator)
	create_upgrade_indicator()
	
	update_robot_appearance()

func create_upgrade_indicator():
	"""Create upgrade ready indicator"""
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw upgrade arrow/star
	var upgrade_color = Color.GOLD
	# Simple star pattern
	image.set_pixel(8, 2, upgrade_color)
	image.set_pixel(7, 4, upgrade_color)
	image.set_pixel(8, 4, upgrade_color)
	image.set_pixel(9, 4, upgrade_color)
	image.set_pixel(6, 6, upgrade_color)
	image.set_pixel(7, 6, upgrade_color)
	image.set_pixel(8, 6, upgrade_color)
	image.set_pixel(9, 6, upgrade_color)
	image.set_pixel(10, 6, upgrade_color)
	image.set_pixel(7, 8, upgrade_color)
	image.set_pixel(8, 8, upgrade_color)
	image.set_pixel(9, 8, upgrade_color)
	image.set_pixel(8, 10, upgrade_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	upgrade_indicator.texture = texture

func setup_navigation():
	"""Setup pathfinding system"""
	navigation_agent = NavigationAgent2D.new()
	add_child(navigation_agent)
	
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 15.0
	navigation_agent.max_speed = SPEED
	navigation_agent.avoidance_enabled = true
	
	# Wait for navigation to be ready
	call_deferred("_on_navigation_ready")

func _on_navigation_ready():
	await get_tree().physics_frame
	print("Navigation system ready")

	var nav_map = navigation_agent.get_navigation_map()

	if not nav_map.is_valid() or NavigationServer2D.map_get_regions(nav_map).is_empty():
		print("Robot: No navigation map detected, using direct movement")
		use_direct_movement = true

func setup_detection():
	"""Setup resource detection area"""
	detection_area = Area2D.new()
	add_child(detection_area)
	
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = DETECTION_RADIUS
	collision_shape.shape = circle_shape
	detection_area.add_child(collision_shape)
	
	detection_area.body_entered.connect(_on_resource_detected)
	detection_area.body_exited.connect(_on_resource_lost)

func setup_visuals():
	"""Create robot sprite based on current phase"""
	update_robot_appearance()

func find_resource_manager():
	"""Find the resource manager in the scene"""
	resource_manager = get_tree().get_first_node_in_group("resource_manager")
	if resource_manager:
		print("Found resource manager")
	else:
		print("No resource manager found, using fallback methods")

func find_hub_in_scene() -> Node2D:
	"""Try to find the hub node in the scene"""
	var scene_root = get_tree().current_scene
	
	# Look for nodes with "hub" in the name
	for child in scene_root.get_children():
		if child.name.to_lower().contains("hub"):
			return child as Node2D
	
	# Look for nodes in "hub" group
	var hub_nodes = get_tree().get_nodes_in_group("hub")
	if hub_nodes.size() > 0:
		return hub_nodes[0] as Node2D
	
	return null

func update_robot_appearance():
	"""Update robot sprite based on current phase"""
	var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Robot body
	var body_color = Color(0.6, 0.6, 0.7, 1.0)
	draw_rectangle(image, 6, 8, 18, 16, body_color)
	
	# Robot face
	var face_color = Color(0.8, 0.8, 0.9, 1.0)
	draw_rectangle(image, 8, 10, 16, 14, face_color)
	
	# Eyes
	var eye_color = Color(0.2, 0.6, 1.0, 1.0)
	image.set_pixel(10, 12, eye_color)
	image.set_pixel(14, 12, eye_color)
	
	if phase == RobotPhase.AUTONOMOUS:
		# Add wheels for autonomous phase
		var wheel_color = Color(0.2, 0.2, 0.2, 1.0)
		draw_rectangle(image, 4, 18, 8, 22, wheel_color)  # Left wheel
		draw_rectangle(image, 16, 18, 20, 22, wheel_color)  # Right wheel
		
		# Add antenna
		image.set_pixel(12, 4, Color.RED)
		image.set_pixel(12, 5, Color.GRAY)
	else:
		# Add handle for pickupable phase
		var handle_color = Color(0.8, 0.8, 0.2, 1.0)
		draw_rectangle(image, 10, 4, 14, 6, handle_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func draw_rectangle(image: Image, x1: int, y1: int, x2: int, y2: int, color: Color):
	"""Helper function to draw rectangles on image"""
	for x in range(x1, x2):
		for y in range(y1, y2):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)

func _physics_process(delta):
	"""Main physics process - handles both phases"""
	# Always check upgrade status
	check_upgrade_status()
	
	# Handle being carried
	if is_held_by_player:
		handle_being_carried()
		return
	
	# Update movement tracking for autonomous robots
	if phase == RobotPhase.AUTONOMOUS:
		update_movement_tracking(delta)
	
	# Handle behavior based on phase
	if phase == RobotPhase.PICKUPABLE:
		handle_pickupable_phase(delta)
	elif phase == RobotPhase.AUTONOMOUS:
		handle_autonomous_phase(delta)

func check_upgrade_status():
	"""Check and update upgrade availability"""
	var new_upgrade_ready = should_upgrade()
	
	if new_upgrade_ready != upgrade_ready:
		upgrade_ready = new_upgrade_ready
		
		if upgrade_ready:
			upgrade_indicator.visible = true
			# Animate upgrade indicator
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(upgrade_indicator, "modulate", Color.GOLD, 0.5)
			tween.tween_property(upgrade_indicator, "modulate", Color.WHITE, 0.5)
			
			if not upgrade_ready_message_shown:
				upgrade_ready_message_shown = true
				print("Robot: UPGRADE AVAILABLE! Press U to upgrade to autonomous mode!")
				upgrade_available.emit(self)
		else:
			upgrade_indicator.visible = false
			upgrade_ready_message_shown = false
			upgrade_unavailable.emit(self)

func handle_being_carried():
	"""Handle visual feedback when carried by player"""
	sprite.modulate = Color(0.8, 0.8, 1.0, 0.8)
	sprite.scale = Vector2(0.9, 0.9)
	
	# Stop any ongoing mining
	if current_state == RobotState.MINING:
		stop_mining()

func handle_pickupable_phase(delta: float):
	"""Handle robot behavior in pickupable phase - FIXED"""
	match current_state:
		RobotState.IDLE:
			look_for_nearby_resources()
		RobotState.MINING:
			process_mining(delta)
		RobotState.DEPOSITING:
			deposit_resources()

func handle_autonomous_phase(delta: float):
	"""Handle robot behavior in autonomous phase - FIXED with debugging"""
	# Add occasional debug output
	if Engine.get_process_frames() % 60 == 0:  # Every second
		print("Autonomous robot state: ", RobotState.keys()[current_state], " at ", global_position)
	
	match current_state:
		RobotState.IDLE:
			find_next_task_autonomous()
		RobotState.MOVING_TO_RESOURCE:
			move_to_target(delta)
			check_resource_arrival()
		RobotState.MINING:
			process_mining(delta)
		RobotState.MOVING_TO_HUB:
			move_to_target(delta)
			check_hub_arrival()
		RobotState.DEPOSITING:
			deposit_resources()

func look_for_nearby_resources():
	"""Look for resources to mine when in pickupable phase - FIXED"""
	var nearest_resource = find_nearest_resource_in_range(MINING_RANGE)
	
	if nearest_resource:
		print("Pickupable robot: Found nearby resource, starting to mine")
		current_resource_target = nearest_resource
		start_mining(current_resource_target)
	elif get_total_resources() > 0:
		# If we have resources and are near hub, deposit them
		if global_position.distance_to(hub_position) <= 40:
			current_state = RobotState.DEPOSITING

func find_next_task_autonomous():
	"""Find next task for autonomous robot - FIXED"""
	print("Autonomous robot: Finding next task. Resources: ", get_total_resources())
	
	# Reset state timeout when starting new task
	state_timeout = 0.0
	
	# Always prioritize depositing if we have resources
	var carried = get_total_resources()
	var no_more_nodes = false
	if resource_manager and resource_manager.active_resources.size() == 0:
		no_more_nodes = true

	if carried >= MAX_INVENTORY_CAPACITY or (carried > 0 and no_more_nodes):	
		var distance_to_hub = global_position.distance_to(hub_position)
		print("Autonomous robot: Distance to hub: ", distance_to_hub)
		
		if distance_to_hub <= 30:
			current_state = RobotState.DEPOSITING
			print("Autonomous robot: Close to hub, depositing directly")
		else:
			print("Autonomous robot: Setting hub target: ", hub_position)
			set_target_position(hub_position)
			current_state = RobotState.MOVING_TO_HUB
			print("Autonomous robot: Going to deposit resources at hub: ", hub_position)
	else:
		# Find resource to mine - try multiple methods
		var nearest_resource = find_nearest_resource_autonomous()
		if nearest_resource and is_instance_valid(nearest_resource):
			current_resource_target = nearest_resource
			var target_pos = nearest_resource.global_position
			print("Autonomous robot: Found resource at: ", target_pos)
			set_target_position(target_pos)
			current_state = RobotState.MOVING_TO_RESOURCE
			print("Autonomous robot: Going to mine resource at: ", target_pos)
		else:
			print("Autonomous robot: No resources found to mine - staying idle")
			current_state = RobotState.IDLE

func find_nearest_resource() -> Node2D:
	"""Find nearest resource - used by pickupable robots"""
	if resource_manager and resource_manager.has_method("get_nearest_resource"):
		return resource_manager.get_nearest_resource(global_position)
	else:
		return search_scene_for_resources()

func find_nearest_resource_autonomous() -> Node2D:
	"""Find nearest resource specifically for autonomous robots - IMPROVED"""
	print("Autonomous robot: Searching for resources...")
	
	# Method 1: Try resource manager first
	if resource_manager and resource_manager.has_method("get_nearest_resource"):
		var resource = resource_manager.get_nearest_resource(global_position)
		if resource and is_instance_valid(resource):
			print("Autonomous robot: Found resource via manager at: ", resource.global_position)
			return resource
	
	# Method 2: Try resources group
	var resources_in_group = get_tree().get_nodes_in_group("resources")
	print("Autonomous robot: Found ", resources_in_group.size(), " resources in group")
	
	if resources_in_group.size() > 0:
		var nearest_resource = null
		var nearest_distance = INF
		
		for resource in resources_in_group:
			if resource and is_instance_valid(resource) and resource is Node2D:
				var distance = global_position.distance_to(resource.global_position)
				print("Autonomous robot: Resource at ", resource.global_position, " distance: ", distance)
				if distance < nearest_distance:
					nearest_distance = distance
					nearest_resource = resource
		
		if nearest_resource:
			print("Autonomous robot: Selected nearest resource at: ", nearest_resource.global_position)
			return nearest_resource
	
	# Method 3: Manual scene search as fallback
	var scene_resource = search_scene_for_resources_autonomous()
	if scene_resource:
		print("Autonomous robot: Found resource via scene search at: ", scene_resource.global_position)
		return scene_resource
	
	print("Autonomous robot: No resources found by any method")
	return null

func search_scene_for_resources_autonomous() -> Node2D:
	"""Enhanced scene search specifically for autonomous robots"""
	var scene_root = get_tree().current_scene
	var nearest_resource = null
	var nearest_distance = INF
	
	print("Autonomous robot: Scanning scene for resources...")
	
	# Recursively search all children
	var nodes_to_check = [scene_root]
	
	while nodes_to_check.size() > 0:
		var current_node = nodes_to_check.pop_front()
		
		# Check if this node is a resource
		if is_resource_node(current_node):
			var distance = global_position.distance_to(current_node.global_position)
			print("Autonomous robot: Found resource node '", current_node.name, "' at ", current_node.global_position, " distance: ", distance)
			
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_resource = current_node
		
		# Add children to check list
		for child in current_node.get_children():
			nodes_to_check.append(child)
	
	if nearest_resource:
		print("Autonomous robot: Scene search selected resource at: ", nearest_resource.global_position)
	else:
		print("Autonomous robot: Scene search found no resources")
	
	return nearest_resource

func find_nearest_resource_in_range(max_range: float) -> Node2D:
	"""Find nearest resource within specified range"""
	var nearest = find_nearest_resource()
	if nearest and global_position.distance_to(nearest.global_position) <= max_range:
		return nearest
	return null

func search_scene_for_resources() -> Node2D:
	"""Fallback method to search scene for resources"""
	var scene_root = get_tree().current_scene
	var nearest_resource = null
	var nearest_distance = INF
	
	for child in scene_root.get_children():
		if is_resource_node(child):
			var distance = global_position.distance_to(child.global_position)
			if distance < nearest_distance and distance <= DETECTION_RADIUS:
				nearest_distance = distance
				nearest_resource = child
	
	return nearest_resource

func is_resource_node(node: Node) -> bool:
	"""Check if node is a resource"""
	# More specific check to avoid treating ResourceManager as a resource
	if node.is_in_group("resource_manager"):
		return false
	
	# Check if it's in the resources group
	if node.is_in_group("resources"):
		return true
	
	# Check if it's a Node2D with resource in the name (but not ResourceManager)
	if node is Node2D:
		var name_lower = node.name.to_lower()
		return name_lower.begins_with("resource") and not name_lower.contains("manager")
	
	return false

func set_target_position(pos: Vector2):
	"""Set navigation target - IMPROVED with validation"""
	# Validate target position
	if pos == Vector2.ZERO:
		print("Robot: ERROR - Invalid target position (0,0), ignoring")
		return
	
	if pos.x < 0 or pos.y < 0 or pos.x > 10000 or pos.y > 10000:
		print("Robot: ERROR - Target position out of bounds: ", pos, ", ignoring")
		return
	
	target_position = pos
	print("Robot: Setting valid target position to: ", pos)
	
	# Try navigation agent first
	if navigation_agent and not use_direct_movement:
		navigation_agent.target_position = pos
		print("Robot: Navigation agent target set to: ", pos)
		
		# Verify the navigation agent accepted the target
		await get_tree().process_frame
		var nav_target = navigation_agent.target_position
		if nav_target.distance_to(pos) > 50:  # If navigation target is way off
			print("Robot: Navigation agent target mismatch, switching to direct movement")
			use_direct_movement = true
	else:
		print("Robot: Using direct movement to target: ", pos)

func move_to_target(delta: float):
	"""Move robot towards target - COMPLETELY REWRITTEN with debugging"""
	if target_position == Vector2.ZERO:
		print("Robot: No target position set")
		return
	
	var distance_to_target = global_position.distance_to(target_position)
	print("Robot: Moving to target ", target_position, " from ", global_position, " distance: ", distance_to_target)
	
	var direction = Vector2.ZERO
	
	# Always use direct movement for now to debug the issue
	if true:  # Force direct movement for debugging
		direction = global_position.direction_to(target_position)
		print("Robot: Direct movement direction: ", direction)
		
		if direction.length() > 0.1:
			velocity = direction * SPEED
			move_and_slide()
			print("Robot: Applied velocity: ", velocity, " New position: ", global_position)
			
			# Visual feedback
			animate_movement(direction)
		else:
			print("Robot: Direction vector too small: ", direction)
	else:
		# Navigation agent logic (currently disabled for debugging)
		if use_direct_movement or not navigation_agent:  
			direction = global_position.direction_to(target_position)
			print("Robot: Direct movement - Direction: ", direction, " Distance: ", distance_to_target)
		else:
			# Try navigation agent
			if navigation_agent.is_navigation_finished():
				print("Robot: Navigation finished")
				return
			
			var next_path_position = navigation_agent.get_next_path_position()
			direction = global_position.direction_to(next_path_position)
			print("Robot: Navigation agent - Next position: ", next_path_position, " Direction: ", direction)
			
			# If navigation seems stuck or giving bad directions, switch to direct movement
			if direction.length() < 0.1 or navigation_agent.is_target_unreachable():
				print("Robot: Navigation stuck/unreachable, switching to direct movement")
				use_direct_movement = true
				direction = global_position.direction_to(target_position)
		
		# Apply movement
		if direction.length() > 0.1:
			velocity = direction * SPEED
			move_and_slide()
			
			# Visual feedback
			animate_movement(direction)
			
			print("Robot: Moving - Position: ", global_position, " Target: ", target_position, " Distance: ", distance_to_target)
	
	# Check if close enough to target
	if distance_to_target <= 20:
		velocity = Vector2.ZERO
		print("Robot: Reached target area")

func animate_movement(direction: Vector2):
	"""Animate robot during movement"""
	if abs(direction.x) > abs(direction.y):
		sprite.rotation_degrees = 15 if direction.x > 0 else -15
	else:
		sprite.rotation_degrees = -15 if direction.y < 0 else 15

func update_movement_tracking(delta: float):
	"""Track if robot is stuck and handle state timeouts"""
	# Check if robot is stuck (hasn't moved much)
	var distance_moved = global_position.distance_to(last_position)
	if distance_moved < 5.0:  # Less than 5 pixels movement
		stuck_timer += delta
	else:
		stuck_timer = 0.0
		last_position = global_position
	
	# Handle being stuck
	if stuck_timer > STUCK_THRESHOLD:
		handle_stuck_robot()
		stuck_timer = 0.0
	
	# Handle state timeouts for moving states
	if current_state in [RobotState.MOVING_TO_RESOURCE, RobotState.MOVING_TO_HUB]:
		state_timeout += delta
		if state_timeout > STATE_TIMEOUT_LIMIT:
			print("Robot: State timeout, returning to idle")
			current_state = RobotState.IDLE
			state_timeout = 0.0

func handle_stuck_robot():
	"""Handle when robot gets stuck"""
	print("Robot: Detected stuck, switching to direct movement")
	use_direct_movement = true
	
	# Try to find alternative path by adding random offset
	if current_state in [RobotState.MOVING_TO_RESOURCE, RobotState.MOVING_TO_HUB]:
		var random_offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		var new_target = target_position + random_offset
		set_target_position(new_target)

func check_resource_arrival():
	"""Check if robot arrived at resource - IMPROVED"""
	if not current_resource_target or not is_instance_valid(current_resource_target):
		print("Robot: Resource target lost, returning to idle")
		current_state = RobotState.IDLE
		return
	
	var distance = global_position.distance_to(current_resource_target.global_position)
	
	if distance <= MINING_RANGE:
		print("Robot: Arrived at resource, starting mining")
		start_mining(current_resource_target)
		velocity = Vector2.ZERO
		sprite.rotation_degrees = 0
		state_timeout = 0.0

func check_hub_arrival():
	"""Check if robot arrived at hub - IMPROVED"""
	var distance = global_position.distance_to(hub_position)
	
	if distance <= 30:
		print("Robot: Arrived at hub, depositing resources")
		current_state = RobotState.DEPOSITING
		velocity = Vector2.ZERO
		sprite.rotation_degrees = 0
		state_timeout = 0.0

func start_mining(resource_node: Node2D):
	"""Start mining a resource - FIXED"""
	if not resource_node or not is_instance_valid(resource_node):
		print("Robot: Invalid resource target")
		current_state = RobotState.IDLE
		return
	
	current_state = RobotState.MINING
	current_resource_target = resource_node
	mining_timer = 0.0
	mining_progress_bar.visible = true
	mining_progress_bar.value = 0
	
	print("Robot: Starting to mine resource at ", resource_node.global_position)

func process_mining(delta: float):
	"""Process mining operation - FIXED"""
	if not current_resource_target or not is_instance_valid(current_resource_target):
		stop_mining()
		return
	
	# Check if still in range
	var distance = global_position.distance_to(current_resource_target.global_position)
	if distance > MINING_RANGE:
		print("Robot: Resource out of range, stopping mining")
		stop_mining()
		return
	
	mining_timer += delta
	var progress = mining_timer / MINING_TIME
	mining_progress_bar.value = progress * 100
	
	# Visual mining effect
	sprite.scale = Vector2(1.0 + sin(mining_timer * 10) * 0.1, 1.0)
	sprite.modulate = Color(1.0, 1.0 - progress * 0.3, 1.0 - progress * 0.3)
	
	if mining_timer >= MINING_TIME:
		complete_mining()

func complete_mining():
	"""Complete mining and collect resource - FIXED"""
	var resource_type = get_resource_type(current_resource_target)
	var amount = 1
	
	# Add to inventory
	resource_inventory[resource_type] += amount
	
	# Visual feedback
	show_collection_effect(resource_type)
	
	# Clean up
	mining_progress_bar.visible = false
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE
	
	# Notify resource manager if available
	if resource_manager and resource_manager.has_method("unregister_resource"):
		resource_manager.unregister_resource(current_resource_target)
	
	# Remove resource from scene
	current_resource_target.queue_free()
	current_resource_target = null
	
	print("Robot: Collected ", ResourceType.keys()[resource_type])
	print("Robot inventory: Crystal:", resource_inventory[ResourceType.CRYSTAL], 
		  " Metal:", resource_inventory[ResourceType.METAL], 
		  " Energy:", resource_inventory[ResourceType.ENERGY])
	
	resource_collected.emit(resource_type, amount)
	
	# FIXED: Different behavior for each phase
	if phase == RobotPhase.PICKUPABLE:
		# For pickupable robots, return to idle to look for nearby resources
		current_state = RobotState.IDLE
		print("Pickupable robot: Mining complete, looking for more nearby resources")
	elif phase == RobotPhase.AUTONOMOUS:
		# For autonomous robots, find next task (could be more resources or deposit)
		current_state = RobotState.IDLE
		print("Autonomous robot: Mining complete, finding next task")

func stop_mining():
	"""Stop mining process"""
	mining_timer = 0.0
	mining_progress_bar.visible = false
	current_resource_target = null
	current_state = RobotState.IDLE
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE

func get_resource_type(resource_node: Node2D) -> ResourceType:
	"""Get resource type from node"""
	if resource_node.has_meta("resource_type"):
		return resource_node.get_meta("resource_type")
	
	# Fallback: determine by name
	var name = resource_node.name.to_lower()
	if "crystal" in name:
		return ResourceType.CRYSTAL
	elif "metal" in name:
		return ResourceType.METAL
	elif "energy" in name:
		return ResourceType.ENERGY
	
	return ResourceType.CRYSTAL  # Default

func show_collection_effect(resource_type: ResourceType):
	"""Show visual effect when collecting resource"""
	var effect_color = Color.WHITE
	match resource_type:
		ResourceType.CRYSTAL:
			effect_color = Color.CYAN
		ResourceType.METAL:
			effect_color = Color.GRAY
		ResourceType.ENERGY:
			effect_color = Color.YELLOW
	
	var tween = create_tween()
	sprite.modulate = effect_color
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)

func deposit_resources():
	"""Deposit collected resources at hub"""
	var total_resources = get_total_resources()
	if total_resources == 0:
		current_state = RobotState.IDLE
		return
	
	print("Robot: Depositing ", total_resources, " resources")
	
	# Show deposit effect
	sprite.scale = Vector2(1.3, 1.3)
	sprite.modulate = Color.GOLD
	
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "scale", Vector2.ONE, 0.5)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.5)
	
	# Notify resource manager if available
	if resource_manager and resource_manager.has_method("deposit_resources"):
		resource_manager.deposit_resources(total_resources, resource_inventory.duplicate())
	
	# Clear inventory
	for type in ResourceType.values():
		resource_inventory[type] = 0
	
	# Notify systems
	resources_deposited.emit(total_resources)
	
	# Notify scene if it has a resource deposit method
	var scene = get_parent()
	if scene.has_method("on_resources_deposited"):
		scene.on_resources_deposited(total_resources)
	
	current_state = RobotState.IDLE

func get_total_resources() -> int:
	"""Get total resources in inventory"""
	var total = 0
	for type in ResourceType.values():
		total += resource_inventory[type]
	return total

func should_upgrade() -> bool:
	"""Check if robot should upgrade to autonomous - requires 1 of each material"""
	if phase != RobotPhase.PICKUPABLE:
		return false
	
	# Check if we have at least 1 of each resource type
	return (resource_inventory[ResourceType.CRYSTAL] >= 1 and 
			resource_inventory[ResourceType.METAL] >= 1 and 
			resource_inventory[ResourceType.ENERGY] >= 1)

func can_upgrade() -> bool:
	"""Public method to check if upgrade is available"""
	return upgrade_ready and phase == RobotPhase.PICKUPABLE

func upgrade_to_autonomous():
	"""Upgrade robot to autonomous phase"""
	if not should_upgrade():
		print("Robot: Cannot upgrade - missing required materials!")
		return
	
	print("Robot: Upgrading to autonomous!")
	
	# Change phase
	phase = RobotPhase.AUTONOMOUS
	current_state = RobotState.IDLE

	# ────── CLEAR ANY CARRIED RESOURCES ──────
	for resource_type in ResourceType.values():
		resource_inventory[resource_type] = 0
	print("Robot: Inventory cleared on upgrade to autonomous.")

	upgrade_ready = false
	upgrade_indicator.visible = false
	
	# Reset movement tracking
	stuck_timer = 0.0
	state_timeout = 0.0
	use_direct_movement = true  # Force direct movement initially for debugging
	target_position = Vector2.ZERO  # Clear any old target
	current_resource_target = null  # Clear any old resource target
	
	# Release from player if held
	if is_held_by_player:
		force_release_from_player()
	
	# Update appearance
	update_robot_appearance()
	
	# Show upgrade effect
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "scale", Vector2(2, 2), 0.3)
	tween.parallel().tween_property(sprite, "modulate", Color.GOLD, 0.3)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.3)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	# Emit signal
	phase_changed.emit(phase)
	
	print("Robot: Now autonomous! Will collect and deposit resources automatically.")
	print("Robot: Current position: ", global_position)
	print("Robot: Hub position: ", hub_position)
	
	# Immediately start looking for tasks
	call_deferred("debug_autonomous_status")

# Player interaction functions
func pick_up():
	"""Pick up robot (called by player)"""
	if phase == RobotPhase.PICKUPABLE and not is_held_by_player:
		is_held_by_player = true
		stop_mining()
		print("Robot: Picked up by player")

func drop_at_position(pos: Vector2):
	"""Drop robot at position (called by player)"""
	if is_held_by_player:
		is_held_by_player = false
		global_position = pos
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2.ONE
		current_state = RobotState.IDLE
		print("Robot: Dropped at ", pos)

func force_release_from_player():
	"""Force release from player (used during upgrade)"""
	is_held_by_player = false
	if player_reference and player_reference.has_method("release_robot"):
		player_reference.release_robot()

# Detection area callbacks
func _on_resource_detected(body: Node2D):
	"""Called when resource enters detection area"""
	if is_resource_node(body) and body not in global_resources:
		global_resources.append(body)

func _on_resource_lost(body: Node2D):
	"""Called when resource leaves detection area"""
	if body in global_resources:
		global_resources.erase(body)

# Utility functions
func set_hub_position(pos: Vector2):
	"""Set hub position"""
	hub_position = pos

func get_robot_status() -> Dictionary:
	"""Get robot status for UI"""
	return {
		"phase": RobotPhase.keys()[phase],
		"state": RobotState.keys()[current_state],
		"resources": resource_inventory,
		"total_resources": get_total_resources(),
		"position": global_position,
		"is_held": is_held_by_player,
		"upgrade_ready": upgrade_ready
	}

func debug_autonomous_status():
	"""Debug function to check autonomous robot status"""
	print("=== AUTONOMOUS ROBOT DEBUG ===")
	print("Phase: ", RobotPhase.keys()[phase])
	print("State: ", RobotState.keys()[current_state])
	print("Position: ", global_position)
	print("Target Position: ", target_position)
	print("Current Resource Target: ", current_resource_target)
	print("Hub Position: ", hub_position)
	print("Use Direct Movement: ", use_direct_movement)
	print("Resources in inventory: ", get_total_resources())
	
	# Test resource finding
	print("--- Testing Resource Finding ---")
	var found_resource = find_nearest_resource_autonomous()
	if found_resource:
		print("Found resource at: ", found_resource.global_position)
	else:
		print("No resources found!")
	
	print("==============================")

func get_debug_info() -> String:
	"""Get debug information"""
	return "Robot - Phase: %s, State: %s, Resources: %d, Upgrade: %s, Target: %s" % [
		RobotPhase.keys()[phase],
		RobotState.keys()[current_state],
		get_total_resources(),
		"Ready" if upgrade_ready else "Not Ready",
		str(target_position)
	]
