## CustomerSystem.gd
## Müşteri spawn, sabır yönetimi ve tip sistemi. GDD §2

extends Node

# ── CONFIG ────────────────────────────────────────────────────────────────────
@export var customer_scene : PackedScene   ## res://scenes/CustomerNode.tscn

# ── STATE ─────────────────────────────────────────────────────────────────────
var max_stools   : int = 2
var max_queue    : int = 3
var current_level: int = 1

var _customers   : Dictionary = {}   ## customer_id → CustomerNode
var _next_id     : int        = 1
var _queue_ids   : Array      = []   ## Sıradaki customer_id'ler
var _seated_ids  : Array      = []   ## Oturan customer_id'ler

## Spawn timers
var _timer_regular   : float = 0.0
var _timer_impatient : float = 0.0
var _timer_tourist   : float = 0.0

## Referanslar
var order_manager   : Node = null
var customer_parent : Node = null   ## CustomerContainer node'u

# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	EventBus.order_seated.connect(_on_order_seated)
	EventBus.order_served.connect(_on_order_served)
	EventBus.order_cancelled.connect(_on_order_cancelled)
	EventBus.level_up.connect(_on_level_up)


func _process(delta: float) -> void:
	_update_spawn_timers(delta)


# ── SPAWN ─────────────────────────────────────────────────────────────────────
func _update_spawn_timers(delta: float) -> void:
	## Regular — her level'da aktif
	_timer_regular += delta
	if _timer_regular >= Constants.SPAWN_INTERVAL_REGULAR:
		_timer_regular = 0.0
		_try_spawn("regular")

	## Impatient — Level 2+
	if current_level >= 2:
		_timer_impatient += delta
		if _timer_impatient >= Constants.SPAWN_INTERVAL_IMPATIENT:
			_timer_impatient = 0.0
			_try_spawn("impatient")

	## Tourist — Level 3+
	if current_level >= 3:
		_timer_tourist += delta
		if _timer_tourist >= Constants.SPAWN_INTERVAL_TOURIST:
			_timer_tourist = 0.0
			_try_spawn("tourist")


func _try_spawn(customer_type: String) -> void:
	## Sıra doluysa spawn etme
	if _queue_ids.size() + _seated_ids.size() >= max_queue + max_stools:
		return

	var id := _next_id
	_next_id += 1

	## Müşteri node'unu oluştur
	if not customer_scene or not customer_parent:
		push_error("CustomerSystem: customer_scene veya customer_parent atanmamış!")
		return

	var node : Node = customer_scene.instantiate()
	customer_parent.add_child(node)

	node.setup(id, customer_type, order_manager, self)
	node.patience_timeout.connect(_on_patience_timeout.bind(id))

	_customers[id] = node
	_queue_ids.append(id)

	EventBus.customer_spawned.emit(id, customer_type)

	## Yer varsa hemen oturtur
	_try_seat_next()


# ── SEATING ───────────────────────────────────────────────────────────────────
func _try_seat_next() -> void:
	if _queue_ids.is_empty():
		return
	if _seated_ids.size() >= max_stools:
		return

	var id  : int  = _queue_ids.pop_front()
	var node: Node = _customers.get(id)
	if not node:
		return

	_seated_ids.append(id)

	## Sipariş oluştur
	var item_id := _pick_item_for_type(node.customer_type)
	var order_id := order_manager.create_order(id, node.customer_type, item_id)

	node.on_seated(order_id)
	order_manager.seat_order(order_id)


func _pick_item_for_type(customer_type: String) -> String:
	## GDD §3 — Hangi müşteri ne sipariş eder
	match customer_type:
		"impatient":
			## Only fast items: tea, pastry, sandwich
			var fast := ["tea", "pastry"]
			if _is_menu_unlocked("sandwich"):
				fast.append("sandwich")
			return fast[randi() % fast.size()]
		"tourist":
			## Prefers tea + sausage
			if _is_menu_unlocked("sausage") and randf() < 0.6:
				return "sausage"
			return "tea"
		_:  ## regular
			var available := _get_available_items()
			return available[randi() % available.size()]


func _get_available_items() -> Array:
	var items := ["tea", "pastry"]
	if _is_menu_unlocked("sandwich"):
		items.append("sandwich")
	if _is_menu_unlocked("sausage"):
		items.append("sausage")
	return items


func _is_menu_unlocked(item_id: String) -> bool:
	var item : Dictionary = Constants.MENU_ITEMS.get(item_id, {})
	return current_level >= item.get("unlock_level", 99)


# ── PATIENCE TIMER EVENTS ─────────────────────────────────────────────────────
func _on_patience_timeout(customer_id: int, timer_type: String) -> void:
	var node : Node = _customers.get(customer_id)
	if not node:
		return

	match timer_type:
		"queue":
			## Sıra sabrı bitti — coin kaybı yok
			order_manager.cancel_order(node.current_order_id, "queue")
			_remove_customer(customer_id, "queue")
		"food":
			## Yemek sabrı bitti — öfkeyle ayrılır
			order_manager.cancel_order(node.current_order_id, "angry")
			_remove_customer(customer_id, "angry")
			EventBus.toast_requested.emit("Müşteri kızarak ayrıldı! 😠 −10 memnuniyet", "error")


func _remove_customer(customer_id: int, reason: String) -> void:
	_queue_ids.erase(customer_id)
	_seated_ids.erase(customer_id)

	var node : Node = _customers.get(customer_id)
	if node:
		node.play_exit_animation(reason)
		await get_tree().create_timer(0.8).timeout
		node.queue_free()

	_customers.erase(customer_id)
	EventBus.customer_left.emit(customer_id)

	## Yeni müşteri oturtmayı dene
	_try_seat_next()


# ── EventBus connections ──────────────────────────────────────────────────────
func _on_order_seated(customer_id: int) -> void:
	pass  ## CustomerNode kendi durumunu yönetiyor


func _on_order_served(customer_id: int) -> void:
	## Yeme bitti → müşteri ayrılır
	await get_tree().create_timer(Constants.EATING_DURATION_SEC).timeout
	_remove_customer(customer_id, "done")
	_try_seat_next()


func _on_order_cancelled(customer_id: int, _reason: String) -> void:
	pass  ## _on_patience_timeout zaten halletti


func _on_level_up(new_level: int) -> void:
	current_level = new_level
