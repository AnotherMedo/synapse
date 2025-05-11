extends CharacterBody2D

# Robot Phases
enum RobotPhase { PICKUPABLE, AUTONOMOUS }

# Variables
var phase = RobotPhase.PICKUPABLE
var resource_count = 0
var target_position = Vector2.ZERO
var global_resource_list = []

# Constants
const SPEED = 100

# Pathfinding variables
var path: Array = []
var current_path_index: int = 0

# Signal for detecting resources
signal resource_detected(resource)

# Variables for player interaction
var is_held_by_player: bool = false
var player_node: Node = null

# Variable to track required resources for autonomous phase
var required_resources: int = 10

func _ready():
	# Initialize the robot
	$Area2D.body_entered.connect(_on_body_entered)
	$ResourceDetector.timeout.connect(_check_for_resources)

	if resource_count >= required_resources:
		_upgrade_to_autonomous()

func set_target_position(position: Vector2) -> void:
	# Set the target position for the robot
	target_position = position

func move_to_target(delta: float, navigation: Node) -> void:
	# Move the robot towards the target position in autonomous phase
	if phase == RobotPhase.AUTONOMOUS:
		if path.size() == 0 or current_path_index >= path.size():
			calculate_path(navigation, target_position)
		follow_path(delta)

func calculate_path(navigation: Node, destination: Vector2) -> void:
	# Calculate a path to the destination using Navigation2D
	path = navigation.get_simple_path(global_position, destination, false)
	current_path_index = 0

func follow_path(delta: float) -> void:
	# Follow the calculated path
	if path.size() > 0 and current_path_index < path.size():
		var next_point: Vector2 = path[current_path_index]
		var direction: Vector2 = (next_point - global_position).normalized()
		# Assign to the built-in velocity property...
		velocity = direction * SPEED
		if global_position.distance_to(next_point) < 5:
			current_path_index += 1
		else:
			move_and_slide()

func mine_resource() -> void:
	# Increment the resource count when mining
	resource_count += 1
	if resource_count >= required_resources and phase == RobotPhase.PICKUPABLE:
		_upgrade_to_autonomous()

func deposit_resource() -> int:
	# Reset the resource count when depositing
	var count_temp: int = resource_count
	resource_count = 0
	return count_temp

func find_resource() -> void:
	# Find the nearest resource from the global list
	if global_resource_list.size() > 0:
		target_position = global_resource_list[0]

func switch_to_autonomous() -> void:
	# Switch the robot to autonomous phase
	phase = RobotPhase.AUTONOMOUS

func switch_to_pickupable() -> void:
	# Switch the robot to pickupable phase
	phase = RobotPhase.PICKUPABLE

func _on_body_entered(body: Node) -> void:
	# Detect when a resource enters the Area2D
	if body.name == "Resource":
		emit_signal("resource_detected", body)
	# Detect when the player interacts with the robot
	if body.name == "Player" and phase == RobotPhase.PICKUPABLE:
		player_node = body

func _check_for_resources() -> void:
	# Periodically check for resources in the area
	pass

func pick_up() -> void:
	# Allow the player to pick up the robot
	if phase == RobotPhase.PICKUPABLE and player_node:
		is_held_by_player = true
		hide()  # Hide the robot while being carried

func drop_at_position(position: Vector2) -> void:
	# Drop the robot at a specified position
	if is_held_by_player:
		is_held_by_player = false
		global_position = position
		show()  # Show the robot after being dropped

func _upgrade_to_autonomous() -> void:
	# Upgrade the robot to the autonomous phase
	switch_to_autonomous()
	print("Robot upgraded to autonomous phase.")

func _physics_process(delta: float) -> void:
	# Handle autonomous movement
	if phase == RobotPhase.AUTONOMOUS:
		move_to_target(delta, get_parent().get_node("Navigation2D"))
		if global_position.distance_to(target_position) < 5:
			mine_resource()
			global_resource_list.erase(target_position)  # Remove resource from list
			find_resource()  # Find the next resource
