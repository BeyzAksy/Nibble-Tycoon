## UpgradeSystem.gd
## Tüm upgrade satın alma, kilit kontrolü ve stat yönetimi.
## GDD §8 — Upgrade Ağacı

extends Node

# ── UPGRADE DEFINITIONS ───────────────────────────────────────────────────────
## Her upgrade: id, maliyet, unlock_level, unlock_cond (opsiyonel), efekt
const UPGRADE_DEFS := {
	## KITCHEN
	"KIT_01": {
		"category": "kitchen", "name": "Ocak Hızı 1",
		"cost": 300, "unlock_level": 1, "effect": "speed",
	},
	"KIT_02": {
		"category": "kitchen", "name": "Ocak Hızı 2",
		"cost": 1200, "unlock_level": 2, "requires": "KIT_01", "effect": "speed",
	},
	"KIT_03": {
		"category": "kitchen", "name": "2. Ocak Slotu",
		"cost": 3500, "unlock_level": 3, "requires": "KIT_02", "effect": "slot",
	},
	"KIT_04": {
		"category": "kitchen", "name": "Malzeme Kalitesi 1",
		"cost": 8000, "unlock_level": 4, "effect": "tip",
	},
	"KIT_05": {
		"category": "kitchen", "name": "Özel Tarif",
		"cost": 20000, "unlock_level": 5, "effect": "price",
	},
	## COUNTER
	"CNT_01": {
		"category": "counter", "name": "2. Tabure",
		"cost": 250, "unlock_level": 1, "effect": "stool",
	},
	"CNT_02": {
		"category": "counter", "name": "3. Tabure",
		"cost": 900, "unlock_level": 2, "requires": "CNT_01", "effect": "stool",
	},
	"CNT_03": {
		"category": "counter", "name": "Sıra Genişletme 1",
		"cost": 700, "unlock_level": 2, "effect": "queue",
	},
	"CNT_04": {
		"category": "counter", "name": "Sıra Genişletme 2",
		"cost": 4000, "unlock_level": 4, "requires": "CNT_03", "effect": "queue",
	},
	## CHEF
	"CHF_01": {
		"category": "chef", "name": "Şef Deneyimi 1",
		"cost": 400, "unlock_level": 1, "effect": "quality",
	},
	"CHF_02": {
		"category": "chef", "name": "Şef Deneyimi 2",
		"cost": 1500, "unlock_level": 2, "requires": "CHF_01", "effect": "quality",
	},
	"CHF_03": {
		"category": "chef", "name": "Şef Deneyimi 3",
		"cost": 4000, "unlock_level": 3, "requires": "CHF_02", "effect": "quality",
	},
	"CHF_04": {
		"category": "chef", "name": "Şef Deneyimi 4",
		"cost": 10000, "unlock_level": 4, "requires": "CHF_03",
		"effect": "quality_priority",
	},
	"CHF_05": {
		"category": "chef", "name": "Şef Ustalaşma",
		"cost": 25000, "unlock_level": 5, "requires": "CHF_04", "effect": "mastery",
	},
	## IDLE
	"IDL_01": {
		"category": "idle", "name": "Offline Paketi 1",
		"cost": 500, "unlock_level": 2, "effect": "offline_hours",
	},
	"IDL_02": {
		"category": "idle", "name": "Offline Paketi 2",
		"cost": 2000, "unlock_level": 3, "requires": "IDL_01", "effect": "offline_hours_eff",
	},
	"IDL_03": {
		"category": "idle", "name": "Offline Verim 1",
		"cost": 3000, "unlock_level": 3, "effect": "offline_eff",
	},
	"IDL_04": {
		"category": "idle", "name": "Offline Paketi 3",
		"cost": 7000, "unlock_level": 4, "requires": "IDL_02", "effect": "offline_hours",
	},
	"IDL_05": {
		"category": "idle", "name": "Offline Paketi 4",
		"cost": 15000, "unlock_level": 5, "requires": "IDL_04", "effect": "offline_hours_eff",
	},
	"IDL_06": {
		"category": "idle", "name": "Offline Verim 2",
		"cost": 12000, "unlock_level": 5, "effect": "offline_eff",
	},
}

# ── CURRENT STATS ─────────────────────────────────────────────────────────────
var speed_multiplier  : float = 1.00
var chef_quality      : int   = 1
var slot_count        : int   = 1
var max_stools        : int   = 2
var max_queue         : int   = 3
var max_offline_hours : float = 4.0
var offline_efficiency: float = Constants.MIN_OFFLINE_EFFICIENCY

## Satın alınan upgrade'lerin ID seti
var purchased : Dictionary = {}

## Referanslar — BufeScene._ready()'de set edilir
var economy_system  : Node = null
var offline_system  : Node = null
var customer_system : Node = null

# ── PURCHASE ──────────────────────────────────────────────────────────────────
func try_purchase(upgrade_id: String, current_level: int) -> bool:
	if not UPGRADE_DEFS.has(upgrade_id):
		push_error("UpgradeSystem: Bilinmeyen upgrade ID: %s" % upgrade_id)
		return false

	var def : Dictionary = UPGRADE_DEFS[upgrade_id]

	## Zaten satın alındı mı?
	if purchased.has(upgrade_id):
		EventBus.toast_requested.emit("Bu upgrade zaten aktif!", "warning")
		return false

	## Level kontrolü
	if current_level < def.get("unlock_level", 1):
		EventBus.toast_requested.emit("Bu upgrade için yeterli level yok.", "warning")
		return false

	## Bağımlılık kontrolü
	if def.has("requires") and not purchased.has(def["requires"]):
		var req_name : String = UPGRADE_DEFS[def["requires"]]["name"]
		EventBus.toast_requested.emit("Önce '%s' al!" % req_name, "warning")
		return false

	## Para kontrolü ve harcama
	if not economy_system.spend_coins(def["cost"], upgrade_id):
		return false

	## Upgrade uygula
	purchased[upgrade_id] = true
	_apply_effect(upgrade_id, def)

	## Sistemleri bilgilendir
	EventBus.upgrade_purchased.emit(upgrade_id)
	EventBus.chef_stats_updated.emit(speed_multiplier, chef_quality, slot_count)
	EventBus.toast_requested.emit("%s aktif! ✅" % def["name"], "success")

	return true


func _apply_effect(_id: String, def: Dictionary) -> void:
	match def.get("effect", ""):
		"speed":
			speed_multiplier += 0.15
		"slot":
			slot_count = min(slot_count + 1, Constants.BUFFET_MAX_COOKING_SLOTS)
		"tip":
			pass  ## EconomySystem formula'ya bakıyor, burada işaret yeterli
		"price":
			pass  ## ChefSystem/MenuItem'da base_price çarpanı uygulanır
		"stool":
			max_stools = min(max_stools + 1, Constants.BUFFET_MAX_STOOLS)
			if customer_system:
				customer_system.max_stools = max_stools
		"queue":
			max_queue = min(max_queue + 2, Constants.BUFFET_MAX_QUEUE)
			if customer_system:
				customer_system.max_queue = max_queue
		"quality":
			chef_quality += 1
		"quality_priority":
			chef_quality += 2
			## Impatient priority bump — ChefSystem reads this
		"mastery":
			chef_quality += 2
			speed_multiplier += 0.20   ## Büfe itemlarına özel
		"offline_hours":
			max_offline_hours = min(max_offline_hours + 2.0, 12.0)
			if offline_system:
				offline_system.max_offline_hours = max_offline_hours
		"offline_hours_eff":
			max_offline_hours = min(max_offline_hours + 2.0, 12.0)
			offline_efficiency = min(offline_efficiency + 0.04, Constants.MAX_OFFLINE_EFFICIENCY)
			_sync_offline()
		"offline_eff":
			offline_efficiency = min(offline_efficiency + 0.05, Constants.MAX_OFFLINE_EFFICIENCY)
			_sync_offline()


func _sync_offline() -> void:
	if offline_system:
		offline_system.max_offline_hours  = max_offline_hours
		offline_system.offline_efficiency = offline_efficiency


# ── STATUS QUERIES ────────────────────────────────────────────────────────────
func get_status(upgrade_id: String, current_level: int) -> String:
	## "done" | "available" | "locked"
	if purchased.has(upgrade_id):
		return "done"
	var def : Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
	if current_level < def.get("unlock_level", 99):
		return "locked"
	if def.has("requires") and not purchased.has(def["requires"]):
		return "locked"
	return "available"


func get_upgrades_by_category(category: String) -> Array:
	var result : Array = []
	for id in UPGRADE_DEFS:
		if UPGRADE_DEFS[id]["category"] == category:
			result.append({"id": id, "def": UPGRADE_DEFS[id]})
	return result


# ── SAVE / LOAD ───────────────────────────────────────────────────────────────
func serialize() -> Dictionary:
	return {
		"purchased":          purchased.duplicate(),
		"speed_multiplier":   speed_multiplier,
		"chef_quality":       chef_quality,
		"slot_count":         slot_count,
		"max_stools":         max_stools,
		"max_queue":          max_queue,
		"max_offline_hours":  max_offline_hours,
		"offline_efficiency": offline_efficiency,
	}


func deserialize(data: Dictionary) -> void:
	purchased          = data.get("purchased",          {})
	speed_multiplier   = data.get("speed_multiplier",   1.0)
	chef_quality       = data.get("chef_quality",       1)
	slot_count         = data.get("slot_count",         1)
	max_stools         = data.get("max_stools",         2)
	max_queue          = data.get("max_queue",          3)
	max_offline_hours  = data.get("max_offline_hours",  4.0)
	offline_efficiency = data.get("offline_efficiency", Constants.MIN_OFFLINE_EFFICIENCY)
