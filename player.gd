extends CharacterBody2D

const SPEED := 200.0
const JUMP_FORCE := -350.0
const GRAVITY := 900.0
const LIMITE_MORTE_Y := 1200   # ajuste para seu mapa

@onready var anim := $AnimatedSprite2D

var morto := false

func _ready():
	add_to_group("player")

func _physics_process(delta):
	if morto:
		return

	# GRAVIDADE
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	# MOVIMENTO HORIZONTAL
	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = 0

	# PULO
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_FORCE

	move_and_slide()

	# ---- MORTE POR QUEDA (SEM ANIMAÇÃO) ----
	if global_position.y > LIMITE_MORTE_Y:
		reiniciar_fase()
		return

	# ANIMAÇÕES NORMAIS
	if not is_on_floor():
		anim.play("jump")
	elif direction != 0:
		anim.play("walk")
	else:
		anim.play("idle")

	# DIREÇÃO DO SPRITE
	if velocity.x > 0:
		anim.flip_h = false
	elif velocity.x < 0:
		anim.flip_h = true

# ---- MORTE POR INIMIGO (COM ANIMAÇÃO) ----
func morrer_por_inimigo():
	if morto:
		return

	morto = true
	velocity = Vector2.ZERO
	anim.play("death")

	await get_tree().create_timer(0.25).timeout
	get_tree().reload_current_scene()

# ---- MORTE POR QUEDA (INSTANTÂNEA) ----
func reiniciar_fase():
	if morto:
		return

	morto = true
	get_tree().reload_current_scene()
