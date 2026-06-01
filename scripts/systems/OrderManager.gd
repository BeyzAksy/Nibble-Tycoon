## OrderManager.gd
## Sipariş durum makinası. GDD §6
##
## Durum geçişleri:
##   QUEUED → SEATED → COOKING → READY → EATING → DONE
##   QUEUED → CANCELLED_QUEUE   (sıra sabrı bitti)
##   SEATED → CANCELLED_ANGRY   (yemek sabrı bitti)

extends Node

# ── ENUM ─────────────────────────────────────────────────────────────────────
enum OrderState {
	QUEUED,
	SEATED,
	COOKING,
	READY,
	EATING,
	DONE,
	CANCELLED_QUEUE,
	CANCELLED_ANGRY,
}

# ── DATA STRUCTURE ────────────────────────────────────────────────────────────
class Order:
	var id            : int
	var customer_id   : int
	var customer_type : String   ## "regular" | "impatient" | "tourist"
	var item_id       : String
	var base_price    : int
	var state         : int = OrderState.QUEUED
	var queue_patience_ratio  : float = 1.0
	var food_patience_ratio   : float = 1.0
	var created_at    : float = 0.0

	func _init(
		p_id: int,
		p_customer_id: int,
		p_customer_type: String,
		p_item_id: String
	) -> void:
		id            = p_id
		customer_id   = p_customer_id
		customer_type = p_customer_type
		item_id       = p_item_id
		base_price    = Constants.MENU_ITEMS.get(p_item_id, {}).get("price", 0)
		created_at    = Time.get_ticks_msec() / 1000.0

## Referanslar
var chef_system    : Node = null
var economy_system : Node = null

# ── STATE ─────────────────────────────────────────────────────────────────────
var _orders        : Dictionary = {}   ## order_id → Order
var _order_queue   : Array      = []   ## QUEUED olanların id listesi (FIFO)
var _next_order_id : int        = 1

# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	pass


# ── CREATE ORDER ──────────────────────────────────────────────────────────────
func create_order(
	customer_id  : int,
	customer_type: String,
	item_id      : String
) -> int:
	var order := Order.new(_next_order_id, customer_id, customer_type, item_id)
	_orders[order.id] = order
	_order_queue.append(order.id)
	_next_order_id += 1

	EventBus.order_queued.emit(customer_id)
	return order.id


# ── STATE TRANSITIONS ─────────────────────────────────────────────────────────
func seat_order(order_id: int) -> void:
	var order := _get_order(order_id)
	if not order: return
	order.state = OrderState.SEATED
	_order_queue.erase(order_id)
	EventBus.order_seated.emit(order.customer_id)

	## Chef'e ilet
	if chef_system:
		chef_system.try_take_order()


func start_cooking(order_id: int) -> void:
	var order := _get_order(order_id)
	if not order: return
	order.state = OrderState.COOKING
	EventBus.order_cooking.emit(order.customer_id, order.item_id)


func mark_ready(order_id: int) -> void:
	var order := _get_order(order_id)
	if not order: return
	order.state = OrderState.READY
	EventBus.order_ready.emit(order.customer_id, order.item_id)


func start_eating(order_id: int) -> void:
	var order := _get_order(order_id)
	if not order: return
	order.state = OrderState.EATING
	EventBus.order_served.emit(order.customer_id)


func complete_order(order_id: int) -> void:
	var order := _get_order(order_id)
	if not order: return
	order.state = OrderState.DONE

	## Ödeme
	if economy_system:
		var chef_q : int = chef_system.chef_quality if chef_system else 1
		economy_system.process_order_done(
			order.base_price,
			order.food_patience_ratio,
			chef_q,
			order.customer_type
		)

	EventBus.xp_gained.emit(1, 0)   ## Her tamamlanan sipariş +1 XP
	_cleanup_order(order_id)


func cancel_order(order_id: int, reason: String) -> void:
	var order := _get_order(order_id)
	if not order: return

	match reason:
		"queue":
			order.state = OrderState.CANCELLED_QUEUE
			_order_queue.erase(order_id)
		"angry":
			order.state = OrderState.CANCELLED_ANGRY
			## −10 memnuniyet (SatisfactionSystem'da işlenir)

	EventBus.order_cancelled.emit(order.customer_id, reason)
	_cleanup_order(order_id)


# ── PATIENCE UPDATE (called from CustomerNode) ────────────────────────────────
func update_queue_patience(order_id: int, ratio: float) -> void:
	var order := _get_order(order_id)
	if order:
		order.queue_patience_ratio = ratio


func update_food_patience(order_id: int, ratio: float) -> void:
	var order := _get_order(order_id)
	if order:
		order.food_patience_ratio = ratio


# ── CHEF HELPERS ──────────────────────────────────────────────────────────────
func get_next_order_for_chef(chef_level: int) -> Order:
	## GDD §7.2 — Impatient priority bump (active at Chef Experience 4)
	## Searches _orders dict since seated orders are removed from _order_queue
	if chef_level >= 4:
		for id in _orders:
			var o : Order = _orders[id]
			if o and o.state == OrderState.SEATED \
					and o.customer_type == "impatient" \
					and o.food_patience_ratio < 0.25:
				return o

	## Default FIFO — _orders preserves insertion order in Godot 4
	for id in _orders:
		var o : Order = _orders[id]
		if o and o.state == OrderState.SEATED:
			return o
	return null


func get_seated_orders() -> Array:
	var result : Array = []
	for id in _orders:
		var o : Order = _orders[id]
		if o.state == OrderState.SEATED:
			result.append(o)
	return result


func get_order(order_id: int) -> Order:
	return _orders.get(order_id)


# ── HELPERS ───────────────────────────────────────────────────────────────────
func _get_order(order_id: int) -> Order:
	if not _orders.has(order_id):
		push_warning("OrderManager: Sipariş bulunamadı: %d" % order_id)
		return null
	return _orders[order_id]


func _cleanup_order(order_id: int) -> void:
	## Tamamlanan/iptal siparişleri belirli süre sonra sil
	await get_tree().create_timer(3.0).timeout
	_orders.erase(order_id)
