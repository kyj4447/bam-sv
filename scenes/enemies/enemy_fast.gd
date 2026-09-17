class_name EnemyFast
extends EnemyBase

var flap_anim: float = 0.0

func _ready() -> void:
	max_hp = 15.0
	speed = 185.0
	damage = 8.0
	attack_cooldown = 0.5
	super._ready()
	
	if sprite:
		sprite.modulate = Color(0.8, 0.3, 1.0) # 보라빛 박쥐
		sprite.scale = Vector2(0.24, 0.24)

func _process(delta: float) -> void:
	# 날개짓처럼 위아래로 빠르게 요동치는 애니메이션
	flap_anim += delta * 15.0
	if is_instance_valid(visual_node):
		visual_node.scale.y = 0.24 + sin(flap_anim) * 0.06
