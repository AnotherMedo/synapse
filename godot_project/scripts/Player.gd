extends CharacterBody2D

# Player movement
const SPEED = 200.0
const CARRY_SPEED_MULTIPLIER = 0.8

# Robot interaction
var held_robot: Node2D = null
var nearby_robots: Array[Node2D] = []
var interaction_area: Area2D

# Visual components
var sprite: Sprite2D

# Input handling
var interaction_cooldown: float = 0.0

# Upgrade system
var robots_ready_for_upgrade: Array[Node2D] = []

func _ready():
	setup_player()
	setup_interaction_area()
	print("Player ready")

func setup_player():
	"""Initialize player components"""
	# Create sprite
	sprite = Sprite2D.new()
	add_child(sprite)
	create_player_sprite()

func setup_interaction_area():
	"""Setup area for robot interaction"""
	interaction_area = Area2D.new()
	add_child(interaction_area)
	
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 40.0
	collision_shape.shape = circle_shape
	interaction_area.add_child(collision_shape)
	
	interaction_area.body_entered.connect(_on_interaction_area_entered)
	interaction_area.body_exited.connect(_on_interaction_area_exited)

func create_player_sprite():
	"""Create player sprite"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Player body (green)
	draw_rectangle(image, 8, 12, 24, 28, Color(0.2, 0.8, 0.2, 1.0))
	
	# Player head (light green)
	draw_rectangle(image, 12, 6, 20, 14, Color(0.4, 0.9, 0.4, 1.0))
	
	# Eyes (black)
	image.set_pixel(14, 9, Color.BLACK)
	image.set_pixel(17, 9, Color.BLACK)
	
	# Arms (green)
	draw_rectangle(image, 6, 14, 8, 22, Color(0.2, 0.8, 0.2, 1.0))  # Left arm
	draw_rectangle(image, 24, 14, 26, 22, Color(0.2, 0.8, 0.2, 1.0))  # Right arm
	
	# Legs (dark green)
	draw_rectangle(image, 12, 28, 14, 32, Color(0.1, 0.6, 0.1, 1.0))  # Left leg
	draw_rectangle(image, 18, 28, 20, 32, Color(0.1, 0.6, 0.1, 1.0))  # Right leg
	
	# Add carrying indicator if holding robot
	if held_robot:
		draw_rectangle(image, 14, 4, 18, 8, Color(0.8, 0.8, 0.2, 1.0))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func draw_rectangle(image: Image, x1: int, y1: int, x2: int, y2: int, color: Color):
	"""Helper function to draw rectangles"""
	for x in range(x1, x2):
		for y in range(y1, y2):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)

func _physics_process(delta: float):
	"""Handle player movement and robot carrying"""
	# Handle cooldown
	if interaction_cooldown > 0:
		interaction_cooldown -= delta
	
	# Get input direction
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	
	# Apply movement
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		var current_speed = SPEED
		
		# Slower when carrying robot
		if held_robot:
			current_speed *= CARRY_SPEED_MULTIPLIER
		
		velocity = direction * current_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
	
	move_and_slide()
	
	# Handle robot carrying
	if held_robot and is_instance_valid(held_robot):
		update_carried_robot()

func update_carried_robot():
	"""Update position of carried robot"""
	if held_robot.has_method("follow_player"):
		# If robot has a follow_player method, use it
		var carry_position = global_position + Vector2(0, -30)
		held_robot.follow_player(carry_position)
	else:
		# Simple position updating
		held_robot.global_position = global_position + Vector2(0, -30)

func _input(event):
	"""Handle input events"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_P:
				if interaction_cooldown <= 0:
					interact_with_robot()
			KEY_U:
				if interaction_cooldown <= 0:
					try_upgrade_robot()

func interact_with_robot():
	"""Main interaction function"""
	if held_robot:
		drop_robot()
	else:
		pickup_robot()

func pickup_robot():
	"""Try to pick up a nearby robot"""
	# Clean up invalid references
	nearby_robots = nearby_robots.filter(func(robot): return is_instance_valid(robot))
	
	# Find pickupable robot
	for robot in nearby_robots:
		if robot.has_method("pick_up") and robot.phase == robot.RobotPhase.PICKUPABLE:
			if not robot.is_held_by_player:
				robot.pick_up()
				held_robot = robot
				robot.player_reference = self
				interaction_cooldown = 0.5
				
				# Connect to robot signals
				connect_robot_signals(robot)
				
				create_player_sprite()  # Update sprite
				print("Player: Picked up robot")
				show_hint("Carry robot to resources, press P to drop")
				return
	
	print("Player: No pickupable robot nearby")

func connect_robot_signals(robot: Node2D):
	"""Connect to robot's signals"""
	if robot.has_signal("phase_changed"):
		if not robot.phase_changed.is_connected(_on_robot_upgraded):
			robot.phase_changed.connect(_on_robot_upgraded)
	
	if robot.has_signal("upgrade_available"):
		if not robot.upgrade_available.is_connected(_on_robot_upgrade_available):
			robot.upgrade_available.connect(_on_robot_upgrade_available)
	
	if robot.has_signal("upgrade_unavailable"):
		if not robot.upgrade_unavailable.is_connected(_on_robot_upgrade_unavailable):
			robot.upgrade_unavailable.connect(_on_robot_upgrade_unavailable)

func disconnect_robot_signals(robot: Node2D):
	"""Disconnect from robot's signals"""
	if robot.has_signal("phase_changed"):
		if robot.phase_changed.is_connected(_on_robot_upgraded):
			robot.phase_changed.disconnect(_on_robot_upgraded)
	
	if robot.has_signal("upgrade_available"):
		if robot.upgrade_available.is_connected(_on_robot_upgrade_available):
			robot.upgrade_available.disconnect(_on_robot_upgrade_available)
	
	if robot.has_signal("upgrade_unavailable"):
		if robot.upgrade_unavailable.is_connected(_on_robot_upgrade_unavailable):
			robot.upgrade_unavailable.disconnect(_on_robot_upgrade_unavailable)

func drop_robot():
	"""Drop the carried robot"""
	if held_robot and is_instance_valid(held_robot):
		# Calculate drop position
		var drop_offset = Vector2(0, 40)  # Drop in front by default
		
		# If moving, drop in movement direction
		if velocity.length() > 10:
			drop_offset = velocity.normalized() * 50
		
		var drop_position = global_position + drop_offset
		
		# Disconnect signals
		disconnect_robot_signals(held_robot)
		
		# Drop robot
		held_robot.drop_at_position(drop_position)
		held_robot.player_reference = null
		held_robot = null
		interaction_cooldown = 0.5
		
		create_player_sprite()  # Update sprite
		print("Player: Dropped robot")
		show_hint("Robot will mine nearby resources")

func try_upgrade_robot():
	"""Try to upgrade a nearby robot or held robot"""
	var robot_to_upgrade: Node2D = null
	
	# Priority 1: Held robot
	if held_robot and is_instance_valid(held_robot):
		if held_robot.has_method("can_upgrade") and held_robot.can_upgrade():
			robot_to_upgrade = held_robot
	
	# Priority 2: Nearby robots ready for upgrade
	if not robot_to_upgrade:
		for robot in robots_ready_for_upgrade:
			if is_instance_valid(robot) and robot in nearby_robots:
				if robot.has_method("can_upgrade") and robot.can_upgrade():
					robot_to_upgrade = robot
					break
	
	# Attempt upgrade
	if robot_to_upgrade:
		print("Player: Upgrading robot to autonomous mode!")
		robot_to_upgrade.upgrade_to_autonomous()
		interaction_cooldown = 1.0
		show_hint("Robot upgraded! It will now work autonomously.")
	else:
		# Check if there are any robots that need materials
		var found_robot = false
		for robot in nearby_robots:
			if is_instance_valid(robot) and robot.phase == robot.RobotPhase.PICKUPABLE:
				found_robot = true
				var crystal = robot.resource_inventory[robot.ResourceType.CRYSTAL]
				var metal = robot.resource_inventory[robot.ResourceType.METAL]
				var energy = robot.resource_inventory[robot.ResourceType.ENERGY]
				
				print("Player: Robot needs materials for upgrade:")
				print("  Crystal: %d/1, Metal: %d/1, Energy: %d/1" % [crystal, metal, energy])
				
				var missing = []
				if crystal < 1: missing.append("Crystal")
				if metal < 1: missing.append("Metal")
				if energy < 1: missing.append("Energy")
				
				if missing.size() > 0:
					show_hint("Robot needs: " + ", ".join(missing))
				break
		
		if not found_robot:
			show_hint("No robots available for upgrade")

func _on_robot_upgraded(new_phase):
	"""Called when carried robot upgrades"""
	# Get enum reference from held robot or nearby robot
	var robot_phase_enum = null
	if held_robot and is_instance_valid(held_robot):
		robot_phase_enum = held_robot.RobotPhase
	else:
		# Try to get enum from any nearby robot
		for robot in nearby_robots:
			if is_instance_valid(robot) and robot.has_method("get_robot_status"):
				robot_phase_enum = robot.RobotPhase
				break
	
	if robot_phase_enum and new_phase == robot_phase_enum.AUTONOMOUS:
		print("Player: Robot upgraded! Auto-releasing...")
		force_release_robot()
		show_hint("Robot upgraded to autonomous mode!")

func _on_robot_upgrade_available(robot: Node2D):
	"""Called when a robot becomes ready for upgrade"""
	if robot not in robots_ready_for_upgrade:
		robots_ready_for_upgrade.append(robot)
	
	if robot == held_robot:
		show_hint("Robot ready for upgrade! Press U to upgrade to autonomous mode.")
	elif robot in nearby_robots:
		show_hint("Nearby robot ready for upgrade! Press U to upgrade.")

func _on_robot_upgrade_unavailable(robot: Node2D):
	"""Called when a robot is no longer ready for upgrade"""
	if robot in robots_ready_for_upgrade:
		robots_ready_for_upgrade.erase(robot)

func force_release_robot():
	"""Force release robot (used when robot upgrades)"""
	if held_robot and is_instance_valid(held_robot):
		var release_position = global_position + Vector2(50, 0)
		
		# Disconnect signals
		disconnect_robot_signals(held_robot)
		
		held_robot.drop_at_position(release_position)
		held_robot.player_reference = null
		held_robot = null
		interaction_cooldown = 1.0
		
		create_player_sprite()

func _on_interaction_area_entered(body: Node2D):
	"""Called when something enters interaction area"""
	if body.name == "Robot" and body not in nearby_robots:
		nearby_robots.append(body)
		print("Player: Robot nearby")
		
		# Connect to robot signals for upgrade notifications
		connect_robot_signals(body)
		
		# Show context hint
		if held_robot:
			show_hint("Press P to drop robot")
		elif body.has_method("pick_up") and body.phase == body.RobotPhase.PICKUPABLE:
			if body.has_method("can_upgrade") and body.can_upgrade():
				show_hint("Press P to pick up robot, U to upgrade")
			else:
				show_hint("Press P to pick up robot")

func _on_interaction_area_exited(body: Node2D):
	"""Called when something leaves interaction area"""
	if body in nearby_robots:
		nearby_robots.erase(body)
		
		# Disconnect signals
		disconnect_robot_signals(body)
		
		# Remove from upgrade list
		if body in robots_ready_for_upgrade:
			robots_ready_for_upgrade.erase(body)

func show_hint(text: String, duration: float = 2.0):
	"""Show interaction hint"""
	print("HINT: ", text)
	# You can implement a proper UI hint system here
	# For now, just print to console

# Utility functions
func is_carrying_robot() -> bool:
	"""Check if player is carrying a robot"""
	return held_robot != null and is_instance_valid(held_robot)

func get_carried_robot() -> Node2D:
	"""Get the carried robot"""
	return held_robot if is_instance_valid(held_robot) else null

func release_robot():
	"""Release robot (called by robot when upgrading)"""
	if held_robot:
		held_robot = null
		create_player_sprite()
