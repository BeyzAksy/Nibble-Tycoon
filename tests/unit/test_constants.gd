## test_constants.gd
## Constants.gd içindeki formülleri ve sabitleri test eder.
## GDD §5.2 formülleri + §2.3 sabır eşikleri

extends GutTest

# ── PATIENCE COLOR ────────────────────────────────────────────────────────────

func test_patience_color_happy_returns_mint() -> void:
	var color := Constants.get_patience_color(0.80)
	assert_eq(color, Constants.PATIENCE_HIGH,
		"Patience 80%% → mint (happy)")

func test_patience_color_neutral_returns_butter() -> void:
	var color := Constants.get_patience_color(0.50)
	assert_eq(color, Constants.PATIENCE_MID,
		"Patience 50%% → butter (neutral)")

func test_patience_color_angry_returns_coral() -> void:
	var color := Constants.get_patience_color(0.20)
	assert_eq(color, Constants.PATIENCE_LOW,
		"Patience 20%% → coral (angry)")

func test_patience_color_at_happy_threshold() -> void:
	## Threshold: >= 0.65 → happy
	var color := Constants.get_patience_color(0.65)
	assert_eq(color, Constants.PATIENCE_HIGH,
		"Patience exactly 65%% → at happy threshold, must be mint")

func test_patience_color_just_below_happy_threshold() -> void:
	var color := Constants.get_patience_color(0.64)
	assert_eq(color, Constants.PATIENCE_MID,
		"Patience 64%% → neutral zone, must be butter")

func test_patience_color_at_neutral_threshold() -> void:
	var color := Constants.get_patience_color(0.35)
	assert_eq(color, Constants.PATIENCE_MID,
		"Patience exactly 35%% → at neutral threshold, must be butter")

func test_patience_color_just_below_neutral_threshold() -> void:
	var color := Constants.get_patience_color(0.34)
	assert_eq(color, Constants.PATIENCE_LOW,
		"Patience 34%% → angry zone, must be coral")

# ── ORDER VALUE FORMULA ────────────────────────────────────────────────────────
## GDD §5.2: order_value = base_price × (1 + chef_quality × 0.04)

func test_order_value_no_quality_bonus() -> void:
	var val := Constants.calc_order_value(25, 1)
	assert_almost_eq(val, 26.0, 0.01,
		"Tea (25₺) + chef_quality 1 → 25 × 1.04 = 26.0")

func test_order_value_high_quality() -> void:
	var val := Constants.calc_order_value(25, 8)
	assert_almost_eq(val, 33.0, 0.01,
		"Tea (25₺) + chef_quality 8 → 25 × 1.32 = 33.0")

func test_order_value_pastry_base() -> void:
	var val := Constants.calc_order_value(40, 1)
	assert_almost_eq(val, 41.6, 0.01,
		"Pastry (40₺) + chef_quality 1 → 40 × 1.04 = 41.6")

func test_order_value_zero_quality() -> void:
	## Theoretical: quality 0 → base price unchanged
	var val := Constants.calc_order_value(65, 0)
	assert_almost_eq(val, 65.0, 0.01,
		"Sandwich (65₺) + chef_quality 0 → price must not change")

# ── TIP FORMULA ────────────────────────────────────────────────────────────────
## GDD §5.2: tip = base_price × patience_ratio × 0.15 + chef_quality × 0.04

func test_tip_happy_customer() -> void:
	## Tea, 100% patience, quality 1
	var tip := Constants.calc_tip(25, 1.0, 1)
	assert_almost_eq(tip, 25 * 1.0 * 0.15 + 1 * 0.04, 0.01,
		"Happy customer must give maximum tip")

func test_tip_angry_customer() -> void:
	## Tea, 10% patience, quality 1
	var tip := Constants.calc_tip(25, 0.10, 1)
	assert_almost_eq(tip, 25 * 0.10 * 0.15 + 1 * 0.04, 0.01,
		"Angry customer must give minimum tip")

func test_tip_zero_patience() -> void:
	## Cancel case — patience 0 (only quality contribution remains)
	var tip := Constants.calc_tip(25, 0.0, 1)
	assert_almost_eq(tip, 0.0 + 1 * 0.04, 0.01,
		"Patience 0 → only quality contribution should remain")

func test_tip_high_quality() -> void:
	var tip := Constants.calc_tip(75, 0.80, 6)
	var expected := 75 * 0.80 * 0.15 + 6 * 0.04
	assert_almost_eq(tip, expected, 0.01,
		"Sausage, 80%% patience, quality 6 → formula must be correct")

# ── OFFLINE CALCULATION ────────────────────────────────────────────────────────
## GDD §10.3

func test_offline_earnings_basic() -> void:
	## hourly_rate=1350, 4 hours, efficiency=0.30
	var earn := Constants.calc_offline_earnings(1350.0, 4.0, 4.0, 0.30)
	assert_almost_eq(earn, 1350.0 * 4.0 * 0.30, 0.01,
		"Level 1 offline earnings must match GDD table")

func test_offline_earnings_capped_by_max_hours() -> void:
	## 8 hours elapsed but max 4 hours — only 4 hours should be calculated
	var earn := Constants.calc_offline_earnings(1350.0, 8.0, 4.0, 0.30)
	var expected := 1350.0 * 4.0 * 0.30
	assert_almost_eq(earn, expected, 0.01,
		"Exceeding max hours must apply cap")

func test_offline_earnings_not_negative() -> void:
	var earn := Constants.calc_offline_earnings(0.0, 6.0, 12.0, 0.38)
	assert_eq(earn, 0.0, "Hourly rate 0 → earnings must be 0")

func test_offline_earnings_level3_gdd_table() -> void:
	## GDD §5.3: Level 3 → 4.788₺/hour, max 8 hours → ~38.304₺
	var earn := Constants.calc_offline_earnings(4788.0 / 0.38, 8.0, 8.0, 0.38)
	assert_almost_eq(earn, 38304.0, 50.0,   ## 50₺ tolerance
		"Level 3 offline must match GDD table")

# ── MENU_ITEMS CHECK ──────────────────────────────────────────────────────────

func test_menu_items_tea_exists() -> void:
	assert_true(Constants.MENU_ITEMS.has("tea"), "Tea must be in menu")

func test_menu_items_tea_price() -> void:
	assert_eq(Constants.MENU_ITEMS["tea"]["price"], 25,
		"Tea price must be 25₺")

func test_menu_items_tea_cook_time() -> void:
	assert_eq(Constants.MENU_ITEMS["tea"]["cook_time"], 8,
		"Tea cook time must be 8 seconds")

func test_menu_items_all_have_required_keys() -> void:
	var required := ["name", "price", "cook_time", "unlock_level"]
	for item_id in Constants.MENU_ITEMS:
		var item : Dictionary = Constants.MENU_ITEMS[item_id]
		for key in required:
			if item_id != "daily_special":   ## Special item — some fields are zero
				assert_true(item.has(key),
					"Menu item '%s' missing field: %s" % [item_id, key])

func test_menu_items_unlock_levels_valid() -> void:
	for item_id in Constants.MENU_ITEMS:
		var lv : int = Constants.MENU_ITEMS[item_id].get("unlock_level", 0)
		assert_true(lv >= 1 and lv <= 5,
			"'%s' unlock_level must be between 1–5, got: %d" % [item_id, lv])

# ── LEVEL THRESHOLDS ──────────────────────────────────────────────────────────

func test_level_thresholds_ordered() -> void:
	var prev := -1
	for lv in [1, 2, 3, 4, 5]:
		var threshold : int = Constants.LEVEL_THRESHOLDS[lv]
		assert_true(threshold > prev,
			"Level %d threshold must be greater than previous level" % lv)
		prev = threshold

func test_level_1_threshold_is_zero() -> void:
	assert_eq(Constants.LEVEL_THRESHOLDS[1], 0,
		"Level 1 threshold must be 0 (starting point)")

func test_level_5_threshold_is_500() -> void:
	assert_eq(Constants.LEVEL_THRESHOLDS[5], 500,
		"Level 5 threshold must be 500 orders (GDD §12.1)")

# ── BUFFET CONSTANTS ──────────────────────────────────────────────────────────

func test_max_stools_is_4() -> void:
	assert_eq(Constants.BUFFET_MAX_STOOLS, 4)

func test_max_queue_is_7() -> void:
	assert_eq(Constants.BUFFET_MAX_QUEUE, 7)

func test_max_cooking_slots_is_2() -> void:
	assert_eq(Constants.BUFFET_MAX_COOKING_SLOTS, 2)

func test_offline_efficiency_range() -> void:
	assert_true(Constants.MIN_OFFLINE_EFFICIENCY < Constants.MAX_OFFLINE_EFFICIENCY,
		"Min efficiency must be less than max")
	assert_almost_eq(Constants.MIN_OFFLINE_EFFICIENCY, 0.30, 0.001)
	assert_almost_eq(Constants.MAX_OFFLINE_EFFICIENCY, 0.45, 0.001)
