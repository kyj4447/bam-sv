class_name SaveManager
extends RefCounted

const SAVE_PATH: String = "user://save_data.json"

static var _instance: SaveManager = null

static func get_instance() -> SaveManager:
	if _instance == null:
		_instance = SaveManager.new()
		_instance.load_data()
	return _instance

var gold: int = 0
var upgrades: Dictionary = {
	"might": 0,    # 공격력 (+8% per Lv)
	"health": 0,   # 최대 체력 (+15 HP per Lv)
	"speed": 0,    # 이동속도 (+6% per Lv)
	"magnet": 0    # 자석범위 (+12% per Lv)
}

const UPGRADE_CONFIGS: Dictionary = {
	"might": {
		"title": "공격력 강화",
		"desc": "기본 공격력 +8% 증가",
		"base_cost": 100,
		"cost_multiplier": 1.5,
		"max_level": 5
	},
	"health": {
		"title": "체력 강화",
		"desc": "최대 체력 +15 HP 증가",
		"base_cost": 80,
		"cost_multiplier": 1.5,
		"max_level": 5
	},
	"speed": {
		"title": "이동속도 강화",
		"desc": "기본 이동속도 +6% 증가",
		"base_cost": 80,
		"cost_multiplier": 1.5,
		"max_level": 5
	},
	"magnet": {
		"title": "마력 자석 강화",
		"desc": "아이템 흡수 반경 +12% 증가",
		"base_cost": 60,
		"cost_multiplier": 1.5,
		"max_level": 5
	}
}

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
		
	var content := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(content)
	if err == OK and json.data is Dictionary:
		var data: Dictionary = json.data
		gold = int(data.get("gold", 0))
		var loaded_upgrades: Dictionary = data.get("upgrades", {})
		for key in upgrades.keys():
			if loaded_upgrades.has(key):
				upgrades[key] = int(loaded_upgrades[key])

func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
		
	var data: Dictionary = {
		"gold": gold,
		"upgrades": upgrades
	}
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func add_gold(amount: int) -> void:
	gold += amount
	save_data()

func get_upgrade_level(id: String) -> int:
	return upgrades.get(id, 0)

func get_upgrade_cost(id: String) -> int:
	var cfg: Dictionary = UPGRADE_CONFIGS.get(id, {})
	var lvl: int = get_upgrade_level(id)
	var base_cost: int = cfg.get("base_cost", 100)
	var multiplier: float = cfg.get("cost_multiplier", 1.5)
	return int(round(base_cost * pow(multiplier, lvl)))

func can_afford(id: String) -> bool:
	var cfg: Dictionary = UPGRADE_CONFIGS.get(id, {})
	var max_lvl: int = cfg.get("max_level", 5)
	if get_upgrade_level(id) >= max_lvl:
		return false
	return gold >= get_upgrade_cost(id)

func buy_upgrade(id: String) -> bool:
	if not can_afford(id):
		return false
	gold -= get_upgrade_cost(id)
	upgrades[id] = get_upgrade_level(id) + 1
	save_data()
	return true

# 보너스 배율/값 계산
func get_might_bonus() -> float:
	return 1.0 + float(get_upgrade_level("might")) * 0.08

func get_health_bonus() -> float:
	return float(get_upgrade_level("health")) * 15.0

func get_speed_bonus() -> float:
	return 1.0 + float(get_upgrade_level("speed")) * 0.06

func get_magnet_bonus() -> float:
	return 1.0 + float(get_upgrade_level("magnet")) * 0.12
