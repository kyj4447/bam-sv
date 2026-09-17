class_name ChestModal
extends Control

signal closed

@onready var title_label: Label = $Center/VBox/TitleLabel
@onready var item_title: Label = $Center/VBox/CardPanel/Margin/VBox/ItemTitle
@onready var item_desc: Label = $Center/VBox/CardPanel/Margin/VBox/ItemDesc
@onready var confirm_btn: Button = $Center/VBox/ConfirmButton
@onready var card_panel: PanelContainer = $Center/VBox/CardPanel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	confirm_btn.pressed.connect(_on_confirm_pressed)

func open_reward(is_evolution: bool, title: String, desc: String) -> void:
	visible = true
	get_tree().paused = true
	
	if is_evolution:
		title_label.text = "★ WEAPON EVOLVED! ★"
		title_label.modulate = Color(1.0, 0.85, 0.2)
		item_title.modulate = Color(1.0, 0.9, 0.3)
	else:
		title_label.text = "TREASURE UNLOCKED!"
		title_label.modulate = Color(0.3, 0.9, 1.0)
		item_title.modulate = Color(0.4, 0.95, 0.6)
		
	item_title.text = title
	item_desc.text = desc
	
	# 상자 오픈 팝업 연출 (스케일 팝)
	card_panel.scale = Vector2(0.5, 0.5)
	var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(card_panel, "scale", Vector2(1.05, 1.05), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_panel, "scale", Vector2.ONE, 0.1)

func _on_confirm_pressed() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()
