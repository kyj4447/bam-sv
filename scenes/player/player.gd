class_name Player
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal died
signal exp_changed(current: float, max_exp: float, level: int)
signal leveled_up(level: int)

@export var max_health: float = 100.0
@export var speed: float = 220.0
@export var invulnerability_duration: float = 0.5

var current_health: float = 100.0
var is_invulnerable: bool = false

# 성장 및 스탯 배율
var level: int = 1
var current_exp: float = 0.0
var max_exp: float = 20.0

var speed_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var pickup_range_multiplier: float = 1.0

# 걷기 애니메이션 (6x6 = 36프레임)
var anim_timer: float = 0.0
var walk_fps: float = 24.0
var total_frames: int = 36

@onready var visual_node: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var invuln_timer: Timer = $InvulnerabilityTimer
@onready var camera: Camera2D = $Camera2D
@onready var weapons_container: Node2D = $Weapons
@onready var magnet_area: Area2D = $MagnetArea

func _ready() -> void:
	add_to_group("player")
	_apply_permanent_upgrades()
	current_health = max_health
	health_changed.emit(current_health, max_health)
	exp_changed.emit(current_exp, max_exp, level)
	
	invuln_timer.wait_time = invulnerability_duration
	invuln_timer.one_shot = true
	invuln_timer.timeout.connect(_on_invulnerability_timeout)
	
	if magnet_area:
		magnet_area.area_entered.connect(_on_magnet_area_entered)
		
	visual_node.scale = Vector2.ONE
	_setup_sprite_texture()

func _apply_permanent_upgrades() -> void:
	var sm := SaveManager.get_instance()
	max_health += sm.get_health_bonus()
	damage_multiplier *= sm.get_might_bonus()
	speed_multiplier *= sm.get_speed_bonus()
	pickup_range_multiplier *= sm.get_magnet_bonus()
	update_pickup_range()

func _setup_sprite_texture() -> void:
	var candidate_paths: Array[String] = [
		"res://scenes/assets/images/sprite_player.png",
		"res://assets/images/sprite_player.png",
		"res://assets/sprite_player.png",
		"res://.godot/assets/images/sprite_player.png"
	]
	for p in candidate_paths:
		if ResourceLoader.exists(p):
			var tex: Texture2D = load(p) as Texture2D
			if tex:
				sprite.texture = tex
				sprite.hframes = 6
				sprite.vframes = 6
				sprite.frame = 0
				sprite.modulate = Color.WHITE
				sprite.scale = Vector2(0.23, 0.23)
				break

func _physics_process(delta: float) -> void:
	# 이동 방향 계산 (WASD 및 방향키 지원)
	var move_x: float = 0.0
	var move_y: float = 0.0
	
	if InputMap.has_action("move_left") and InputMap.has_action("move_right"):
		move_x = Input.get_axis("move_left", "move_right")
	else:
		move_x = Input.get_axis("ui_left", "ui_right")
		
	if InputMap.has_action("move_up") and InputMap.has_action("move_down"):
		move_y = Input.get_axis("move_up", "move_down")
	else:
		move_y = Input.get_axis("ui_up", "ui_down")
		
	var input_vector: Vector2 = Vector2(move_x, move_y)
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
		
	velocity = input_vector * (speed * speed_multiplier)
	move_and_slide()
	
	# 걷기 애니메이션 및 좌우 방향 전환
	# 스프라이트 원본이 왼쪽(Left)을 보고 있으므로:
	# 왼쪽 이동 시 flip_h = false (원본 왼쪽 봄)
	# 오른쪽 이동 시 flip_h = true (좌우 반전되어 오른쪽 봄)
	if input_vector.x < -0.05:
		sprite.flip_h = false
	elif input_vector.x > 0.05:
		sprite.flip_h = true
		
	if velocity.length() > 5.0:
		anim_timer += delta * walk_fps
		if anim_timer >= float(total_frames):
			anim_timer -= float(total_frames)
		sprite.frame = int(anim_timer)
	else:
		anim_timer = 0.0
		sprite.frame = 0 # 정지 시 기본 서 있는 포즈

func take_damage(amount: float) -> void:
	if is_invulnerable or current_health <= 0:
		return
		
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if camera and camera.has_method("shake"):
		camera.shake(6.0, 0.25)
	
	if current_health <= 0:
		_die()
		return
		
	# 무적 시간 시작 및 깜빡임 연출
	is_invulnerable = true
	invuln_timer.start()
	_start_blink_effect()

func _die() -> void:
	died.emit()
	set_physics_process(false)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)

func _start_blink_effect() -> void:
	var tween: Tween = create_tween().set_loops(int(invulnerability_duration / 0.1))
	tween.tween_property(visual_node, "modulate:a", 0.2, 0.05)
	tween.tween_property(visual_node, "modulate:a", 1.0, 0.05)

func _on_invulnerability_timeout() -> void:
	is_invulnerable = false
	visual_node.modulate.a = 1.0

# --- 성장 및 자석 시스템 ---
func _on_magnet_area_entered(area: Area2D) -> void:
	if area is Gem:
		(area as Gem).collect(self)
	elif area is Coin:
		(area as Coin).collect(self)

func add_exp(amount: float) -> void:
	current_exp += amount
	while current_exp >= max_exp:
		current_exp -= max_exp
		level += 1
		max_exp = round(max_exp * 1.35 + 5.0)
		leveled_up.emit(level)
	exp_changed.emit(current_exp, max_exp, level)

func update_pickup_range() -> void:
	if not magnet_area:
		return
	var shape_node: CollisionShape2D = magnet_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is CircleShape2D:
		(shape_node.shape as CircleShape2D).radius = 130.0 * pickup_range_multiplier
