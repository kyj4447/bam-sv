class_name PlayerCamera
extends Camera2D

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0

func _process(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		var damping: float = shake_timer / shake_duration
		var current_shake: float = shake_intensity * damping
		offset = Vector2(
			randf_range(-current_shake, current_shake),
			randf_range(-current_shake, current_shake)
		)
	else:
		offset = Vector2.ZERO

func shake(intensity: float = 6.0, duration: float = 0.2) -> void:
	# 더 강한 셰이크가 들어오면 갱신
	shake_intensity = max(shake_intensity, intensity)
	shake_duration = duration
	shake_timer = duration
