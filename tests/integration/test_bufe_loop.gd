## test_bufe_loop.gd
## Entegrasyon testi: Tam sipariş döngüsü.
## GDD §6 — QUEUED → SEATED → COOKING → READY → EATING → DONE
##
## Bu test real-time timer kullanmaz; durum makinasını doğrudan sürülür.
## Amaç: OrderManager + ChefSystem + EconomySystem'in birlikte çalışmasını doğrulamak.

extends GutTest

var economy : Node
var manager : Node
var chef    : Node

func before_each() -> void:
	economy = preload("res://scripts/systems/EconomySystem.gd").new()
	add_child_autofree(economy)
	economy.coins = 0.0

	manager = preload("res://scripts/systems/OrderManager.gd").new()
	add_child_autofree(manager)

	chef = preload("res://scripts/systems/ChefSystem.gd").new()
	add_child_autofree(chef)

	## Two-way reference setup
	manager.economy_system = economy
	manager.chef_system    = chef
	chef.order_manager     = manager


# ── FULL ORDER CYCLE (REGULAR) ────────────────────────────────────────────────

func test_full_order_cycle_earns_coins() -> void:
	## 1 — Create order (QUEUED)
	var order_id := manager.create_order(1, "regular", "tea")
	var order    := manager.get_order(order_id)
	assert_eq(order.state, OrderManager.OrderState.QUEUED, "Initial: QUEUED")

	## 2 — Seat (SEATED)
	manager.seat_order(order_id)
	order = manager.get_order(order_id)
	assert_eq(order.state, OrderManager.OrderState.SEATED, "seat_order → SEATED")

	## 3 — Start cooking (COOKING)
	manager.start_cooking(order_id)
	order = manager.get_order(order_id)
	assert_eq(order.state, OrderManager.OrderState.COOKING, "start_cooking → COOKING")

	## 4 — Ready (READY)
	manager.mark_ready(order_id)
	order = manager.get_order(order_id)
	assert_eq(order.state, OrderManager.OrderState.READY, "mark_ready → READY")

	## 5 — Start eating (EATING)
	manager.start_eating(order_id)
	order = manager.get_order(order_id)
	assert_eq(order.state, OrderManager.OrderState.EATING, "start_eating → EATING")

	## 6 — Complete (DONE) — coin payment triggered
	manager.complete_order(order_id)
	assert_true(economy.coins > 0.0,
		"Cycle complete → economy balance must increase")


func test_full_cycle_coin_equals_formula() -> void:
	## Tea (25₺), full patience, chef_quality=1, regular → calculate via formula
	var order_id := manager.create_order(1, "regular", "tea")
	manager.seat_order(order_id)
	manager.start_cooking(order_id)
	manager.mark_ready(order_id)

	## Set patience to full
	manager.update_food_patience(order_id, 1.0)
	manager.start_eating(order_id)
	manager.complete_order(order_id)

	## GDD §5.2 formula
	var expected_value := Constants.calc_order_value(25, 1)           ## 26.0
	var expected_tip   := Constants.calc_tip(25, 1.0, 1)              ## 3.79
	var expected_total := expected_value + expected_tip

	assert_almost_eq(economy.coins, expected_total, 0.5,
		"Regular customer, full patience → coins must match formula")


func test_impatient_cycle_gives_bonus_coins() -> void:
	## Impatient customer gives +20%% coin bonus
	var id_reg := manager.create_order(1, "regular", "tea")
	manager.seat_order(id_reg)
	manager.start_cooking(id_reg)
	manager.mark_ready(id_reg)
	manager.update_food_patience(id_reg, 1.0)
	manager.start_eating(id_reg)
	manager.complete_order(id_reg)
	var regular_coins := economy.coins

	economy.coins = 0.0

	var id_imp := manager.create_order(2, "impatient", "tea")
	manager.seat_order(id_imp)
	manager.start_cooking(id_imp)
	manager.mark_ready(id_imp)
	manager.update_food_patience(id_imp, 1.0)
	manager.start_eating(id_imp)
	manager.complete_order(id_imp)
	var impatient_coins := economy.coins

	assert_true(impatient_coins > regular_coins,
		"Impatient customer must give more coins than regular (GDD §2.1)")


func test_multiple_orders_accumulate_coins() -> void:
	## Verify coin accumulation after 3 completed orders
	for i in 3:
		var id := manager.create_order(i + 1, "regular", "tea")
		manager.seat_order(id)
		manager.start_cooking(id)
		manager.mark_ready(id)
		manager.update_food_patience(id, 1.0)
		manager.start_eating(id)
		manager.complete_order(id)

	## 3 × (26.0 + tip) — each order adds coins
	assert_true(economy.coins > 70.0,
		"3 orders must total more than 70₺")


# ── CANCEL SCENARIOS ──────────────────────────────────────────────────────────

func test_queue_cancel_does_not_add_coins() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.cancel_order(id, "queue")
	assert_almost_eq(economy.coins, 0.0, 0.01,
		"Queue cancel must not add coins")


func test_angry_cancel_does_not_add_coins() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.seat_order(id)
	manager.cancel_order(id, "angry")
	assert_almost_eq(economy.coins, 0.0, 0.01,
		"Angry cancel must not add coins")


# ── XP SIGNAL CYCLE ───────────────────────────────────────────────────────────

func test_complete_order_emits_xp_gained_signal() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.seat_order(id)
	manager.start_cooking(id)
	manager.mark_ready(id)
	manager.start_eating(id)
	watch_signals(EventBus)
	manager.complete_order(id)
	assert_signal_emitted(EventBus, "xp_gained",
		"xp_gained must fire when order cycle completes")


# ── CHEF SYSTEM INTEGRATION ───────────────────────────────────────────────────

func test_chef_cook_time_reduced_by_speed_multiplier() -> void:
	## Chef 2× speed → tea's 8s becomes 4s
	chef.speed_multiplier = 2.0
	var cook_time := chef._calc_cook_time(8.0, "tea")
	assert_almost_eq(cook_time, 4.0, 0.01,
		"2× speed → tea cook time must be 4s")
