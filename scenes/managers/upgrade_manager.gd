class_name UpgradeManager
extends Node

var upgrades: Dictionary = {
	"magic_missile": {
		"id": "magic_missile",
		"type": "weapon",
		"title": "마법 탄환",
		"desc": "가장 가까운 적을 추적하는 마법탄을 발사합니다. (강화: 투사체 +1, 공격력 증가)",
		"max_level": 5,
		"level": 1,
		"scene": preload("res://scenes/weapons/weapon_magic_missile.tscn")
	},
	"garlic_aura": {
		"id": "garlic_aura",
		"type": "weapon",
		"title": "성스러운 마늘 오라",
		"desc": "주변 모든 적에게 지속 데미지를 주는 신성한 장막을 형성합니다.",
		"max_level": 5,
		"level": 0,
		"scene": preload("res://scenes/weapons/weapon_garlic_aura.tscn")
	},
	"whip": {
		"id": "whip",
		"type": "weapon",
		"title": "회오리 칼날",
		"desc": "플레이어 주변을 맹렬히 회전하며 적들을 난도질하는 회오리 칼날을 소환합니다. (강화: 칼날 수, 반경, 회전 속도 증가)",
		"max_level": 5,
		"level": 0,
		"scene": preload("res://scenes/weapons/weapon_whip.tscn")
	},
	"boots": {
		"id": "boots",
		"type": "passive",
		"title": "신속의 부츠",
		"desc": "플레이어의 이동 속도가 15% 증가합니다.",
		"max_level": 5,
		"level": 0
	},
	"gauntlet": {
		"id": "gauntlet",
		"type": "passive",
		"title": "힘의 건틀릿",
		"desc": "모든 무기의 공격력이 20% 증가합니다.",
		"max_level": 5,
		"level": 0
	},
	"magnet": {
		"id": "magnet",
		"type": "passive",
		"title": "마력 자석",
		"desc": "경험치 젬을 흡수하는 자석 반경이 35% 증가합니다.",
		"max_level": 5,
		"level": 0
	}
}

# 무기 진화 조합표
var evolutions: Dictionary = {
	"soul_ballista": {
		"id": "soul_ballista",
		"base_id": "magic_missile",
		"req_passive": "gauntlet",
		"title": "영혼의 발리스타",
		"desc": "★무기 진화! 4방향으로 모든 적을 관통하는 거대 영혼 에너지 구체를 난사합니다.",
		"scene": preload("res://scenes/weapons/weapon_soul_ballista.tscn"),
		"is_evolved": false
	},
	"solar_aura": {
		"id": "solar_aura",
		"base_id": "garlic_aura",
		"req_passive": "magnet",
		"title": "생명의 태양 오라",
		"desc": "★무기 진화! 초대형 태양 플레어 오라가 적을 불태우며 플레이어 체력을 흡혈 회복합니다.",
		"scene": preload("res://scenes/weapons/weapon_solar_aura.tscn"),
		"is_evolved": false
	},
	"infinite_blades": {
		"id": "infinite_blades",
		"base_id": "whip",
		"req_passive": "boots",
		"title": "무한의 검무",
		"desc": "★무기 진화! 쿨다운 없이 6개의 초승달 칼날이 상시 영구 회전하며 칼날 파편을 사방에 사출합니다.",
		"scene": preload("res://scenes/weapons/weapon_infinite_blades.tscn"),
		"is_evolved": false
	}
}

func get_random_upgrades(count: int = 3) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for key: String in upgrades.keys():
		var data: Dictionary = upgrades[key]
		if data["level"] < data["max_level"]:
			available.append(data)
			
	available.shuffle()
	var result: Array[Dictionary] = []
	var take_count: int = mini(count, available.size())
	for i in range(take_count):
		result.append(available[i])
	return result

func apply_upgrade(upgrade_id: String, player: Player) -> void:
	if not upgrades.has(upgrade_id):
		return
		
	var data: Dictionary = upgrades[upgrade_id]
	data["level"] += 1
	var new_lvl: int = data["level"]
	
	if data["type"] == "weapon":
		_apply_weapon_upgrade(data, new_lvl, player)
	elif data["type"] == "passive":
		_apply_passive_upgrade(data, new_lvl, player)

func _apply_weapon_upgrade(data: Dictionary, level: int, player: Player) -> void:
	if not is_instance_valid(player) or not player.weapons_container:
		return
		
	var id: String = data["id"]
	if level == 1:
		# 신규 무기 생성 및 장착
		var scene: PackedScene = data["scene"] as PackedScene
		if scene:
			var weapon_inst: Node2D = scene.instantiate() as Node2D
			weapon_inst.name = id.capitalize().replace(" ", "")
			player.weapons_container.add_child(weapon_inst)
	else:
		# 기존 무기 레벨업
		for child in player.weapons_container.get_children():
			if id == "magic_missile" and child is WeaponMagicMissile:
				(child as WeaponMagicMissile).upgrade()
			elif id == "garlic_aura" and child is WeaponGarlicAura:
				(child as WeaponGarlicAura).upgrade()
			elif id == "whip" and child is WeaponWhip:
				(child as WeaponWhip).upgrade()

func _apply_passive_upgrade(data: Dictionary, _level: int, player: Player) -> void:
	if not is_instance_valid(player):
		return
		
	var id: String = data["id"]
	match id:
		"boots":
			player.speed_multiplier += 0.15
		"gauntlet":
			player.damage_multiplier += 0.20
		"magnet":
			player.pickup_range_multiplier += 0.35
			player.update_pickup_range()

# --- 무기 진화 (Evolution) 시스템 ---
func check_evolution_available() -> Dictionary:
	for evo_key: String in evolutions.keys():
		var evo: Dictionary = evolutions[evo_key]
		if evo["is_evolved"]:
			continue
			
		var base_item: Dictionary = upgrades.get(evo["base_id"], {})
		var req_passive: Dictionary = upgrades.get(evo["req_passive"], {})
		
		# 진화 조건: 기본 무기 만렙(5) + 대응 패시브 1레벨 이상 보유
		if base_item.get("level", 0) >= base_item.get("max_level", 5) and req_passive.get("level", 0) >= 1:
			return evo
			
	return {}

func apply_evolution(evo_data: Dictionary, player: Player) -> void:
	var evo_id: String = evo_data["id"]
	if not evolutions.has(evo_id):
		return
		
	evolutions[evo_id]["is_evolved"] = true
	var base_id: String = evo_data["base_id"]
	
	if not is_instance_valid(player) or not player.weapons_container:
		return
		
	# 1. 기존 기본 무기 노드 제거
	for child in player.weapons_container.get_children():
		if base_id == "magic_missile" and child is WeaponMagicMissile:
			child.queue_free()
		elif base_id == "garlic_aura" and child is WeaponGarlicAura:
			child.queue_free()
		elif base_id == "whip" and child is WeaponWhip:
			child.queue_free()
			
	# 2. 진화 무기 인스턴스화 후 장착
	var scene: PackedScene = evo_data["scene"] as PackedScene
	if scene:
		var evolved_weapon: Node2D = scene.instantiate() as Node2D
		evolved_weapon.name = evo_id.capitalize().replace(" ", "")
		player.weapons_container.call_deferred("add_child", evolved_weapon)

func get_free_upgrade_for_chest(player: Player) -> Dictionary:
	# 진화 조건이 안 될 때 보물상자에서 보유 스킬 1개 즉시 강화
	var candidates: Array[Dictionary] = []
	for key: String in upgrades.keys():
		var data: Dictionary = upgrades[key]
		if data["level"] > 0 and data["level"] < data["max_level"]:
			candidates.append(data)
			
	if not candidates.is_empty():
		candidates.shuffle()
		var chosen: Dictionary = candidates[0]
		apply_upgrade(chosen["id"], player)
		return {
			"type": "upgrade",
			"title": chosen["title"],
			"desc": "보물상자의 축복으로 레벨이 1 증가했습니다! (Lv. %d)" % chosen["level"]
		}
	else:
		# 모든 보유 장비가 만렙이면 체력 회복
		if is_instance_valid(player):
			player.current_health = player.max_health
			player.health_changed.emit(player.current_health, player.max_health)
		return {
			"type": "heal",
			"title": "생명의 성배",
			"desc": "보물상자의 마력으로 모든 체력이 즉시 완전히 회복되었습니다!"
		}
