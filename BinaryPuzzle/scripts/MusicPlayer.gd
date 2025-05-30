extends AudioStreamPlayer2D

func _ready():
	if not playing:
		play()
