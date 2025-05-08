extends Node2D

const Input_ = preload("res://BinaryPuzzle/scripts/Input.gd")
const Output = preload("res://BinaryPuzzle/scripts/Output.gd")

static var selected_output: Output

signal send(message: Message)

var current_val: bool

var connected_input: Input_

var wire_mesh_instance: MeshInstance2D

const false_color: Color = Color(.75,0,0,1)
const true_color: Color = Color(0,.75,0,1)

var just_connected = false

class Message:
	var sent_val: bool
	var sender_id: int

func _ready():
	wire_mesh_instance = $"MeshInstance2D"
	
	send.connect(
		func(message:Message): 
			
			if (message.sender_id == get_output_id()):
				if just_connected:
					just_connected = false
				else:
					disconnect_input()
		
			current_val = message.sent_val
			if message.sent_val:
				wire_mesh_instance.modulate = true_color
			else:
				wire_mesh_instance.modulate = false_color
	)
	self.input_event.connect(_on_CollisionShape2D_input_event)

func _on_CollisionShape2D_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_RIGHT and
		event.pressed):
			selected_output = self
			
			if Input_.selectedInput != null:
				Input_.selectedInput.disconnect_output()
				selected_output.disconnect_input()
				
				#needs to be called on input first
				#so output can send out it's current value
				Input_.selectedInput.connect_to_output(selected_output)
				selected_output.connect_to_input(Input_.selectedInput)
				
				selected_output = null
				Input_.selectedInput = null

func create_wire_array_mesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var halfway = (self.global_position.y + connected_input.global_position.y)/2
	
	var halfway_compensation = 1
	
	if (self.global_position.x < connected_input.global_position.x):
		halfway_compensation *= -1
	elif (self.global_position.x == connected_input.global_position.x):
		halfway_compensation = 0
	
	# Vertices of a simple triangle
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		self.global_position + Vector2(-1,0),
		self.global_position + Vector2(1,0),
		Vector2(self.global_position.x-1,halfway - halfway_compensation),
		Vector2(self.global_position.x+1,halfway + halfway_compensation),
		Vector2(connected_input.global_position.x-1,halfway - halfway_compensation),
		Vector2(connected_input.global_position.x+1,halfway + halfway_compensation),
		connected_input.global_position + Vector2(-1,0),
		connected_input.global_position + Vector2(1,0),
	])
	
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(
		[0,1,2,
		1,3,2,
		3,2,4,
		4,5,3,
		4,5,6,
		6,7,5])
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	
	return mesh

func connect_to_input(input: Input_):
	connected_input = input
	just_connected = true
	
	#the wire mesh instance needs to be put at zero so the vertices are relative to
	#Vec(0,0) and not the position of the meshinstance
	wire_mesh_instance.global_position = Vector2.ZERO
	wire_mesh_instance.mesh = create_wire_array_mesh()
	
	#we need to keep the new input up to date
	#this also means the input should connect to the ouput first
	var sent_message = Message.new()
	sent_message.sent_val = current_val
	sent_message.sender_id = get_output_id()
	send.emit(sent_message)
	
func disconnect_input():
	wire_mesh_instance.mesh = null
	
	if !connected_input:
		return
	
	var input = connected_input
	connected_input = null
	
	input.disconnect_output()
	
func get_output_id() -> int:
	return position.x * 100 + position.y
	
