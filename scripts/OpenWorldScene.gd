extends Node2D

# Global resource list
var global_resource_list = []

func _ready():
    # Populate the global resource list with resource positions
    for child in get_children():
        if child.name.begins_with("Resource"):
            global_resource_list.append(child.global_position)

    # Pass the resource list to the robot
    var robot = get_node("Robot")
    robot.global_resource_list = global_resource_list
