class_name WeaponMagicMissile
extends Node2D

@export var projectile_scene: PackedScene = preload("res://scenes/weapons/projectile.tscn")
@export var attack_cooldown: float = 1.0
@export var attack_range: float = 500.0
@export var damage: float = 25.0
@export var projectile_count: int = 1
@export var attack_sound: AudioStream = preload("res://scenes/assets/sound/short_first.mp3")

var cooldown_timer: Timer
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	cooldown_timer = Timer.new()
	cooldown_timer.wait_time = attack_cooldown
	cooldown_timer.autostart = true
	cooldown_timer.one_shot = false
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	add_child(cooldown_timer)
	
	audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = attack_sound
	add_child(audio_player)

func _on_cooldown_timeout() -> void:
	fire()

func fire() -> void:
	var target_enemy := _find_nearest_enemy()
	if not target_enemy:
		return
		
	var target_dir: Vector2 = (target_enemy.global_position - global_position).normalized()
	if target_dir == Vector2.ZERO:
		target_dir = Vector2.RIGHT
		
	_play_attack_sound()

	for i in range(projectile_count):
		_spawn_projectile(target_dir)

func _play_attack_sound() -> void:
	if is_instance_valid(audio_player) and audio_player.stream:
		audio_player.pitch_scale = randf_range(0.95, 1.05)
		audio_player.play()

func _spawn_projectile(dir: Vector2) -> void:
	if not projectile_scene:
		return
		
	var player: Player = owner as Player
	var dmg_mult: float = player.damage_multiplier if is_instance_valid(player) else 1.0
	
	var projectile: Projectile = projectile_scene.instantiate() as Projectile
	projectile.global_position = global_position
	projectile.direction = dir
	projectile.damage = damage * dmg_mult
	
	# 발사체는 월드(메인 씬 등)의 Projectiles 컨테이너 또는 최상위 노드에 배치
	var projectiles_container := get_tree().current_scene.get_node_or_null("Projectiles")
	if projectiles_container:
		projectiles_container.add_child(projectile)
	else:
		get_tree().current_scene.add_child(projectile)

func upgrade() -> void:
	projectile_count += 1
	damage += 6.0
	attack_cooldown = max(0.4, attack_cooldown - 0.1)
	if is_instance_valid(cooldown_timer):
		cooldown_timer.wait_time = attack_cooldown

func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var nearest_enemy: Node2D = null
	var nearest_dist_sq: float = attack_range * attack_range
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist_sq := global_position.distance_squared_to(enemy.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest_enemy = enemy
			
	return nearest_enemy
