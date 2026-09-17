class_name WeaponSoulBallista
extends Node2D

@export var damage: float = 60.0
@export var attack_cooldown: float = 0.65
@export var projectile_speed: float = 620.0
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
	if is_instance_valid(audio_player) and audio_player.stream:
		audio_player.pitch_scale = randf_range(0.9, 1.1)
		audio_player.play()
		
	var player: Player = owner as Player
	var dmg_mult: float = player.damage_multiplier if is_instance_valid(player) else 1.0
	var final_dmg: float = damage * dmg_mult
	
	# 4방향 십자(또는 X자)로 거대 관통 영혼탄 일제 발사
	var directions: Array[Vector2] = [
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.UP,
		Vector2.DOWN
	]
	
	for dir in directions:
		_spawn_soul_projectile(dir, final_dmg)

func _spawn_soul_projectile(dir: Vector2, hit_damage: float) -> void:
	var proj: Area2D = Area2D.new()
	proj.collision_layer = 4
	proj.collision_mask = 2
	proj.global_position = global_position
	
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	proj.add_child(shape)
	
	# 관통 투사체 스크립트 붙이기
	proj.set_script(preload("res://scenes/weapons/projectile.gd"))
	proj.set("speed", projectile_speed)
	proj.set("damage", hit_damage)
	proj.set("direction", dir)
	proj.set("lifetime", 2.5)
	
	var projectiles_container: Node = get_tree().current_scene.get_node_or_null("Projectiles")
	if projectiles_container:
		projectiles_container.call_deferred("add_child", proj)
	else:
		get_tree().current_scene.call_deferred("add_child", proj)
