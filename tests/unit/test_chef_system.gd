## test_chef_system.gd
## ChefSystem pişirme hızı, hız bostu ve slot yönetimi testleri.
## GDD §7 — Şef (Büfeci) Sistemi

extends GutTest

var chef    : Node
var manager : Node

func before_each() -> void:
	manager = preload("res://scripts/systems/OrderManager.gd").new()
	add_child_autofree(manager)

	chef = preload("res://scripts/systems/ChefSystem.gd").new()
	add_child_autofree(chef)
	chef.order_manager = manager
	manager.chef_system = chef

	## Default starting values
	chef.speed_multiplier = 1.0
	chef.chef_quality     = 1
	chef.slot_count       = 1
	chef._boost_active    = false


# ── COOK TIME CALCULATION ─────────────────────────────────────────────────────

func test_calc_cook_time_default_speed() -> void:
	## speed_multiplier = 1.0 → cook_time unchanged
	var result : float = chef._calc_cook_time(8.0, "tea")
	assert_almost_eq(result, 8.0, 0.01,
		"speed_mult 1.0 must not change cook time")


func test_calc_cook_time_with_speed_multiplier() -> void:
	chef.speed_multiplier = 1.15
	var result : float = chef._calc_cook_time(8.0, "tea")
	## expected = 8.0 / 1.15
	assert_almost_eq(result, 8.0 / 1.15, 0.01,
		"speed_mult 1.15 must proportionally reduce cook time")


func test_calc_cook_time_double_speed_halves_time() -> void:
	chef.speed_multiplier = 2.0
	var result : float = chef._calc_cook_time(10.0, "tea")
	assert_almost_eq(result, 5.0, 0.01,
		"2× speed must halve cook time")


func test_calc_cook_time_boost_halves_time() -> void:
	## Speed boost active: time is divided by (mult = 1/0.5 = 2)
	chef._boost_active = true
	var result : float = chef._calc_cook_time(10.0, "tea")
	## effective = 10 / (1.0 * (1.0/0.5)) = 10 / 2.0 = 5.0
	assert_almost_eq(result, 5.0, 0.01,
		"Speed boost must halve cook time")


func test_calc_cook_time_boost_stacks_with_speed_multiplier() -> void:
	chef.speed_multiplier = 1.15
	chef._boost_active    = true
	var result   : float = chef._calc_cook_time(8.0, "tea")
	var expected : float = 8.0 / (1.15 * (1.0 / ChefSystem.BOOST_MULTIPLIER))
	assert_almost_eq(result, expected, 0.01,
		"Speed boost and speed_mult must stack together")


# ── SPEED BOOST ───────────────────────────────────────────────────────────────

func test_activate_boost_sets_active() -> void:
	chef.activate_boost()
	assert_true(chef._boost_active, "activate_boost must set _boost_active to true")


func test_activate_boost_sets_duration() -> void:
	chef.activate_boost()
	assert_almost_eq(chef._boost_remaining, ChefSystem.BOOST_DURATION, 0.01,
		"activate_boost must set _boost_remaining to BOOST_DURATION")


func test_activate_boost_emits_toast() -> void:
	watch_signals(EventBus)
	chef.activate_boost()
	assert_signal_emitted(EventBus, "toast_requested",
		"Speed boost start must emit a toast signal")


# ── SLOT MANAGEMENT ───────────────────────────────────────────────────────────

func test_is_slot_busy_empty_slot_returns_false() -> void:
	assert_false(chef.is_slot_busy(0),
		"Empty slot → is_slot_busy must return false")


func test_is_slot_busy_out_of_range_returns_false() -> void:
	chef.slot_count = 1
	assert_false(chef.is_slot_busy(1),
		"slot_count=1 → slot 1 is out of range → must return false")


func test_get_slot_order_id_empty_returns_negative() -> void:
	var result := chef.get_slot_order_id(0)
	## null or -1 — empty slot
	assert_true(result == null or result == -1,
		"Empty slot must return null or -1")


func test_get_slot_order_id_out_of_range_returns_minus_one() -> void:
	chef.slot_count = 1
	assert_eq(chef.get_slot_order_id(5), -1,
		"Invalid slot index must return -1")


func test_slot_count_capped_at_max() -> void:
	## Sending slot_count=99 via _on_stats_updated must be capped
	chef._on_stats_updated(1.0, 1, 99)
	assert_eq(chef.slot_count, Constants.BUFFET_MAX_COOKING_SLOTS,
		"slot_count must not exceed BUFFET_MAX_COOKING_SLOTS")


# ── STAT UPDATE ───────────────────────────────────────────────────────────────

func test_on_stats_updated_sets_speed_multiplier() -> void:
	chef._on_stats_updated(1.30, 1, 1)
	assert_almost_eq(chef.speed_multiplier, 1.30, 0.001,
		"_on_stats_updated must update speed_multiplier")


func test_on_stats_updated_sets_chef_quality() -> void:
	chef._on_stats_updated(1.0, 3, 1)
	assert_eq(chef.chef_quality, 3,
		"_on_stats_updated must update chef_quality")


func test_on_stats_updated_sets_slot_count() -> void:
	chef._on_stats_updated(1.0, 1, 2)
	assert_eq(chef.slot_count, 2,
		"_on_stats_updated must update slot_count")


# ── CHF_04 PRIORITY BUMP ──────────────────────────────────────────────────────

func test_chf04_upgrade_activates_priority_bump() -> void:
	assert_false(chef.priority_bump_active,
		"priority_bump_active must be false at start")
	chef._on_upgrade_purchased("CHF_04")
	assert_true(chef.priority_bump_active,
		"priority_bump_active must be true after CHF_04")


func test_other_upgrade_does_not_activate_priority_bump() -> void:
	chef._on_upgrade_purchased("KIT_01")
	assert_false(chef.priority_bump_active,
		"KIT_01 must not change priority_bump_active")
