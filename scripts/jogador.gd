extends CharacterBody2D

enum Estado { PARADO, ANDANDO, PULANDO, FERIDO, ATACANDO, MORTO }

@export var velocidade: float = 150.0
@export var forca_do_pulo: float = -400.0
@export var vida_maxima: int = 5
@export var tempo_hurt: float = 0.4
@export var dano_do_golpe: int = 2
@export var quadro_do_golpe: int = 3

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_golpe: Area2D = $AreaGolpe

var vida: int
var status: Estado = Estado.PARADO
var direcao: float = 0.0
var tempo_no_hurt: float = 0.0
var golpe_aplicado: bool = false


func _ready() -> void:
	_configurar_animacoes()
	vida = vida_maxima
	go_to_idle_state()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		Estado.PARADO:
			idle_state()
		Estado.ANDANDO:
			walk_state()
		Estado.PULANDO:
			jump_state()
		Estado.FERIDO:
			hurt_state()
		Estado.ATACANDO:
			attack_state()
		Estado.MORTO:
			pass

	move_and_slide()


func levar_dano(quantidade: int) -> void:
	if status == Estado.FERIDO or status == Estado.MORTO:
		return

	vida -= quantidade
	print("vida: ", vida)
	if vida <= 0:
		morrer()
		return

	go_to_hurt_state()


func morrer() -> void:
	status = Estado.MORTO
	anim.modulate = Color.WHITE
	anim.play(&"death")
	velocity = Vector2.ZERO
	area_golpe.monitoring = false
	set_physics_process(false)


func go_to_idle_state() -> void:
	status = Estado.PARADO
	anim.modulate = Color.WHITE
	anim.play(&"idle")
	velocity.x = 0.0


func idle_state() -> void:
	_atualizar_direcao()
	velocity.x = move_toward(velocity.x, 0.0, velocidade)

	if Input.is_action_just_pressed(&"attack"):
		go_to_attack_state()
		return
	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		go_to_jump_state()
		return
	if not is_zero_approx(direcao):
		go_to_walk_state()


func go_to_walk_state() -> void:
	status = Estado.ANDANDO
	anim.play(&"walk")


func walk_state() -> void:
	_atualizar_direcao()
	velocity.x = direcao * velocidade

	if Input.is_action_just_pressed(&"attack"):
		go_to_attack_state()
		return
	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		go_to_jump_state()
		return
	if is_zero_approx(direcao):
		go_to_idle_state()


func go_to_jump_state() -> void:
	status = Estado.PULANDO
	velocity.y = forca_do_pulo
	anim.play(&"jump")


func jump_state() -> void:
	_atualizar_direcao()
	velocity.x = direcao * velocidade

	if is_on_floor() and velocity.y >= 0.0:
		if is_zero_approx(direcao):
			go_to_idle_state()
		else:
			go_to_walk_state()


func go_to_hurt_state() -> void:
	status = Estado.FERIDO
	anim.play(&"hurt")
	anim.modulate = Color(1.0, 0.4, 0.4)
	velocity.x = 0.0
	tempo_no_hurt = 0.0
	area_golpe.monitoring = false


func hurt_state() -> void:
	tempo_no_hurt += get_physics_process_delta_time()
	if tempo_no_hurt >= tempo_hurt:
		if is_on_floor():
			go_to_idle_state()
		else:
			status = Estado.PULANDO
			anim.modulate = Color.WHITE
			anim.play(&"jump")


func go_to_attack_state() -> void:
	status = Estado.ATACANDO
	anim.play(&"attack")
	velocity.x = 0.0
	golpe_aplicado = false
	area_golpe.monitoring = true


func attack_state() -> void:
	if not golpe_aplicado and anim.frame >= quadro_do_golpe:
		golpe_aplicado = true
		for corpo in area_golpe.get_overlapping_bodies():
			if corpo != self and corpo.has_method(&"levar_dano"):
				corpo.levar_dano(dano_do_golpe)

	if not anim.is_playing():
		area_golpe.monitoring = false
		go_to_idle_state()


func _atualizar_direcao() -> void:
	direcao = Input.get_axis(&"move_left", &"move_right")
	if direcao > 0.0:
		anim.flip_h = false
		area_golpe.position.x = abs(area_golpe.position.x)
	elif direcao < 0.0:
		anim.flip_h = true
		area_golpe.position.x = -abs(area_golpe.position.x)


func _configurar_animacoes() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_adicionar_animacao(frames, &"idle", "idle.png", 8, 8.0, true)
	_adicionar_animacao(frames, &"walk", "walk.png", 8, 8.0, true)
	_adicionar_animacao(frames, &"jump", "jump.png", 7, 17.0, false)
	_adicionar_animacao(frames, &"attack", "attack.png", 7, 10.0, false)
	_adicionar_animacao(frames, &"hurt", "hurt.png", 7, 14.0, false)
	_adicionar_animacao(frames, &"death", "death.png", 7, 10.0, false)
	anim.sprite_frames = frames


func _adicionar_animacao(
	frames: SpriteFrames,
	nome: StringName,
	arquivo: String,
	quantidade: int,
	fps: float,
	loop: bool
) -> void:
	frames.add_animation(nome)
	frames.set_animation_speed(nome, fps)
	frames.set_animation_loop(nome, loop)
	var textura := load("res://assets/combate/sobrevivente/" + arquivo) as Texture2D
	for indice in quantidade:
		var quadro := AtlasTexture.new()
		quadro.atlas = textura
		quadro.region = Rect2(indice * 68, 0, 68, 64)
		frames.add_frame(nome, quadro)
