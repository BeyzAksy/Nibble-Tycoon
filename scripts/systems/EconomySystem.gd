## EconomySystem.gd
## Coin ve Gem yönetimi. EventBus sinyallerini dinler ve yayar.
## GDD §5 — Para Sistemi

extends Node

# ── STATE ─────────────────────────────────────────────────────────────────────
var coins : float = 0.0
var gems  : int   = 0

# ── SIGNALS ───────────────────────────────────────────────────────────────────
## Not: Geniş sinyal ihtiyacı EventBus'ta tanımlı. Burada lokal UI güncellemesi:
signal balance_changed(coins: float, gems: int)

# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	EventBus.coin_earned.connect(_on_coin_earned)
	EventBus.coin_spent.connect(_on_coin_spent)
	EventBus.gem_earned.connect(_on_gem_earned)
	EventBus.gem_spent.connect(_on_gem_spent)


# ── COIN ─────────────────────────────────────────────────────────────────────
func earn_coins(amount: float, source: String = "") -> void:
	coins += amount
	balance_changed.emit(coins, gems)
	EventBus.coin_earned.emit(amount, source)


func spend_coins(amount: float, target: String = "") -> bool:
	## False dönerse yeterli coin yok — UI'da shake efekti tetiklenir
	if coins < amount:
		EventBus.toast_requested.emit("Yeterli coin yok! 🪙", "error")
		return false
	coins -= amount
	balance_changed.emit(coins, gems)
	EventBus.coin_spent.emit(amount, target)
	return true


# ── GEM ──────────────────────────────────────────────────────────────────────
func earn_gems(amount: int, source: String = "") -> void:
	gems += amount
	balance_changed.emit(coins, gems)
	EventBus.gem_earned.emit(amount, source)


func spend_gems(amount: int, target: String = "") -> bool:
	if gems < amount:
		EventBus.toast_requested.emit("Yeterli gem yok! 💎", "error")
		return false
	gems -= amount
	balance_changed.emit(coins, gems)
	EventBus.gem_spent.emit(amount, target)
	return true


# ── ORDER COMPLETED ───────────────────────────────────────────────────────────
func process_order_done(
	base_price: int,
	patience_ratio: float,
	chef_quality: int,
	customer_type: String
) -> void:
	## GDD §5.2 formülleri
	var order_value := Constants.calc_order_value(base_price, chef_quality)

	## Impatient customer coin multiplier
	if customer_type == "impatient":
		order_value *= Constants.COIN_MULT_IMPATIENT

	var tip := Constants.calc_tip(base_price, patience_ratio, chef_quality)

	## Tourist tip bonus
	if customer_type == "tourist":
		tip *= Constants.TIP_MULT_TOURIST

	## Sinirli müşteri bahşiş düşürme (GDD §2.3)
	if patience_ratio < Constants.PATIENCE_NEUTRAL_THRESHOLD:
		tip *= 0.2
	elif patience_ratio < Constants.PATIENCE_HAPPY_THRESHOLD:
		tip *= 0.6

	var total := order_value + tip
	earn_coins(total, "order")


# ── HOURLY RATE CALCULATION ───────────────────────────────────────────────────
func calculate_hourly_rate(upgrade_system: Node) -> float:
	## GDD §10.3
	var spawn_interval  : float = _get_avg_spawn_interval(upgrade_system)
	var avg_order_value : float = _get_avg_order_value(upgrade_system)
	var chef_quality    : int   = upgrade_system.chef_quality
	var stool_count     : int   = upgrade_system.max_stools

	var customers_per_hour := 3600.0 / spawn_interval
	var order_val          := avg_order_value * (1.0 + chef_quality * Constants.ORDER_QUALITY_MULT)

	return (
		customers_per_hour
		* order_val
		* Constants.STOOL_UTILIZATION
		* Constants.FOOD_COST_FACTOR
	)


func _get_avg_spawn_interval(_us: Node) -> float:
	## Simple average — Regular + Impatient + Tourist mix at Lv3
	return (
		Constants.SPAWN_INTERVAL_REGULAR
		+ Constants.SPAWN_INTERVAL_IMPATIENT
		+ Constants.SPAWN_INTERVAL_TOURIST
	) / 3.0


func _get_avg_order_value(_us: Node) -> float:
	## Simple average over all current menu items (₺)
	var total := 0
	var count := 0
	for item in Constants.MENU_ITEMS.values():
		total += item["price"]
		count += 1
	return float(total) / max(count, 1)


# ── EventBus hooks (prevents double handling) ─────────────────────────────────
func _on_coin_earned(_amount: float, _source: String) -> void:
	pass  ## Zaten earn_coins içinde işleniyor

func _on_coin_spent(_amount: float, _target: String) -> void:
	pass

func _on_gem_earned(_amount: int, _source: String) -> void:
	pass

func _on_gem_spent(_amount: int, _target: String) -> void:
	pass
