class_name WeaponWhip
extends Node2D

@export var damage: float = 32.0
@export var attack_cooldown: float = 0.9     # 회오리 멈춘 후 대기 시간
@export var spin_duration: float = 0.85      # 회오리 회전 지속 시간
@export var blade_count: int = 2             # 칼날 개수
@export var orbit_radius: float = 95.0       # 회전 반경
@export var rotation_speed: float = 13.0     # 회전 속도 (rad/s)
@export var hit_radius: float = 28.0        # 각 칼날의 타격 판정 반경
@export var attack_sound: AudioStream = preload("res://scenes/assets/sound/short_first.mp3")

var is_spinning: bool = false
var current_angle: float = 0.0
var spin_time_left: float = 0.0
var cooldown_time_left: float = 0.2
var hit_history: Dictionary = {}             # 적별 개별 타격 쿨다운 (다단히트 지원)
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = attack_sound
	add_child(audio_player)
	_start_spin()

func _process(delta: float) -> void:
	# 개별 적 타격 쿨다운 타이머 차감
	var dead_keys: Array = []
	for key in hit_history.keys():
		hit_history[key] -= delta
		if hit_history[key] <= 0.0:
			dead_keys.append(key)
	for key in dead_keys:
		hit_history.erase(key)

	if is_spinning:
		spin_time_left -= delta
		current_angle += rotation_speed * delta
		_check_blade_collisions()
		queue_redraw()
		
		if spin_time_left <= 0.0:
			is_spinning = false
			cooldown_time_left = attack_cooldown
			hit_history.clear()
			queue_redraw()
	else:
		cooldown_time_left -= delta
		if cooldown_time_left <= 0.0:
			_start_spin()

func _start_spin() -> void:
	is_spinning = true
	spin_time_left = spin_duration
	hit_history.clear()
	if is_instance_valid(audio_player) and audio_player.stream:
		audio_player.pitch_scale = randf_range(0.9, 1.1)
		audio_player.play()

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
					hit_history[enemy_id] = 0.25 # 0.25초 후 동일 회오리에서 다시 타격 가능

func _draw() -> void:
	if not is_spinning:
		return
		
	var alpha: float = clampf(spin_time_left / 0.15, 0.0, 1.0)
	
	# 은은한 회오리 바람 궤적 링
	draw_arc(Vector2.ZERO, orbit_radius, 0.0, TAU, 36, Color(0.4, 0.8, 1.0, 0.18 * alpha), 3.0)
	
	for i in range(blade_count):
		var angle: float = current_angle + float(i) * (TAU / float(blade_count))
		var blade_pos: Vector2 = Vector2(cos(angle), sin(angle)) * orbit_radius
		_draw_crescent_blade(blade_pos, angle, alpha)

func _draw_crescent_blade(pos: Vector2, angle: float, alpha: float) -> void:
	# 칼날의 진행 방향 (접선 방향)
	var forward: Vector2 = Vector2(-sin(angle), cos(angle))
	var normal: Vector2 = Vector2(cos(angle), sin(angle))
	
	var blade_len: float = 24.0
	var blade_width: float = 9.0
	
	var tip: Vector2 = pos + forward * blade_len
	var back: Vector2 = pos - forward * (blade_len * 0.5)
	var outer: Vector2 = pos + normal * blade_width
	var inner: Vector2 = pos - normal * (blade_width * 0.3)
	
	# 날카로운 검기 폴리곤
	var blade_points: PackedVector2Array = [
		tip,
		outer,
		back,
		inner
	]
	
	# 외곽 빛나는 하늘색 칼날
	draw_colored_polygon(blade_points, Color(0.3, 0.85, 1.0, 0.85 * alpha))
	# 내부 순백의 날카로운 칼날 코어
	var core_points: PackedVector2Array = [
		tip,
		pos + normal * (blade_width * 0.4),
		pos - forward * (blade_len * 0.2),
		pos - normal * (blade_width * 0.1)
	]
	draw_colored_polygon(core_points, Color(1.0, 1.0, 1.0, 0.95 * alpha))
	
	# 회오리 잔상 꼬리 (Wind trail)
	var trail_points: PackedVector2Array = []
	var trail_steps: int = 5
	for t in range(trail_steps):
		var trail_angle: float = angle - float(t + 1) * 0.12
		var trail_pos: Vector2 = Vector2(cos(trail_angle), sin(trail_angle)) * orbit_radius
		trail_points.append(trail_pos)
		
	if trail_points.size() > 1:
		draw_polyline(trail_points, Color(0.4, 0.9, 1.0, 0.4 * alpha), 3.5)

func upgrade() -> void:
	blade_count += 1
	damage += 8.0
	orbit_radius += 12.0
	rotation_speed += 1.5
