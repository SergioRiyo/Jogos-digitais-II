extends CharacterBody2D

@export var speed: float = 150.0
@export var jump_force: float = -300.0
@export var max_jumps: int = 2
@export_range(0.2, 1.0, 0.05) var crouch_height_ratio: float = 0.6

enum Estado { PARADO, ANDANDO, PULANDO, AGACHADO }

var estado: Estado = Estado.PARADO
var pulos_feitos: int = 0
var direcao: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colisor: CollisionShape2D = $Shape

var tamanho_colisor_normal: Vector2
var posicao_colisor_normal: Vector2
var tamanho_colisor_agachado: Vector2
var posicao_colisor_agachado: Vector2
var escala_sprite_normal: Vector2
var posicao_sprite_normal: Vector2


func _ready() -> void:
	colisor.shape = colisor.shape.duplicate() as Shape2D
	var forma := colisor.shape as RectangleShape2D

	tamanho_colisor_normal = forma.size
	posicao_colisor_normal = colisor.position
	tamanho_colisor_agachado = Vector2(
		tamanho_colisor_normal.x,
		tamanho_colisor_normal.y * crouch_height_ratio
	)
	posicao_colisor_agachado = posicao_colisor_normal + Vector2(
		0.0,
		(tamanho_colisor_normal.y - tamanho_colisor_agachado.y) / 2.0
	)
	escala_sprite_normal = sprite.scale
	posicao_sprite_normal = sprite.position

	entrar_parado()

func _physics_process(delta: float) -> void:
	direcao = Input.get_axis("move_left", "move_right")
	virar_sprite(direcao)

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		pulos_feitos = 0

	match estado:
		Estado.PARADO:
			processar_parado(delta)
		Estado.ANDANDO:
			processar_andando(delta)
		Estado.PULANDO:
			processar_pulando(delta)
		Estado.AGACHADO:
			processar_agachado(delta)


	move_and_slide()
	atualizar_estado_de_chao()


func mudar_estado(novo_estado: Estado) -> void:
	if estado == novo_estado:
		return

	estado = novo_estado

	match estado:
		Estado.PARADO:
			entrar_parado()
		Estado.ANDANDO:
			entrar_andando()
		Estado.PULANDO:
			entrar_pulando()
		Estado.AGACHADO:
			entrar_agachado()


func entrar_parado() -> void:
	usar_colisor_normal()
	tocar_animacao("idle")


func processar_parado(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, speed)

	if tentar_pular():
		return

	if Input.is_action_pressed("duck"):
		mudar_estado(Estado.AGACHADO)
		return

	if not is_zero_approx(direcao):
		velocity.x = direcao * speed
		mudar_estado(Estado.ANDANDO)


func entrar_andando() -> void:
	usar_colisor_normal()
	tocar_animacao("walk")


func processar_andando(_delta: float) -> void:
	if tentar_pular():
		return

	if Input.is_action_pressed("duck") or is_zero_approx(direcao):
		velocity.x = move_toward(velocity.x, 0.0, speed)
		mudar_estado(Estado.PARADO)
		return

	velocity.x = direcao * speed


func entrar_pulando() -> void:
	usar_colisor_normal()
	tocar_animacao("jump")


func processar_pulando(_delta: float) -> void:
	tentar_pular()

	if not is_zero_approx(direcao):
		velocity.x = direcao * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)

	if velocity.y > 0.0 and sprite.sprite_frames.has_animation("fall"):
		tocar_animacao("fall")
	elif velocity.y <= 0.0:
		tocar_animacao("jump")


func entrar_agachado() -> void:
	usar_colisor_agachado()

	if sprite.sprite_frames.has_animation("duck"):
		tocar_animacao("duck")
	else:
		tocar_animacao("idle")
		sprite.scale = Vector2(escala_sprite_normal.x, escala_sprite_normal.y * crouch_height_ratio)
		sprite.position = posicao_sprite_normal + Vector2(
			0.0,
			(tamanho_colisor_normal.y - tamanho_colisor_agachado.y) / 2.0
		)


func processar_agachado(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, speed)

	if not Input.is_action_pressed("duck"):
		mudar_estado(Estado.PARADO)


func tentar_pular() -> bool:
	if not Input.is_action_just_pressed("jump"):
		return false

	if pulos_feitos >= max_jumps:
		return false

	velocity.y = jump_force
	pulos_feitos += 1
	tocar_animacao("jump")
	mudar_estado(Estado.PULANDO)
	return true


func atualizar_estado_de_chao() -> void:
	if is_on_floor():
		pulos_feitos = 0

		if estado == Estado.PULANDO:
			if is_zero_approx(direcao):
				mudar_estado(Estado.PARADO)
			else:
				mudar_estado(Estado.ANDANDO)
	elif estado != Estado.PULANDO:
		mudar_estado(Estado.PULANDO)


func usar_colisor_normal() -> void:
	var forma := colisor.shape as RectangleShape2D
	forma.size = tamanho_colisor_normal
	colisor.position = posicao_colisor_normal
	sprite.scale = escala_sprite_normal
	sprite.position = posicao_sprite_normal


func usar_colisor_agachado() -> void:
	var forma := colisor.shape as RectangleShape2D
	forma.size = tamanho_colisor_agachado
	colisor.position = posicao_colisor_agachado


func tocar_animacao(nome: StringName) -> void:
	if sprite.animation != nome or not sprite.is_playing():
		sprite.play(nome)


func virar_sprite(valor_direcao: float) -> void:
	if valor_direcao > 0.0:
		sprite.flip_h = false
	elif valor_direcao < 0.0:
		sprite.flip_h = true
