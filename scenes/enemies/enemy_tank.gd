class_name EnemyTank
extends EnemyBase

func _ready() -> void:
	max_hp = 130.0
	speed = 60.0
	damage = 20.0
	attack_cooldown = 0.8
	super._ready()
	
	if sprite:
		sprite.modulate = Color(0.45, 0.45, 0.55) # 다크 스톤
		sprite.scale = Vector2(0.48, 0.48)
