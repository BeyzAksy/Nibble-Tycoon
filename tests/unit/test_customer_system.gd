## test_customer_system.gd
## CustomerSystem CUSTOMER_TYPES data-driven refactor testleri. LI-56.

extends GutTest

const CustomerSystem = preload("res://scripts/systems/CustomerSystem.gd")
const OrderManager   = preload("res://scripts/systems/OrderManager.gd")

var system : CustomerSystem


func before_each() -> void:
	system = CustomerSystem.new()
	add_child_autofree(system)
	system.current_level = 1


# ── CUSTOMER_TYPES DICT ────────────────────────────────────────────────────────

func test_customer_types_has_regular() -> void:
	assert_true(Constants.CUSTOMER_TYPES.has("regular"),
		"CUSTOMER_TYPES must contain 'regular'")


func test_customer_types_has_impatient() -> void:
	assert_true(Constants.CUSTOMER_TYPES.has("impatient"),
		"CUSTOMER_TYPES must contain 'impatient'")


func test_customer_types_has_tourist() -> void:
	assert_true(Constants.CUSTOMER_TYPES.has("tourist"),
		"CUSTOMER_TYPES must contain 'tourist'")


func test_customer_types_regular_has_required_fields() -> void:
	var def : Dictionary = Constants.CUSTOMER_TYPES["regular"]
	assert_true(def.has("unlock_level"),    "regular: unlock_level")
	assert_true(def.has("spawn_interval"),  "regular: spawn_interval")
	assert_true(def.has("patience_queue"),  "regular: patience_queue")
	assert_true(def.has("patience_food"),   "regular: patience_food")
	assert_true(def.has("coin_mult"),       "regular: coin_mult")
	assert_true(def.has("tip_mult"),        "regular: tip_mult")
	assert_true(def.has("item_pool"),       "regular: item_pool")


func test_regular_unlocks_at_level_1() -> void:
	assert_eq(Constants.CUSTOMER_TYPES["regular"]["unlock_level"], 1)


func test_impatient_unlocks_at_level_2() -> void:
	assert_eq(Constants.CUSTOMER_TYPES["impatient"]["unlock_level"], 2)


func test_tourist_unlocks_at_level_3() -> void:
	assert_eq(Constants.CUSTOMER_TYPES["tourist"]["unlock_level"], 3)


func test_impatient_coin_mult_is_1_20() -> void:
	assert_almost_eq(
		Constants.CUSTOMER_TYPES["impatient"]["coin_mult"], 1.20, 0.001,
		"impatient coin_mult must be 1.20")


func test_tourist_tip_mult_is_1_30() -> void:
	assert_almost_eq(
		Constants.CUSTOMER_TYPES["tourist"]["tip_mult"], 1.30, 0.001,
		"tourist tip_mult must be 1.30")


func test_regular_coin_mult_is_1() -> void:
	assert_almost_eq(
		Constants.CUSTOMER_TYPES["regular"]["coin_mult"], 1.00, 0.001)


func test_regular_tip_mult_is_1() -> void:
	assert_almost_eq(
		Constants.CUSTOMER_TYPES["regular"]["tip_mult"], 1.00, 0.001)


# ── SPAWN TIMERS ───────────────────────────────────────────────────────────────

func test_spawn_timers_initialized_for_all_types() -> void:
	for type_key in Constants.CUSTOMER_TYPES:
		assert_true(system._spawn_timers.has(type_key),
			"_spawn_timers must have key: %s" % type_key)


func test_spawn_timers_start_at_zero() -> void:
	for type_key in Constants.CUSTOMER_TYPES:
		assert_almost_eq(system._spawn_timers[type_key], 0.0, 0.001,
			"timer for %s must start at 0" % type_key)


# ── UNLOCK LEVEL — spawn yalnızca unlock_level karşılandığında ─────────────────

func test_impatient_not_spawned_below_unlock_level() -> void:
	## Level 1'de impatient spawn timer artmamalı (unlock_level=2)
	system.current_level = 1
	var timer_before : float = system._spawn_timers.get("impatient", 0.0)
	system._update_spawn_timers(1.0)
	assert_almost_eq(
		system._spawn_timers["impatient"], timer_before, 0.001,
		"impatient timer must not advance at level 1")


func test_impatient_spawned_at_unlock_level() -> void:
	## Level 2'de impatient timer artmalı
	system.current_level = 2
	system._update_spawn_timers(1.0)
	assert_almost_eq(system._spawn_timers["impatient"], 1.0, 0.001,
		"impatient timer must advance at level 2")


func test_tourist_not_spawned_below_unlock_level() -> void:
	system.current_level = 2
	var timer_before : float = system._spawn_timers.get("tourist", 0.0)
	system._update_spawn_timers(1.0)
	assert_almost_eq(
		system._spawn_timers["tourist"], timer_before, 0.001,
		"tourist timer must not advance at level 2")


func test_regular_always_spawns() -> void:
	system.current_level = 1
	system._update_spawn_timers(1.0)
	assert_almost_eq(system._spawn_timers["regular"], 1.0, 0.001,
		"regular timer must always advance")


# ── ITEM SELECTION ─────────────────────────────────────────────────────────────

func test_regular_picks_tea_at_level_1() -> void:
	system.current_level = 1
	## At level 1 only tea and pastry are available
	var result := system._pick_item_for_type("regular")
	assert_true(result == "tea" or result == "pastry",
		"regular at level 1 must pick tea or pastry, got: " + result)


func test_impatient_picks_from_restricted_pool() -> void:
	system.current_level = 1
	var result := system._pick_item_for_type("impatient")
	assert_true(result == "tea" or result == "pastry",
		"impatient at level 1 must pick tea or pastry, got: " + result)


func test_impatient_never_picks_sausage() -> void:
	## Even if level is high enough to unlock sausage, impatient cannot pick it
	system.current_level = 5
	for i in range(20):
		var result := system._pick_item_for_type("impatient")
		assert_ne(result, "sausage",
			"impatient must never pick sausage (not in item_pool)")


func test_tourist_fallback_tea_when_sausage_locked() -> void:
	## Level 1 — sausage not unlocked → tourist always gets tea
	system.current_level = 1
	for i in range(10):
		var result := system._pick_item_for_type("tourist")
		assert_eq(result, "tea",
			"tourist with sausage locked must always get tea")


func test_unknown_type_fallback_to_available_items() -> void:
	system.current_level = 1
	var result := system._pick_item_for_type("vip")
	assert_true(result == "tea" or result == "pastry",
		"unknown type must fallback to available items")
