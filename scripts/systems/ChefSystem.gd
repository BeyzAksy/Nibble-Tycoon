## ChefSystem.gd
## Şef otomasyon motoru. GDD §7 — Şef (Büfeci) Sistemi
##
## Şef Level 1'den itibaren tamamen otonomdur.
## Ocak slot sayısı upgrade ile 1→2 artar.

extends Node

# ── CONFIG ────────────────────────────────────────────────────────────────────
@export var check_interval : float = 0.5   ## Kaç saniyede bir sıra kontrol edilir

# ── STATE ─────────────────────────────────────────────────────────────────────
var speed_multiplier : float = 1.0
var chef_quality     : int   = 1
var slot_count       : int   = 1   ## Upgrade ile 2'ye çıkar
var priority_bump_active : bool = false   ## CHF_04 ile aktif

## Her slot: null ya da pişirilen order_id
var _cooking_slots : Array = [null, null]
var _check_timer   : float = 0.0

## Speed boost state
var _boost_active      : bool  = false
var _boost_remaining   : float = 0.0
const BOOST_DURATION   := 300.0   ## 5 dakika
const BOOST_MULTIPLIER := 0.5     ## Pişirme süresi ×0.5 (yarıya iner)

## Referanslar
var order_manager : Node = null


# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
	EventBus.chef_stats_updated.connect(_on_stats_updated)


func _process(delta: float) -> void:
	_check_timer += delta
	if _check_timer >= check_interval:
		_check_timer = 0.0
		try_take_order()

	## Boost timer countdown
	if _boost_active:
		_boost_remaining -= delta
		EventBus.chef_boost_tick.emit(_boost_remaining)
		if _boost_remaining <= 0.0:
			_boost_active = false
			EventBus.toast_requested.emit("Hız Bostu bitti!", "warning")


# ── QUEUE CHECK ───────────────────────────────────────────────────────────────
func try_take_order() -> void:
	## GDD §7.2 pseudocode implementasyonu
	for i in slot_count:
		if _cooking_slots[i] == null:
			var order = order_manager.get_next_order_for_chef(
				4 if priority_bump_active else 0
			)
			if order:
				_start_cooking_slot(i, order)


func _start_cooking_slot(slot_index: int, order) -> void:
	_cooking_slots[slot_index] = order.id
	order_manager.start_cooking(order.id)

	## GDD §7.3 — Pişirme süresi
	var base_time : float = Constants.MENU_ITEMS.get(order.item_id, {}).get("cook_time", 10.0)
	var effective : float = _calc_cook_time(base_time, order.item_id)

	EventBus.chef_slot_started_cooking.emit(slot_index, order.id, order.item_id, effective)

	## Timer ile bekleme
	await get_tree().create_timer(effective).timeout
	_finish_slot(slot_index, order.id)


func _finish_slot(slot_index: int, order_id: int) -> void:
	_cooking_slots[slot_index] = null
	order_manager.mark_ready(order_id)
	EventBus.chef_slot_finished.emit(slot_index, order_id)

	## Hemen yeni sıra kontrol
	try_take_order()


# ── COOK TIME CALCULATION ─────────────────────────────────────────────────────
func _calc_cook_time(base_time: float, item_id: String) -> float:
	var mult := speed_multiplier

	## Şef Ustalaşma (CHF_05) — Büfe itemlarına +%20 hız (tüm büfe itemı)
	## speed_multiplier içinde zaten ekleniyor (UpgradeSystem._apply_effect)

	## Speed boost active: halve effective cook time
	if _boost_active:
		mult *= (1.0 / BOOST_MULTIPLIER)

	return base_time / mult


# ── SPEED BOOST ───────────────────────────────────────────────────────────────
func activate_boost() -> void:
	## Reklam izlendikten sonra BufeScene tarafından çağrılır
	_boost_active    = true
	_boost_remaining = BOOST_DURATION
	EventBus.toast_requested.emit("⚡ Hız Bostu aktif! 5 dakika", "reward")


# ── STAT UPDATE ───────────────────────────────────────────────────────────────
func _on_upgrade_purchased(upgrade_id: String) -> void:
	if upgrade_id == "CHF_04":
		priority_bump_active = true


func _on_stats_updated(new_speed: float, new_quality: int, new_slots: int) -> void:
	speed_multiplier = new_speed
	chef_quality     = new_quality
	slot_count       = min(new_slots, Constants.BUFFET_MAX_COOKING_SLOTS)


# ── STATE QUERIES ─────────────────────────────────────────────────────────────
func is_slot_busy(slot_index: int) -> bool:
	return slot_index < slot_count and _cooking_slots[slot_index] != null


func get_slot_order_id(slot_index: int) -> int:
	if slot_index >= slot_count:
		return -1
	var val = _cooking_slots[slot_index]
	return val if val != null else -1
