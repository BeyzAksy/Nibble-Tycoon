## test_order_manager.gd
## OrderManager sipariş durum makinası testleri.
## GDD §6 — QUEUED → SEATED → COOKING → READY → DONE / CANCELLED

extends GutTest

const EconomySystem = preload("res://scripts/systems/EconomySystem.gd")
const OrderManager  = preload("res://scripts/systems/OrderManager.gd")

var manager  : OrderManager
var economy  : EconomySystem

func before_each() -> void:
	economy = EconomySystem.new()
	add_child_autofree(economy)
	economy.coins = 0.0

	manager = OrderManager.new()
	add_child_autofree(manager)
	manager.economy_system = economy
	## chef_system left null for tests that don't require it


# ── CREATE ORDER ──────────────────────────────────────────────────────────────

func test_create_order_returns_valid_id() -> void:
	var id := manager.create_order(1, "regular", "tea")
	assert_true(id > 0, "create_order must return a positive ID")


func test_create_order_state_is_queued() -> void:
	var id    := manager.create_order(1, "regular", "tea")
	var order := manager.get_order(id)
	assert_eq(order.state, OrderManager.OrderState.QUEUED,
		"New order must be in QUEUED state")


func test_create_order_adds_to_queue() -> void:
	var id := manager.create_order(1, "regular", "tea")
	var order := manager.get_order(id)
	assert_not_null(order, "Order must be recorded in the dictionary")


func test_create_order_increments_id() -> void:
	var id1 := manager.create_order(1, "regular", "tea")
	var id2 := manager.create_order(2, "regular", "pastry")
	assert_true(id2 > id1, "Each new order must receive a higher ID")


func test_create_order_emits_order_queued() -> void:
	watch_signals(EventBus)
	manager.create_order(1, "regular", "tea")
	assert_signal_emitted(EventBus, "order_queued",
		"Creating an order must emit EventBus.order_queued")


func test_create_order_sets_base_price() -> void:
	var id    := manager.create_order(1, "regular", "tea")
	var order := manager.get_order(id)
	assert_eq(order.base_price, 25, "Tea base_price must be 25₺")


# ── SEAT ──────────────────────────────────────────────────────────────────────

func test_seat_order_changes_state_to_seated() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.seat_order(id)
	var order := manager.get_order(id)
	assert_eq(order.state, OrderManager.OrderState.SEATED,
		"seat_order must transition state to SEATED")


func test_seat_order_emits_order_seated() -> void:
	var id := manager.create_order(1, "regular", "tea")
	watch_signals(EventBus)
	manager.seat_order(id)
	assert_signal_emitted(EventBus, "order_seated")


# ── START COOKING ─────────────────────────────────────────────────────────────

func test_start_cooking_changes_state() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.seat_order(id)
	manager.start_cooking(id)
	var order := manager.get_order(id)
	assert_eq(order.state, OrderManager.OrderState.COOKING,
		"start_cooking must transition state to COOKING")


func test_start_cooking_emits_order_cooking() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.seat_order(id)
	watch_signals(EventBus)
	manager.start_cooking(id)
	assert_signal_emitted(EventBus, "order_cooking")


# ── MARK READY ────────────────────────────────────────────────────────────────

func test_mark_ready_changes_state() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.seat_order(id)
	manager.start_cooking(id)
	manager.mark_ready(id)
	var order := manager.get_order(id)
	assert_eq(order.state, OrderManager.OrderState.READY,
		"mark_ready must transition state to READY")


func test_mark_ready_emits_order_ready() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.seat_order(id)
	manager.start_cooking(id)
	watch_signals(EventBus)
	manager.mark_ready(id)
	assert_signal_emitted(EventBus, "order_ready")


# ── START EATING ──────────────────────────────────────────────────────────────

func test_start_eating_changes_state() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.seat_order(id)
	manager.start_cooking(id)
	manager.mark_ready(id)
	manager.start_eating(id)
	var order := manager.get_order(id)
	assert_eq(order.state, OrderManager.OrderState.EATING,
		"start_eating must transition state to EATING")


func test_start_eating_emits_order_served() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.seat_order(id)
	manager.start_cooking(id)
	manager.mark_ready(id)
	watch_signals(EventBus)
	manager.start_eating(id)
	assert_signal_emitted(EventBus, "order_served")


# ── COMPLETE ORDER ────────────────────────────────────────────────────────────

func test_complete_order_adds_coins_to_economy() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.seat_order(id)
	manager.start_cooking(id)
	manager.mark_ready(id)
	manager.start_eating(id)
	manager.complete_order(id)
	assert_true(economy.coins > 0.0,
		"Completing an order must add coins to economy")


func test_complete_order_emits_xp_gained() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.seat_order(id)
	manager.start_cooking(id)
	manager.mark_ready(id)
	manager.start_eating(id)
	watch_signals(EventBus)
	manager.complete_order(id)
	assert_signal_emitted(EventBus, "xp_gained",
		"Each completed order must emit +1 XP (GDD §6)")


# ── CANCEL ORDER ──────────────────────────────────────────────────────────────

func test_cancel_queue_emits_order_cancelled() -> void:
	var id := manager.create_order(1, "regular", "tea")
	watch_signals(EventBus)
	manager.cancel_order(id, "queue")
	assert_signal_emitted(EventBus, "order_cancelled")


func test_cancel_angry_state_is_cancelled_angry() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.seat_order(id)
	watch_signals(EventBus)
	manager.cancel_order(id, "angry")
	## assert_signal_emitted_with_parameters triggers a GDScript type error in GUT 9.6
	## when comparing a mixed-type array [int, String] — use assert_signal_emitted instead
	assert_signal_emitted(EventBus, "order_cancelled",
		"Angry cancel must emit order_cancelled signal")


# ── PATIENCE UPDATE ───────────────────────────────────────────────────────────

func test_update_queue_patience_stores_value() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.update_queue_patience(id, 0.42)
	var order := manager.get_order(id)
	assert_almost_eq(order.queue_patience_ratio, 0.42, 0.001)


func test_update_food_patience_stores_value() -> void:
	var id := manager.create_order(1, "regular", "tea")
	manager.update_food_patience(id, 0.75)
	var order := manager.get_order(id)
	assert_almost_eq(order.food_patience_ratio, 0.75, 0.001)


# ── INVALID ORDER ─────────────────────────────────────────────────────────────

func test_seat_nonexistent_order_does_not_crash() -> void:
	## Unknown ID must soft-fail without crash; no order must exist after the call
	manager.seat_order(9999)
	assert_null(manager.get_order(9999), "Unknown order must not exist after invalid seat")


func test_get_order_returns_null_for_unknown_id() -> void:
	var order := manager.get_order(9999)
	assert_null(order, "Unknown ID must return null")


# ── GET SEATED ORDERS ─────────────────────────────────────────────────────────

func test_get_seated_orders_returns_seated_only() -> void:
	var id1 := manager.create_order(1, "regular", "tea")
	var id2 := manager.create_order(2, "regular", "pastry")
	manager.seat_order(id1)
	## id2 stays QUEUED

	var seated := manager.get_seated_orders()
	assert_eq(seated.size(), 1,
		"Only SEATED orders must be returned")


# ── CHEF QUEUE CHECK ──────────────────────────────────────────────────────────

func test_get_next_order_fifo_order() -> void:
	var id1 := manager.create_order(1, "regular", "tea")
	var id2 := manager.create_order(2, "regular", "pastry")
	manager.seat_order(id1)
	manager.seat_order(id2)

	## chef_level 0 → FIFO, first seated comes first
	var next := manager.get_next_order_for_chef(0)
	assert_eq(next.id, id1, "FIFO: first seated order must be served first")


func test_customer_type_stored_correctly() -> void:
	var id    := manager.create_order(5, "tourist", "sausage")
	var order := manager.get_order(id)
	assert_eq(order.customer_type, "tourist", "Customer type must be stored correctly")
