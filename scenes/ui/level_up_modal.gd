class_name LevelUpModal
extends Control

signal upgrade_selected(upgrade_id: String)

@export var card_scene: PackedScene = preload("res://scenes/ui/level_up_card.tscn")

@onready var cards_container: HBoxContainer = $Center/VBox/CardsContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func open(upgrades: Array[Dictionary]) -> void:
	# 기존 카드 정리
	for child in cards_container.get_children():
		child.queue_free()
		
	if upgrades.is_empty():
		# 선택할 업그레이드가 없을 경우 즉시 닫기
		return
		
	for data in upgrades:
		var card: LevelUpCard = card_scene.instantiate() as LevelUpCard
		cards_container.add_child(card)
		card.setup(data)
		card.selected.connect(_on_card_selected)
		
	visible = true
	get_tree().paused = true

func _on_card_selected(id: String) -> void:
	visible = false
	get_tree().paused = false
	upgrade_selected.emit(id)
