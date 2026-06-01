## test_progression_system.gd
## ProgressionSystem XP sayımı, level-up tetikleme ve serialize testleri.

extends GutTest

var progression : Node

func before_each() -> void:
	progression = preload("res://scripts/systems/ProgressionSystem.gd").new()
	add_child_autofree(progression)
	progression.current_level = 1
	progression.total_orders  = 0


# ── TOTAL ORDERS ──────────────────────────────────────────────────────────────

func test_add_orders_increments_total() -> void:
	EventBus.xp_gained.emit(1, 0)
	assert_eq(progression.total_orders, 1, "total_orders must increment by 1")


func test_add_multiple_orders() -> void:
	EventBus.xp_gained.emit(1, 0)
	EventBus.xp_gained.emit(1, 0)
	EventBus.xp_gained.emit(1, 0)
	assert_eq(progression.total_orders, 3)


# ── LEVEL UP ──────────────────────────────────────────────────────────────────

func test_level_up_at_threshold_emits_level_up_signal() -> void:
	watch_signals(EventBus)
	## Level 2 eşiği = 30 sipariş (Constants.LEVEL_THRESHOLDS[2])
	for i in range(30):
		EventBus.xp_gained.emit(1, 0)
	assert_signal_emitted(EventBus, "level_up",
		"level_up must be emitted when threshold is reached")


func test_level_up_increments_current_level() -> void:
	for i in range(30):
		EventBus.xp_gained.emit(1, 0)
	assert_eq(progression.current_level, 2,
		"current_level must be 2 after 30 orders")


func test_already_leveled_guard_no_double_emit() -> void:
	## 30 sipariş → level 2. Bir tane daha eklersek tekrar level_up olmamalı.
	for i in range(30):
		EventBus.xp_gained.emit(1, 0)
	watch_signals(EventBus)
	EventBus.xp_gained.emit(1, 0)
	assert_signal_emit_count(EventBus, "level_up", 0,
		"level_up must not fire again after already leveling up")


func test_multiple_thresholds_crossed_in_one_batch() -> void:
	## Doğrudan total_orders'ı atla, _check_level_up'ı manuel tetikle
	## Level 3 eşiği = 100 — birden 100'e çıkarsak level 2 ve 3 emit edilmeli
	watch_signals(EventBus)
	for i in range(100):
		EventBus.xp_gained.emit(1, 0)
	assert_eq(progression.current_level, 3,
		"Must reach level 3 after 100 orders")


# ── XP RATIO ──────────────────────────────────────────────────────────────────

func test_get_xp_ratio_at_level_start_is_zero() -> void:
	## Level 1, hiç sipariş yok → oran 0.0
	assert_almost_eq(progression.get_xp_ratio(), 0.0, 0.01)


func test_get_xp_ratio_at_halfway() -> void:
	## Level 1→2 eşiği 30; 15 sipariş → 0.5
	for i in range(15):
		EventBus.xp_gained.emit(1, 0)
	assert_almost_eq(progression.get_xp_ratio(), 0.5, 0.01,
		"15 of 30 orders must give 0.5 ratio")


func test_get_xp_ratio_at_max_level_is_one() -> void:
	## Level 5'te (max) oran 1.0 olmalı
	progression.current_level = 5
	progression.total_orders  = 500
	assert_almost_eq(progression.get_xp_ratio(), 1.0, 0.01,
		"Max level must return 1.0 ratio")


func test_no_level_up_beyond_max() -> void:
	progression.current_level = 5
	progression.total_orders  = 499
	watch_signals(EventBus)
	EventBus.xp_gained.emit(1, 0)
	assert_signal_emit_count(EventBus, "level_up", 0,
		"No level_up must fire beyond max level")


# ── SERIALIZE / DESERIALIZE ───────────────────────────────────────────────────

func test_serialize_returns_correct_keys() -> void:
	progression.current_level = 3
	progression.total_orders  = 120
	var data : Dictionary = progression.serialize()
	assert_eq(data["level"],        3)
	assert_eq(data["total_orders"], 120)


func test_deserialize_restores_state() -> void:
	progression.deserialize({"level": 4, "total_orders": 280})
	assert_eq(progression.current_level, 4)
	assert_eq(progression.total_orders,  280)


func test_deserialize_missing_keys_use_defaults() -> void:
	progression.deserialize({})
	assert_eq(progression.current_level, 1)
	assert_eq(progression.total_orders,  0)


func test_serialize_deserialize_roundtrip() -> void:
	progression.current_level = 2
	progression.total_orders  = 45
	var data := progression.serialize()
	progression.current_level = 1
	progression.total_orders  = 0
	progression.deserialize(data)
	assert_eq(progression.current_level, 2)
	assert_eq(progression.total_orders,  45)
