class_name EnemyBoss
extends EnemyBase

signal boss_health_changed(current: float, max_hp: float)
signal boss_defeated

@export var chest_scene: PackedScene = preload("res://scenes/items/chest.tscn")

var pulse_anim: float = 0.0

func _ready() -> void:
	max_hp = 1600.0
	speed = 110.0
	damage = 30.0
	attack_cooldown = 0.5
	super._ready()
	
	if sprite:
		sprite.modulate = Color(0.9, 0.05, 0.2) # 진홍빛 군주
		sprite.scale = Vector2(0.75, 0.75)
		
	boss_health_changed.emit(current_hp, max_hp)

func _process(delta: float) -> void:
	pulse_anim += delta * 4.0
	queue_redraw()

func _draw() -> void:
	# 보스 전용 거대한 지옥의 불길 오라
	var r1: float = 38.0 + sin(pulse_anim) * 5.0
	var r2: float = 46.0 + cos(pulse_anim * 1.2) * 6.0
	draw_arc(Vector2.ZERO, r1, 0.0, TAU, 36, Color(1.0, 0.1, 0.1, 0.6), 4.0)
	draw_arc(Vector2.ZERO, r2, 0.0, TAU, 36, Color(1.0, 0.6, 0.1, 0.3), 2.5)

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	boss_health_changed.emit(current_hp, max_hp)

func _spawn_gem() -> void:
	boss_defeated.emit()
	if not chest_scene:
		return
	var chest: Node2D = chest_scene.instantiate() as Node2D
	chest.global_position = global_position
	var gems_container: Node = get_tree().current_scene.get_node_or_null("Gems")
	if gems_container:
		gems_container.call_deferred("add_child", chest)
	else:
		get_parent().call_deferred("add_child", chest)
