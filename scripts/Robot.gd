extends KinematicBody2D

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
var path = []
var current_path_index = 0

# Signal for detecting resources
signal resource_detected(resource)

# Variables for player interaction
var is_held_by_player = false
var player_node = null

# Variable to track required resources for autonomous phase
var required_resources = 10

# Functions
func _ready():
    # Initialize the robot
    $Area2D.connect("body_entered", self, "_on_body_entered")
    $ResourceDetector.connect("timeout", self, "_check_for_resources")

    if resource_count >= required_resources:
        _upgrade_to_autonomous()

func set_target_position(position: Vector2):
    # Set the target position for the robot
    target_position = position

func move_to_target(delta, navigation: Navigation2D):
    # Move the robot towards the target position in autonomous phase
    if phase == RobotPhase.AUTONOMOUS:
        if path.size() == 0 or current_path_index >= path.size():
            calculate_path(navigation, target_position)
        follow_path(delta)

func calculate_path(navigation: Navigation2D, destination: Vector2):
    # Calculate a path to the destination using Navigation2D
    path = navigation.get_simple_path(global_position, destination, false)
    current_path_index = 0

func follow_path(delta):
    # Follow the calculated path
    if path.size() > 0 and current_path_index < path.size():
        var next_point = path[current_path_index]
        var direction = (next_point - global_position).normalized()
        var velocity = direction * SPEED * delta

        if global_position.distance_to(next_point) < 5:
            current_path_index += 1
        else:
            move_and_slide(velocity)

func mine_resource():
    # Increment the resource count when mining
    resource_count += 1
    if resource_count >= required_resources and phase == RobotPhase.PICKUPABLE:
        _upgrade_to_autonomous()

func deposit_resource():
    # Reset the resource count when depositing
    var count_temp=resource_count
    resource_count = 0
    return count_temp

func find_resource():
    # Find the nearest resource from the global list
    if global_resource_list.size() > 0:
        target_position = global_resource_list[0]

func switch_to_autonomous():
    # Switch the robot to autonomous phase
    phase = RobotPhase.AUTONOMOUS

func switch_to_pickupable():
    # Switch the robot to pickupable phase
    phase = RobotPhase.PICKUPABLE

func _on_body_entered(body):
    # Detect when a resource enters the Area2D
    if body.name == "Resource":
        emit_signal("resource_detected", body)
    # Detect when the player interacts with the robot
    if body.name == "Player" and phase == RobotPhase.PICKUPABLE:
        player_node = body

func _check_for_resources():
    # Periodically check for resources in the area
    for body in $Area2D.get_overlapping_bodies():
        if body.name == "Resource":
            emit_signal("resource_detected", body)
            break

func pick_up():
    # Allow the player to pick up the robot
    if phase == RobotPhase.PICKUPABLE and player_node:
        is_held_by_player = true
        hide()  # Hide the robot while being carried

func drop_at_position(position: Vector2):
    # Drop the robot at a specified position
    if is_held_by_player:
        is_held_by_player = false
        global_position = position
        show()  # Show the robot after being dropped

func _upgrade_to_autonomous():
    # Upgrade the robot to the autonomous phase
    switch_to_autonomous()
    print("Robot upgraded to autonomous phase.")

func _physics_process(delta):
    # Handle autonomous movement
    if phase == RobotPhase.AUTONOMOUS:
        move_to_target(delta, get_parent().get_node("Navigation2D"))
        if global_position.distance_to(target_position) < 5:
            mine_resource()
            global_resource_list.erase(target_position)  # Remove resource from list
            find_resource()  # Find the next resource
