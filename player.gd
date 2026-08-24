extends CharacterBody2D

@export var speed: float = 150.0
@export var jump_force: float = -300.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Pulo
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	# Movimento horizontal
	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

	update_animation(direction)


func update_animation(direction: float) -> void:
	if not is_on_floor():
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("fall")

	elif direction != 0:
		sprite.play("walk")

	else:
		sprite.play("idle")

	if direction > 0:
		sprite.flip_h = false
	elif direction < 0:
		sprite.flip_h = true
