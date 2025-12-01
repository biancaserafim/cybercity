extends CharacterBody2D

# --- CONFIGURAÇÕES ---
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
var gravity = 980

# Define a altura limite. Se passar daqui, morre.
# Aumente esse número se sua fase for muito alta (profunda).
var altura_mortal = 500

@onready var sprite = $AnimatedSprite2D

func _ready():
	add_to_group("player")

func _physics_process(delta):
	# 1. Aplica a Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Pulo
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Movimento
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = (direction < 0)
		if is_on_floor():
			sprite.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			sprite.play("idle")

	# 4. Animação de Pulo
	if not is_on_floor():
		if sprite.sprite_frames.has_animation("jump"):
			sprite.play("jump")
			
	# --- 5. MORTE POR QUEDA (NOVIDADE) ---
	# Se a posição Y (vertical) for maior que o limite, reinicia.
	if global_position.y > altura_mortal:
		print("Caiu no abismo!")
		get_tree().reload_current_scene()

	move_and_slide()
