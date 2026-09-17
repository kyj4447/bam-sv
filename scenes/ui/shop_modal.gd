class_name ShopModal
extends Control

signal closed

@onready var gold_label: Label = $Center/Panel/Margin/VBox/Header/GoldLabel
@onready var items_container: VBoxContainer = $Center/Panel/Margin/VBox/Scroll/ItemsContainer
@onready var close_button: Button = $Center/Panel/Margin/VBox/CloseButton

var item_rows: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	close_button.pressed.connect(_on_close_pressed)

func open() -> void:
	visible = true
	_refresh_ui()

func _on_close_pressed() -> void:
	visible = false
	closed.emit()

func _refresh_ui() -> void:
	var sm := SaveManager.get_instance()
	gold_label.text = "보유 골드: 💰 %d G" % sm.gold

	for id in sm.UPGRADE_CONFIGS.keys():
		var cfg: Dictionary = sm.UPGRADE_CONFIGS[id]
		var lvl: int = sm.get_upgrade_level(id)
		var max_lvl: int = cfg.get("max_level", 5)
		var cost: int = sm.get_upgrade_cost(id)
		var can_buy: bool = sm.can_afford(id)

		var row: Control = _get_or_create_row(id)
		var title_lbl: Label = row.get_node("HBox/Info/Title")
		var desc_lbl: Label = row.get_node("HBox/Info/Desc")
		var btn: Button = row.get_node("HBox/BuyButton")

		title_lbl.text = "%s (Lv. %d / %d)" % [cfg["title"], lvl, max_lvl]
		desc_lbl.text = cfg["desc"]

		if lvl >= max_lvl:
			btn.text = "MAX"
			btn.disabled = true
		else:
			btn.text = "강화 (%d G)" % cost
			btn.disabled = not can_buy

func _get_or_create_row(id: String) -> Control:
	if item_rows.has(id):
		return item_rows[id]

	var row := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.22, 0.85)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.theme_override_constants.separation = 16
	row.add_child(hbox)

	var info := VBoxContainer.new()
	info.name = "Info"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var title := Label.new()
	title.name = "Title"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3, 1))
	info.add_child(title)

	var desc := Label.new()
	desc.name = "Desc"
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 1))
	info.add_child(desc)

	var btn := Button.new()
	btn.name = "BuyButton"
	btn.custom_minimum_size = Vector2(130, 36)
	btn.pressed.connect(func(): _on_buy_pressed(id))
	hbox.add_child(btn)

	items_container.add_child(row)
	item_rows[id] = row
	return row

func _on_buy_pressed(id: String) -> void:
	var sm := SaveManager.get_instance()
	if sm.buy_upgrade(id):
		_refresh_ui()
