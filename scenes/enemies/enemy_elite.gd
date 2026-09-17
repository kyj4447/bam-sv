class_name EnemyElite
extends EnemyBase

@export var chest_scene: PackedScene = preload("res://scenes/items/chest.tscn")

var aura_anim: float = 0.0

func _ready() -> void:
	max_hp = 450.0
	speed = 105.0
	damage = 25.0
	attack_cooldown = 0.6
	super._ready()
	
	if sprite:
		sprite.modulate = Color(1.0, 0.15, 0.15) # 강렬한 심홍색
		sprite.scale = Vector2(0.55, 0.55)

func _process(delta: float) -> void:
	aura_anim += delta * 5.0
	queue_redraw()

func _draw() -> void:
	# 붉은색 엘리트 위압감 오라 렌더링
	var aura_radius: float = 28.0 + sin(aura_anim) * 4.0
	draw_arc(Vector2.ZERO, aura_radius, 0.0, TAU, 32, Color(1.0, 0.2, 0.2, 0.4), 3.0)

func _spawn_gem() -> void:
	# 엘리트는 일반 젬 대신 귀중한 보물상자 드롭!
	if not chest_scene:
		return
	var chest: Node2D = chest_scene.instantiate() as Node2D
	chest.global_position = global_position
	var gems_container: Node = get_tree().current_scene.get_node_or_null("Gems")
	if gems_container:
		gems_container.call_deferred("add_child", chest)
	else:
		get_parent().call_deferred("add_child", chest)
