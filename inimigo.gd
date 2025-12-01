extends CharacterBody2D

# --- CONFIG ---
var speed_patrulha = 60
var speed_perseguir = 110
var gravity = 980
var forca_quicar = -350

var sprite_olha_direita = true

# ESTADOS
enum { PATRULHA, PERSEGUIR }
var estado = PATRULHA

# VARS
var direction = 1
var player_alvo = null
var esta_morto = false
var direcao_visual = 1

# ==============================================================
# ⚠️ CORREÇÃO DE OFFSET: AJUSTE ESTE VALOR ⚠️
# 1. Selecione o nó "$Hit" na sua cena do inimigo.
# 2. Olhe a propriedade 'Position' no Inspector.
# 3. Use o valor X positivo aqui (Ex: se no Inspector for (18, 0), use 18).
const HIT_OFFSET_X = 15 # <-- SUBSTITUA ESTE '15' pelo SEU VALOR CORRETO
# ==============================================================

# NODES
@onready var sprite = $AnimatedSprite2D
@onready var ray = $RayCastChao
@onready var hit = $Hit # O nó Area2D de colisão lateral
@onready var head = $Head

func _physics_process(delta):
	if esta_morto:
		move_and_slide()
		return

	# Aplica gravidade
	velocity.y += gravity * delta

	# Lógica de estados
	match estado:
		PATRULHA:
			estado_patrulha()
		PERSEGUIR:
			estado_perseguir()

	# Aplica movimento
	move_and_slide()


# ================= PATRULHA =================
func estado_patrulha():
	# Transição para PERSEGUIR
	if player_alvo:
		estado = PERSEGUIR
		return

	# Vira se atingir parede ou não tiver chão
	if is_on_wall() or not _tem_chao_frente():
		direction *= -1

	velocity.x = direction * speed_patrulha
	sprite.play("walk")
	_atualizar_visual(direction)


# ================= PERSEGUIR =================
func estado_perseguir():
	# Transição para PATRULHA (se perder o alvo)
	if not is_instance_valid(player_alvo):
		player_alvo = null
		estado = PATRULHA
		return

	# Calcula a direção para o Player
	var direcao = sign(player_alvo.global_position.x - global_position.x)

	# Se não houver chão à frente, para.
	if not _tem_chao_frente():
		velocity.x = 0
		sprite.play("idle")
	else:
		velocity.x = direcao * speed_perseguir
		sprite.play("run")

	_atualizar_visual(direcao)


# ================= VISUAL E CORREÇÃO DO HITBOX =================
func _atualizar_visual(d):
	# Não faz nada se a direção for 0 (parado)
	if d == 0:
		return

	# Só executa as atualizações se a direção de movimento mudou
	if direcao_visual != d:
		direcao_visual = d

		# 1. Flip do Sprite
		# Se 'sprite_olha_direita' é true, vira a imagem se d for -1
		sprite.flip_h = (d == -1) if sprite_olha_direita else (d == 1)

		# 2. RayCast sempre na frente REAL do inimigo (aqui usa 10 como offset)
		ray.position.x = 10 * d
		
		# 3. ✅ CORREÇÃO DO HITBOX LATERAL ($Hit)
		# Aplica o offset correto. Inverte o sinal (d = 1 ou d = -1) para mover
		# o nó $Hit junto com o lado espelhado.
		hit.position.x = HIT_OFFSET_X * d
		
		# (Opcional) Se o Head também tiver um offset, adicione aqui:
		# head.position.x = HEAD_OFFSET_X * d
		

func _tem_chao_frente():
	# Força a atualização e verifica se o RayCast está colidindo
	ray.force_raycast_update()
	return ray.is_colliding()


# ================= COLISÕES =================

# Detecta o Player para entrar no estado PERSEGUIR
func _on_detector_body_entered(body):
	if body.is_in_group("player"):
		player_alvo = body
		estado = PERSEGUIR

func _on_detector_body_exited(body):
	if body == player_alvo:
		player_alvo = null
		estado = PATRULHA


# ----------- DANO (colisão lateral $Hit) -----------
func _on_hit_body_entered(body):
	if esta_morto:
		return

	# Se colidir com o Player lateralmente, reinicia a cena (mata o Player)
	if body.is_in_group("player"):
		get_tree().reload_current_scene()


# ----------- CABEÇA (matar o inimigo $Head) -----------
func _on_head_body_entered(body):
	if esta_morto:
		return
	
	# Só mata se o PLAYER estiver CAINDO (pulando em cima)
	if body.is_in_group("player") and body.velocity.y > 0:
		esta_morto = true
		
		# Aplica o quique no Player
		body.velocity.y = forca_quicar 
		
		# Efeitos visuais e remoção
		sprite.modulate = Color(1,0,0) # Deixa vermelho
		hit.queue_free()
		head.queue_free()
		
		# Espera um curto período e remove o inimigo
		await get_tree().create_timer(0.2).timeout
		queue_free()
