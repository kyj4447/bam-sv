class_name LevelUpCard
extends Button

signal selected(upgrade_id: String)

var upgrade_id: String = ""

@onready var title_label: Label = $Margin/VBox/Header/TitleLabel
@onready var type_label: Label = $Margin/VBox/Header/TypeLabel
@onready var level_label: Label = $Margin/VBox/LevelLabel
@onready var desc_label: Label = $Margin/VBox/DescLabel

func _ready() -> void:
	pressed.connect(_on_pressed)

func setup(data: Dictionary) -> void:
	if not is_node_ready():
		await ready
		
	upgrade_id = data["id"]
	var lvl: int = data["level"]
	var is_new: bool = (lvl == 0)
	
	if is_instance_valid(title_label):
		title_label.text = data["title"]
	if is_instance_valid(type_label):
		var type_str: String = "무기" if data["type"] == "weapon" else "패시브"
		type_label.text = "[%s]" % type_str
		type_label.modulate = Color(1.0, 0.8, 0.3) if data["type"] == "weapon" else Color(0.4, 0.9, 1.0)
	if is_instance_valid(level_label):
		level_label.text = "★ 신규 획득!" if is_new else "Lv. %d → Lv. %d" % [lvl, lvl + 1]
		level_label.modulate = Color(0.3, 1.0, 0.5) if is_new else Color(1.0, 0.9, 0.4)
	if is_instance_valid(desc_label):
		desc_label.text = data["desc"]

func _on_pressed() -> void:
	selected.emit(upgrade_id)
