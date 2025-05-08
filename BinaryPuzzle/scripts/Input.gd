extends Node

const Output = preload("res://BinaryPuzzle/scripts/Output.gd")
const Input_ = preload("res://BinaryPuzzle/scripts/Input.gd")

static var selectedInput: Input_

var current_val: bool
var connected_output: Output

var is_selected_by_player: bool

signal recieve(message:Output.Message)

func _ready():
	self.input_event.connect(_on_CollisionShape2D_input_event)

func _on_CollisionShape2D_input_event(viewport, event, shape_idx):
	if (event is InputEventMouseButton and 
	event.button_index == MOUSE_BUTTON_RIGHT and
	event.pressed):
			selectedInput = self
			
			if Output.selected_output != null:
				selectedInput.disconnect_output()
				Output.selected_output.disconnect_input()
				
				#call on input first, so output can give it's current value
				selectedInput.connect_to_output(Output.selected_output)
				Output.selected_output.connect_to_input(selectedInput)
				
				selectedInput = null
				Output.selected_output = null

func connect_to_output(output: Output):
	output.send.connect(recieve_func)
	connected_output = output
	
func disconnect_output():
	if !connected_output:
		return

	# we use this temp to avoid having the output and input 
	# call eachother to disconnect in a loop
	var output = connected_output
	
	connected_output.send.disconnect(recieve_func)
	connected_output = null
	
	output.disconnect_input()
	
func recieve_func(message: Output.Message):
	current_val = message.sent_val
	recieve.emit(message)
	
	print("recieved ", message.sent_val)
	
