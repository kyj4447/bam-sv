class_name EnemyBase
extends CharacterBody2D

signal enemy_defeated(enemy: EnemyBase)

@export var max_hp: float = 30.0
@export var speed: float = 115.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 0.6
@export var gem_scene: PackedScene = preload("res://scenes/items/gem.tscn")
@export var damage_number_scene: PackedScene = preload("res://scenes/ui/damage_number.tscn")
@export var coin_scene: PackedScene = preload("res://scenes/items/coin.tscn")

var current_hp: float = 30.0
var target_player: Player = null
var can_attack: bool = true
var attack_timer: Timer

@onready var visual_node: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite2D

func _ready() -> void:
	add_to_group("enemy")
	current_hp = max_hp
	
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(func(): can_attack = true)
	add_child(attack_timer)
	
	_find_player()
	
	var hitbox := $Hitbox as Area2D
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target_player):
		_find_player()
		return
		
	var dir := (target_player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	
	# 이동 방향에 따라 스프라이트 좌우 반전
	if velocity.x < -0.1:
		visual_node.scale.x = -abs(visual_node.scale.x)
	elif velocity.x > 0.1:
		visual_node.scale.x = abs(visual_node.scale.x)
		
	# 플레이어와 겹쳐 있을 때 주기적 공격 검사
	_check_player_contact()

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0] as Player

func _check_player_contact() -> void:
	if not can_attack or not is_instance_valid(target_player):
		return
		
	# 거리가 가까우면 데미지 부여
	var dist_sq := global_position.distance_squared_to(target_player.global_position)
	if dist_sq <= 30.0 * 30.0:
		_deal_damage_to_player()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is Player:
		_deal_damage_to_player()

func _deal_damage_to_player() -> void:
	if can_attack and is_instance_valid(target_player):
		target_player.take_damage(damage)
		can_attack = false
		attack_timer.start()

func take_damage(amount: float) -> void:
	current_hp -= amount
	_play_hit_flash()
	_spawn_damage_number(amount)
	
	if current_hp <= 0:
		_die()

func _play_hit_flash() -> void:
	var tween := create_tween()
	sprite.modulate = Color(2.0, 2.0, 2.0, 1.0) # 강렬한 피격 플래시
	tween.tween_property(sprite, "modulate", Color(1.0, 0.25, 0.25, 1.0), 0.1)

func _die() -> void:
	enemy_defeated.emit(self)
	_spawn_gem()
	if randf() < 0.25:
		_spawn_coin()
		
	# 충돌 및 처리 비활성화 후 부드러운 스케일 축소 제거
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("Hitbox"):
		$Hitbox/CollisionShape2D.set_deferred("disabled", true)
		
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _spawn_damage_number(amount: float) -> void:
	if not damage_number_scene:
		return
	var dmg_node: DamageNumber = damage_number_scene.instantiate() as DamageNumber
	dmg_node.global_position = global_position + Vector2(0, -15.0)
	var is_crit: bool = amount >= 45.0
	dmg_node.setup(amount, is_crit)
	get_tree().current_scene.call_deferred("add_child", dmg_node)

func _spawn_coin() -> void:
	if not coin_scene:
		return
	var coin: Node2D = coin_scene.instantiate() as Node2D
	coin.global_position = global_position
	var gems_container: Node = get_tree().current_scene.get_node_or_null("Gems")
	if gems_container:
		gems_container.call_deferred("add_child", coin)
	else:
		get_parent().call_deferred("add_child", coin)

func _spawn_gem() -> void:
	if not gem_scene:
		return
	var gem: Node2D = gem_scene.instantiate() as Node2D
	gem.global_position = global_position
	var gems_container: Node = get_tree().current_scene.get_node_or_null("Gems")
	if gems_container:
		gems_container.call_deferred("add_child", gem)
	else:
		get_parent().call_deferred("add_child", gem)
