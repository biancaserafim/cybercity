extends CharacterBody2D

# --- CONFIGURAÇÕES ---
var speed_patrulha = 60
var speed_perseguir = 130
var gravity = 980
var distancia_desistir = 500 

# --- VARIÁVEIS ---
var player_alvo: Node2D = null
var direction = 1

@onready var sprite = $AnimatedSprite2D
@onready var raycast_chao = $RayCast2D
# Se usar Godot 4, o timer é útil para evitar spam de prints, mas opcional.

func _physics_process(delta):
	# 1. Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Sistema de Memória
	if player_alvo != null:
		# Verifica se o alvo ainda é válido (pode ter morrido/deletado)
		if not is_instance_valid(player_alvo):
			player_alvo = null
		else:
			var distancia_real = global_position.distance_to(player_alvo.global_position)
			if distancia_real > distancia_desistir:
				player_alvo = null
				# Opcional: print("Player fugiu. Voltando a patrulhar.")

	# 3. Define o que fazer
	if player_alvo != null:
		_comportamento_perseguir()
	else:
		_comportamento_patrulha()

	move_and_slide()

# --- PATRULHA ---
func _comportamento_patrulha():
	# Se bater na parede ou o chão acabar, vira
	if is_on_wall() or (is_on_floor() and not _tem_chao_frente()):
		direction *= -1
	
	velocity.x = direction * speed_patrulha
	sprite.play("walk")
	_virar_visual(direction)

# --- PERSEGUIR ---
func _comportamento_perseguir():
	# Proteção extra caso o player suma
	if not is_instance_valid(player_alvo): return

	var dist = global_position.distance_to(player_alvo.global_position)
	var dir_player = sign(player_alvo.global_position.x - global_position.x)
	
	# Se o dir_player for 0 (estão na mesma posição x), assume a direção atual
	if dir_player == 0: dir_player = direction

	# ZONA DE ATAQUE (Para e bate)
	if dist < 20:
		velocity.x = 0
		sprite.play("idle") # Troque por "attack" se tiver
		_virar_visual(dir_player)
		return

	# MOVIMENTO
	_virar_visual(dir_player)
	
	if _tem_chao_frente():
		velocity.x = dir_player * speed_perseguir
		sprite.play("run")
	else:
		# Chegou na borda enquanto persegue
		velocity.x = 0
		sprite.play("idle")

# --- AJUDANTES ---
func _virar_visual(dir):
	if dir == 0: return
	
	direction = dir # Atualiza a variável global de direção
	
	# Inverte o sprite
	sprite.flip_h = (dir == -1)
	
	# Vira o sensor de buraco (IMPORTANTE: O RayCast deve ter posição X inicial > 0 no editor)
	raycast_chao.position.x = abs(raycast_chao.position.x) * dir
	
	# Vira a Hitbox (Se existir)
	if has_node("hitbox"):
		$hitbox.position.x = abs($hitbox.position.x) * dir

func _tem_chao_frente() -> bool:
	raycast_chao.force_raycast_update()
	return raycast_chao.is_colliding()

# --- SINAIS ---

func _on_detector_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		player_alvo = body

func _on_detector_body_exited(body):
	pass

func _on_hitbox_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		call_deferred("_reload")

func _reload():
	get_tree().reload_current_scene()
