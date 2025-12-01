extends Area2D

const TELA_VITORIA_PATH = "res://frasevitoria.tscn"

var ja_ativou = false
var tela_vitoria_ref: Node = null

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if ja_ativou:
		return
	if body.name == "Player" or body.is_in_group("player"):
		ja_ativou = true
		ativar_vitoria(body)

func ativar_vitoria(player_body: Node):
	if not ResourceLoader.exists(TELA_VITORIA_PATH):
		push_error("Cena de vitória não encontrada!")
		return

	var victory_res = load(TELA_VITORIA_PATH)
	var victory_scene = victory_res.instantiate()

	# força aparecer mesmo pausado
	victory_scene.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# força ficar NA FRENTE
	if victory_scene.has_method("set_z_index"):
		victory_scene.z_index = 9999

	get_tree().root.add_child(victory_scene)
	tela_vitoria_ref = victory_scene

	if is_instance_valid(player_body):
		player_body.hide()

	get_tree().paused = true
