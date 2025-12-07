extends Area2D

const TELA_VITORIA_PATH := "res://vitoria.tscn" # <<< AJUSTADO
var ja_ativou := false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if ja_ativou:
		return

	if body.is_in_group("player"):
		ja_ativou = true

		if not ResourceLoader.exists(TELA_VITORIA_PATH):
			push_error("❌ Cena de vitória NÃO encontrada!")
			return

		get_tree().change_scene_to_file(TELA_VITORIA_PATH)
