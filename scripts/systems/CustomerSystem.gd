## CustomerSystem.gd
## Müşteri spawn, sabır yönetimi ve tip sistemi. GDD §2

extends Node

# ── CONFIG ────────────────────────────────────────────────────────────────────
@export var customer_scene : PackedScene   ## res://scenes/CustomerNode.tscn

# ── STATE ─────────────────────────────────────────────────────────────────────
var max_stools    : int = 2
var max_queue     : int = 3
var current_level : int = 1

## Referanslar
var order_manager   : Node = null
var customer_parent : Node = null   ## CustomerContainer node'u

var _customers   : Dictionary = {}   ## customer_id → CustomerNode
var _next_id     : int        = 1
var _queue_ids   : Array      = []   ## Sıradaki customer_id'ler
var _seated_ids  : Array      = []   ## Oturan customer_id'ler

## customer_type → saniye (CUSTOMER_TYPES'tan otomatik başlatılır)
var _spawn_timers : Dictionary = {}

# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	for type_key in Constants.CUSTOMER_TYPES:
		_spawn_timers[type_key] = 0.0
	EventBus.order_seated.connect(_on_order_seated)
	EventBus.order_served.connect(_on_order_served)
	EventBus.order_cancelled.connect(_on_order_cancelled)
	EventBus.level_up.connect(_on_level_up)


func _process(delta: float) -> void:
	_update_spawn_timers(delta)


# ── SPAWN ─────────────────────────────────────────────────────────────────────
func _update_spawn_timers(delta: float) -> void:
	## CUSTOMER_TYPES'tan unlock_level ve spawn_interval okunur.
	## Yeni tip = sadece Constants.CUSTOMER_TYPES'a satır.
	for type_key in Constants.CUSTOMER_TYPES:
		var def : Dictionary = Constants.CUSTOMER_TYPES[type_key]
		if current_level < def["unlock_level"]:
			continue
		_spawn_timers[type_key] += delta
		if _spawn_timers[type_key] >= def["spawn_interval"]:
			_spawn_timers[type_key] = 0.0
			_try_spawn(type_key)


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
	var order_id : int = order_manager.create_order(id, node.customer_type, item_id)

	node.on_seated(order_id)
	order_manager.seat_order(order_id)


func _pick_item_for_type(customer_type: String) -> String:
	## GDD §3 — CUSTOMER_TYPES[type]["item_pool"] ve preferred_item'dan okur.
	##
	## item_pool boş   → tüm unlocked itemlar (regular davranışı)
	## preferred_weight > 0 → first=preferred, last=fallback (tourist davranışı)
	## weight = 0       → pool'dan rastgele (impatient davranışı)
	var def    : Dictionary = Constants.CUSTOMER_TYPES.get(customer_type, {})
	var pool   : Array      = def.get("item_pool", [])
	var weight : float      = def.get("preferred_weight", 0.0)

	if pool.is_empty():
		var available := _get_available_items()
		return available[randi() % available.size()]

	if weight > 0.0:
		## Preferred + fallback: pool[0] tercih, pool[-1] geri dönüş
		var preferred : String = pool[0]
		var fallback  : String = pool[-1]
		if _is_menu_unlocked(preferred) and randf() < weight:
			return preferred
		return fallback

	## Kısıtlı pool — unlock'lu olanlardan rastgele
	var unlocked := pool.filter(func(i: String) -> bool: return _is_menu_unlocked(i))
	if unlocked.is_empty():
		return _get_available_items().front()
	return unlocked[randi() % unlocked.size()]


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
func _on_order_seated(_customer_id: int) -> void:
	pass  ## CustomerNode kendi durumunu yönetiyor


func _on_order_served(customer_id: int) -> void:
	## Yeme bitti → müşteri ayrılır
	await get_tree().create_timer(Constants.EATING_DURATION_SEC).timeout
	_remove_customer(customer_id, "done")
	_try_seat_next()


func _on_order_cancelled(_customer_id: int, _reason: String) -> void:
	pass  ## _on_patience_timeout zaten halletti


func _on_level_up(new_level: int) -> void:
	current_level = new_level
