class_name EnemySpawner
extends Node2D

signal enemy_spawned(enemy: EnemyBase)

@export var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy_base.tscn")
@export var enemy_fast_scene: PackedScene = preload("res://scenes/enemies/enemy_fast.tscn")
@export var enemy_tank_scene: PackedScene = preload("res://scenes/enemies/enemy_tank.tscn")
@export var enemy_elite_scene: PackedScene = preload("res://scenes/enemies/enemy_elite.tscn")
@export var enemy_boss_scene: PackedScene = preload("res://scenes/enemies/enemy_boss.tscn")

@export var spawn_interval: float = 1.0
@export var spawn_radius_min: float = 750.0
@export var spawn_radius_max: float = 900.0

var spawn_timer: Timer
var target_player: Player = null
var is_fever_time: bool = false
var elapsed_seconds: float = 0.0
var boss_spawned: bool = false
var elite_spawn_times: Array[float] = [180.0, 360.0] # 3분, 6분에 엘리트 출현
var next_elite_index: int = 0

func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

func set_fever_time(active: bool) -> void:
	is_fever_time = active
	if active:
		spawn_timer.wait_time = max(0.3, spawn_interval * 0.77)
	else:
		spawn_timer.wait_time = spawn_interval

func update_time(seconds: float) -> void:
	elapsed_seconds = seconds
	
	# 8분(480초)에 보스 출현
	if not boss_spawned and elapsed_seconds >= 480.0:
		boss_spawned = true
		spawn_timer.stop() # 일반 스폰 중단
		_spawn_specific_enemy(enemy_boss_scene)
		return
	
	# 엘리트 예약 시간 도달 체크
	if next_elite_index < elite_spawn_times.size():
		if elapsed_seconds >= elite_spawn_times[next_elite_index]:
			next_elite_index += 1
			_spawn_specific_enemy(enemy_elite_scene)

func _on_spawn_timer_timeout() -> void:
	if boss_spawned:
		return
	spawn_enemy()

func spawn_enemy() -> void:
	if not is_instance_valid(target_player):
		var players: Array = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0] as Player
		else:
			return

	var chosen_scene: PackedScene = _pick_enemy_scene()
	_create_enemy_from_scene(chosen_scene)

	# 피버 타임: 30% 확률 추가 스폰
	if is_fever_time and randf() < 0.30:
		_create_enemy_from_scene(chosen_scene)

func _pick_enemy_scene() -> PackedScene:
	var t: float = elapsed_seconds
	var roll: float = randf()

	# 시간대별 스폰 가중치 테이블
	if t < 90.0:
		# 00:00~01:30 : 일반 슬라임 100%
		return enemy_scene
	elif t < 180.0:
		# 01:30~03:00 : 일반 60%, 박쥐 40%
		return enemy_scene if roll < 0.6 else enemy_fast_scene
	elif t < 360.0:
		# 03:00~06:00 : 일반 40%, 박쥐 35%, 골렘 25%
		if roll < 0.4:
			return enemy_scene
		elif roll < 0.75:
			return enemy_fast_scene
		else:
			return enemy_tank_scene
	else:
		# 06:00~08:00 : 박쥐 40%, 골렘 40%, 일반 20%
		if roll < 0.4:
			return enemy_fast_scene
		elif roll < 0.8:
			return enemy_tank_scene
		else:
			return enemy_scene

func _create_enemy_from_scene(scene: PackedScene) -> void:
	if not is_instance_valid(target_player) or not scene:
		return

	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(spawn_radius_min, spawn_radius_max)
	var spawn_pos: Vector2 = target_player.global_position + Vector2(cos(angle), sin(angle)) * distance

	var enemy: EnemyBase = scene.instantiate() as EnemyBase
	enemy.global_position = spawn_pos

	var enemies_container: Node = get_tree().current_scene.get_node_or_null("Enemies")
	if enemies_container:
		enemies_container.add_child(enemy)
	else:
		get_parent().add_child(enemy)

	enemy_spawned.emit(enemy)

func _spawn_specific_enemy(scene: PackedScene) -> void:
	if not is_instance_valid(target_player):
		var players: Array = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0] as Player
		else:
			return
	_create_enemy_from_scene(scene)
