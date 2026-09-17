class_name Projectile
extends Area2D

@export var speed: float = 550.0
@export var damage: float = 25.0
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# 수명 타이머 설정 (화면 밖 등으로 사라지지 않아도 일정 시간 후 메모리 해제)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _draw() -> void:
	# 별도 애셋 없이도 자체 렌더링되는 발광 마법탄
	draw_circle(Vector2.ZERO, 9.0, Color(0.2, 0.7, 1.0, 0.4)) # 외곽 발광
	draw_circle(Vector2.ZERO, 6.0, Color(0.4, 0.9, 1.0, 0.9)) # 메인 바디
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 1.0, 1.0, 1.0)) # 중앙 코어

func _on_area_entered(area: Area2D) -> void:
	_hit(area.owner if area.owner else area)

func _on_body_entered(body: Node2D) -> void:
	_hit(body)

func _hit(target: Node) -> void:
	if target and target.has_method("take_damage"):
		set_deferred("monitoring", false)
		target.take_damage(damage)
		queue_free()
