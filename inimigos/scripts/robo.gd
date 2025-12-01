extends CharacterBody2D

# --- CONFIGURAÇÕES ---
var speed_patrulha = 60
var speed_perseguir = 130
var gravity = 980

# --- VARIÁVEIS ---
var player_alvo: Node2D = null
var direction = 1
@onready var sprite = $AnimatedSprite2D
@onready var raycast_chao = $RayCast2D

func _physics_process(delta):
	# 1. Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Comportamento
	if player_alvo != null:
		_perseguir()
	else:
		_patrulhar()

	move_and_slide()

func _patrulhar():
	# Se bater na parede ou acabar o chão, volta
	if is_on_wall() or (is_on_floor() and not _tem_chao_frente()):
		direction *= -1
	
	velocity.x = direction * speed_patrulha
	sprite.play("walk")
	_virar_visual(direction)

func _perseguir():
	var dist = global_position.distance_to(player_alvo.global_position)
	var dir_player = sign(player_alvo.global_position.x - global_position.x)
	
	# --- CORREÇÃO DO ATAQUE ---
	# Diminuímos a distância de parada para 13 pixels.
	# Se a sua hitbox for maior que 13px, ele vai encostar e matar.
	if dist < 13:
		velocity.x = 0
		sprite.play("idle") 
		return

	# Verifica chão antes de andar
	_virar_visual(dir_player)
	
	if _tem_chao_frente():
		velocity.x = dir_player * speed_perseguir
		sprite.play("run")
	else:
		velocity.x = 0
		sprite.play("idle")

# --- AJUDANTES ---
func _tem_chao_frente() -> bool:
	raycast_chao.force_raycast_update()
	return raycast_chao.is_colliding()

func _virar_visual(dir):
	if dir == 0: return
	direction = dir
	sprite.flip_h = (dir == -1)
	
	# Vira o RayCast
	raycast_chao.position.x = abs(raycast_chao.position.x) * dir
	
	# Vira a Hitbox (Ataque) e o Detector (Visão)
	if has_node("hitbox"):
		$hitbox.position.x = abs($hitbox.position.x) * dir
	if has_node("detector"):
		$detector.position.x = abs($detector.position.x) * dir

# --- VISÃO ---
func _on_detector_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		player_alvo = body

func _on_detector_body_exited(body):
	if body == player_alvo:
		player_alvo = null

# --- ATAQUE (MATA O PLAYER) ---
func _on_hitbox_body_entered(body):
	# IMPORTANTE: Esse código só roda se a HITBOX encostar fisicamente no Player
	if body.is_in_group("player") or body.name == "Player":
		print("MATOU!")
		call_deferred("_reload")

func _reload():
	get_tree().reload_current_scene()
