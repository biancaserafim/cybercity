extends CharacterBody2D

const SPEED := 60.0
const GRAVITY := 900.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var head: Area2D = $head
@onready var corpo: Area2D = $Corpo
@onready var collision: CollisionShape2D = $collision

var direcao := 1
var morto := false

func _ready():
	if head:
		head.body_entered.connect(_on_head_body_entered)
	else:
		push_error("❌ Nó 'head' não encontrado!")

	if corpo:
		corpo.body_entered.connect(_on_corpo_body_entered)
	else:
		push_error("❌ Nó 'Corpo' não encontrado!")

func _physics_process(delta):
	if morto:
		return

	velocity.y += GRAVITY * delta
	velocity.x = direcao * SPEED

	move_and_slide()

	# Vira ao bater na parede
	if is_on_wall():
		direcao *= -1

	anim.flip_h = direcao < 0

	if anim.animation != "walk":
		anim.play("walk")


# =========================
# PLAYER MATA O INIMIGO (CABEÇA)
# =========================
func _on_head_body_entered(body):
	if morto:
		return

	if body.is_in_group("player"):
		morrer()

		if "velocity" in body:
			body.velocity.y = -200


# =========================
# INIMIGO MATA O PLAYER (CORPO)
# =========================
func _on_corpo_body_entered(body):
	if morto:
		return

	if body.is_in_group("player"):
		body.morrer_por_inimigo()


# =========================
# MORTE DO INIMIGO (100% GARANTIDA)
# =========================
func morrer():
	if morto:
		return

	morto = true
	velocity = Vector2.ZERO

	if collision:
		collision.disabled = true
	if head:
		head.monitoring = false
	if corpo:
		corpo.monitoring = false

	anim.stop()
	anim.play("death")

	# AQUI VOCÊ CONTROLA O TEMPO DA ANIMAÇÃO
	await get_tree().create_timer(1.0).timeout   # ← ajuste aqui

	queue_free()
