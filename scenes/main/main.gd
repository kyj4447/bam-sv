class_name Main
extends Node2D

var elapsed_time: float = 0.0
var kill_count: int = 0
var run_gold: int = 0
var is_game_over: bool = false
var is_victory: bool = false

# 피버 타임 설정 (45초마다 12초간 발동)
var fever_interval: float = 45.0
var fever_duration: float = 12.0
var fever_timer: float = 0.0
var is_fever_active: bool = false

@onready var player: Player = $Player
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var upgrade_manager: UpgradeManager = $UpgradeManager

@onready var exp_bar: ProgressBar = $UI/HUD/ExpBar
@onready var level_label: Label = $UI/HUD/TopLeft/Header/LevelLabel
@onready var health_bar: ProgressBar = $UI/HUD/TopLeft/HealthBar
@onready var health_label: Label = $UI/HUD/TopLeft/Header/HealthLabel
@onready var time_label: Label = $UI/HUD/TopCenter/TimeLabel
@onready var fever_banner: Label = $UI/HUD/TopCenter/FeverBanner
@onready var kill_label: Label = $UI/HUD/TopRight/KillLabel
@onready var gold_label: Label = $UI/HUD/TopRight/GoldLabel
@onready var boss_bar_container: Control = $UI/HUD/BossBarContainer
@onready var boss_bar: ProgressBar = $UI/HUD/BossBarContainer/BossBar
@onready var boss_label: Label = $UI/HUD/BossBarContainer/BossLabel
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var victory_panel: Control = $UI/VictoryPanel
@onready var level_up_modal: LevelUpModal = $UI/LevelUpModal
@onready var chest_modal: ChestModal = $UI/ChestModal
@onready var shop_modal: ShopModal = $UI/ShopModal

func _ready() -> void:
	game_over_panel.visible = false
	victory_panel.visible = false
	boss_bar_container.visible = false

	if is_instance_valid(fever_banner):
		fever_banner.visible = false

	if is_instance_valid(player):
		player.health_changed.connect(_on_player_health_changed)
		player.died.connect(_on_player_died)
		player.exp_changed.connect(_on_player_exp_changed)
		player.leveled_up.connect(_on_player_leveled_up)
		_on_player_health_changed(player.current_health, player.max_health)
		_on_player_exp_changed(player.current_exp, player.max_exp, player.level)

	if is_instance_valid(enemy_spawner):
		enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)

	if is_instance_valid(level_up_modal):
		level_up_modal.upgrade_selected.connect(_on_upgrade_selected)

	if is_instance_valid(chest_modal):
		chest_modal.closed.connect(_on_chest_modal_closed)

	if is_instance_valid(gold_label):
		gold_label.text = "💰 0"

	var go_shop_btn: Button = game_over_panel.get_node_or_null("VBox/ShopButton")
	if go_shop_btn:
		go_shop_btn.pressed.connect(_on_open_shop_pressed)
		
	var vic_shop_btn: Button = victory_panel.get_node_or_null("VBox/ShopButton")
	if vic_shop_btn:
		vic_shop_btn.pressed.connect(_on_open_shop_pressed)

func _process(delta: float) -> void:
	if is_game_over or is_victory:
		if is_instance_valid(shop_modal) and shop_modal.visible:
			return
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()
		return

	elapsed_time += delta
	_update_time_display()
	_update_fever_time(delta)

	# 스포너에 현재 경과 시간 전달 (웨이브 스케줄러용)
	if is_instance_valid(enemy_spawner):
		enemy_spawner.update_time(elapsed_time)

func _update_time_display() -> void:
	var minutes: int = int(elapsed_time) / 60
	var seconds: int = int(elapsed_time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

func _update_fever_time(delta: float) -> void:
	fever_timer += delta

	if not is_fever_active:
		if fever_timer >= fever_interval:
			_start_fever_time()
	else:
		if fever_timer >= fever_duration:
			_end_fever_time()
		else:
			if is_instance_valid(fever_banner):
				var pulse: float = (sin(elapsed_time * 8.0) + 1.0) * 0.5
				fever_banner.modulate = Color(1.0, 0.4 + pulse * 0.5, 0.1, 0.8 + pulse * 0.2)

func _start_fever_time() -> void:
	is_fever_active = true
	fever_timer = 0.0
	if is_instance_valid(enemy_spawner):
		enemy_spawner.set_fever_time(true)
	if is_instance_valid(fever_banner):
		fever_banner.visible = true
	if is_instance_valid(time_label):
		time_label.modulate = Color(1.0, 0.35, 0.15, 1.0)

func _end_fever_time() -> void:
	is_fever_active = false
	fever_timer = 0.0
	if is_instance_valid(enemy_spawner):
		enemy_spawner.set_fever_time(false)
	if is_instance_valid(fever_banner):
		fever_banner.visible = false
	if is_instance_valid(time_label):
		time_label.modulate = Color(1.0, 1.0, 1.0, 1.0)

# --- 보물상자 처리 ---
func open_chest_modal() -> void:
	if not is_instance_valid(upgrade_manager) or not is_instance_valid(chest_modal) or not is_instance_valid(player):
		return

	var evo_data: Dictionary = upgrade_manager.check_evolution_available()

	if not evo_data.is_empty():
		# 진화 조건 충족 → 무기 진화!
		upgrade_manager.apply_evolution(evo_data, player)
		chest_modal.open_reward(true, evo_data["title"], evo_data["desc"])
	else:
		# 진화 조건 미충족 → 무작위 스킬 강화 또는 체력 회복
		var reward: Dictionary = upgrade_manager.get_free_upgrade_for_chest(player)
		chest_modal.open_reward(false, reward["title"], reward["desc"])

func _on_chest_modal_closed() -> void:
	pass # 필요시 추가 처리

# --- 플레이어 UI 연동 ---
func _on_player_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "HP: %d / %d" % [int(current), int(maximum)]

func _on_player_exp_changed(current: float, max_exp: float, level: int) -> void:
	exp_bar.max_value = max_exp
	exp_bar.value = current
	level_label.text = "Lv. %d" % level

func _on_player_leveled_up(_level: int) -> void:
	if is_instance_valid(upgrade_manager) and is_instance_valid(level_up_modal):
		var options: Array[Dictionary] = upgrade_manager.get_random_upgrades(3)
		level_up_modal.open(options)

func _on_upgrade_selected(upgrade_id: String) -> void:
	if is_instance_valid(upgrade_manager) and is_instance_valid(player):
		upgrade_manager.apply_upgrade(upgrade_id, player)

func add_run_gold(amount: int) -> void:
	run_gold += amount
	if is_instance_valid(gold_label):
		gold_label.text = "💰 %d" % run_gold
	SaveManager.get_instance().add_gold(amount)

func _on_open_shop_pressed() -> void:
	if is_instance_valid(shop_modal):
		shop_modal.open()

func _on_player_died() -> void:
	is_game_over = true
	game_over_panel.visible = true
	$UI/GameOverPanel/VBox/StatsLabel.text = "생존 시간: %s  |  처치: %d  |  Lv. %d  |  획득 골드: 💰 %d G" % [
		time_label.text, kill_count,
		player.level if is_instance_valid(player) else 1,
		run_gold
	]

# --- 적 처치 및 보스 연동 ---
func _on_enemy_spawned(enemy: EnemyBase) -> void:
	enemy.enemy_defeated.connect(_on_enemy_defeated)

	if enemy is EnemyBoss:
		var boss: EnemyBoss = enemy as EnemyBoss
		boss.boss_health_changed.connect(_on_boss_health_changed)
		boss.boss_defeated.connect(_on_boss_defeated)
		boss_bar_container.visible = true
		boss_bar.max_value = boss.max_hp
		boss_bar.value = boss.max_hp
		boss_label.text = "👿 뱀파이어 로드"

func _on_enemy_defeated(_enemy: EnemyBase) -> void:
	kill_count += 1
	kill_label.text = "Kills: %d" % kill_count

func _on_boss_health_changed(current: float, max_hp: float) -> void:
	boss_bar.max_value = max_hp
	boss_bar.value = current

func _on_boss_defeated() -> void:
	is_victory = true
	boss_bar_container.visible = false
	victory_panel.visible = true
	$UI/VictoryPanel/VBox/StatsLabel.text = "클리어 시간: %s  |  처치: %d  |  Lv. %d  |  획득 골드: 💰 %d G" % [
		time_label.text, kill_count,
		player.level if is_instance_valid(player) else 1,
		run_gold
	]
