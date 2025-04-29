extends CharacterBody2D

@export var speed := 100.0

func _physics_process(delta):
	var velocity = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1

	velocity = velocity.normalized() * speed

	if velocity != Vector2.ZERO:
		if abs(velocity.x) > abs(velocity.y):
			$AnimatedSprite2D.play("right" if velocity.x > 0 else "left")
		else:
			$AnimatedSprite2D.play("down" if velocity.y > 0 else "up")
	else:
		$AnimatedSprite2D.stop()

	velocity = move_and_slide()
