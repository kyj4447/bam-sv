class_name WeaponInfiniteBlades
extends Node2D

@export var damage: float = 40.0
@export var blade_count: int = 6
@export var orbit_radius: float = 125.0
@export var rotation_speed: float = 17.0
@export var hit_radius: float = 32.0
@export var attack_sound: AudioStream = preload("res://scenes/assets/sound/short_first.mp3")

var current_angle: float = 0.0
var shard_timer: float = 0.0
var hit_history: Dictionary = {}
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = attack_sound
	add_child(audio_player)

func _process(delta: float) -> void:
	# 쿨다운 없이 상시 영구 회전
	current_angle += rotation_speed * delta
	
	# 개별 타격 쿨다운 차감
	var dead_keys: Array = []
	for key in hit_history.keys():
		hit_history[key] -= delta
		if hit_history[key] <= 0.0:
			dead_keys.append(key)
	for key in dead_keys:
		hit_history.erase(key)
		
	_check_blade_collisions()
	
	# 주기적으로 외곽으로 칼날 파편 사출
	shard_timer += delta
	if shard_timer >= 0.6:
		shard_timer = 0.0
		_launch_shards()
		
	queue_redraw()

func _check_blade_collisions() -> void:
	var player: Player = owner as Player
	var dmg_mult: float = player.damage_multiplier if is_instance_valid(player) else 1.0
	var final_dmg: float = damage * dmg_mult
	var enemies: Array = get_tree().get_nodes_in_group("enemy")
	var hit_radius_sq: float = hit_radius * hit_radius
	
	for i in range(blade_count):
		var angle: float = current_angle + float(i) * (TAU / float(blade_count))
		var blade_local_pos: Vector2 = Vector2(cos(angle), sin(angle)) * orbit_radius
		var blade_global_pos: Vector2 = global_position + blade_local_pos
		
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			var enemy_node: Node2D = enemy as Node2D
			var enemy_id: int = enemy_node.get_instance_id()
			
			if hit_history.has(enemy_id):
				continue
				
			if blade_global_pos.distance_squared_to(enemy_node.global_position) <= hit_radius_sq:
				if enemy.has_method("take_damage"):
					enemy.take_damage(final_dmg)
					hit_history[enemy_id] = 0.2

func _launch_shards() -> void:
	if is_instance_valid(audio_player) and audio_player.stream:
		audio_player.pitch_scale = randf_range(1.1, 1.25)
		audio_player.play()
		
	var player: Player = owner as Player
	var dmg_mult: float = player.damage_multiplier if is_instance_valid(player) else 1.0
	var shard_dmg: float = damage * 0.7 * dmg_mult
	
	# 4방향으로 칼날 파편 발사
	for i in range(4):
		var angle: float = current_angle + float(i) * (TAU / 4.0)
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		
		var proj: Area2D = Area2D.new()
		proj.collision_layer = 4
		proj.collision_mask = 2
		proj.global_position = global_position + dir * orbit_radius
		
		var shape: CollisionShape2D = CollisionShape2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = 12.0
		shape.shape = circle
		proj.add_child(shape)
		
		proj.set_script(preload("res://scenes/weapons/projectile.gd"))
		proj.set("speed", 520.0)
		proj.set("damage", shard_dmg)
		proj.set("direction", dir)
		proj.set("lifetime", 1.8)
		
		var container: Node = get_tree().current_scene.get_node_or_null("Projectiles")
		if container:
			container.call_deferred("add_child", proj)
		else:
			get_tree().current_scene.call_deferred("add_child", proj)

func _draw() -> void:
	# 무지개빛/화려한 칼날 폭풍 궤적
	draw_arc(Vector2.ZERO, orbit_radius, 0.0, TAU, 48, Color(0.2, 0.9, 1.0, 0.35), 4.0)
	
	for i in range(blade_count):
		var angle: float = current_angle + float(i) * (TAU / float(blade_count))
		var blade_pos: Vector2 = Vector2(cos(angle), sin(angle)) * orbit_radius
		
		var forward: Vector2 = Vector2(-sin(angle), cos(angle))
		var normal: Vector2 = Vector2(cos(angle), sin(angle))
		
		var tip: Vector2 = blade_pos + forward * 28.0
		var back: Vector2 = blade_pos - forward * 14.0
		var outer: Vector2 = blade_pos + normal * 11.0
		var inner: Vector2 = blade_pos - normal * 4.0
		
		var blade_points: PackedVector2Array = [tip, outer, back, inner]
		draw_colored_polygon(blade_points, Color(0.2, 1.0, 0.9, 0.9))
		draw_polyline(blade_points, Color(1.0, 1.0, 1.0, 1.0), 2.0)
