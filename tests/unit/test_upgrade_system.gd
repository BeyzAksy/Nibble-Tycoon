## test_upgrade_system.gd
## UpgradeSystem satın alma, kilit kontrolü ve serialize testleri.

extends GutTest

const EconomySystem = preload("res://scripts/systems/EconomySystem.gd")
const UpgradeSystem = preload("res://scripts/systems/UpgradeSystem.gd")

var upgrade : UpgradeSystem
var economy : EconomySystem

func before_each() -> void:
	economy = EconomySystem.new()
	add_child_autofree(economy)
	economy.coins = 99999.0

	upgrade = UpgradeSystem.new()
	add_child_autofree(upgrade)
	upgrade.economy_system = economy

# ── STATUS QUERIES ────────────────────────────────────────────────────────────

func test_kit01_available_at_level1() -> void:
	var status := upgrade.get_status("KIT_01", 1)
	assert_eq(status, "available",
		"KIT_01 must be available at Level 1")

func test_kit02_locked_at_level1() -> void:
	var status := upgrade.get_status("KIT_02", 1)
	assert_eq(status, "locked",
		"KIT_02 must be locked at Level 1 (requires Level 2)")

func test_kit02_locked_without_kit01() -> void:
	## KIT_02 must remain locked at Level 2 without KIT_01
	var status := upgrade.get_status("KIT_02", 2)
	assert_eq(status, "locked",
		"KIT_02 must remain locked without KIT_01")

func test_kit02_available_after_kit01() -> void:
	upgrade.purchased["KIT_01"] = true
	var status := upgrade.get_status("KIT_02", 2)
	assert_eq(status, "available",
		"KIT_02 must be available after KIT_01 at Level 2")

func test_purchased_upgrade_is_done() -> void:
	upgrade.try_purchase("KIT_01", 1)
	var status := upgrade.get_status("KIT_01", 1)
	assert_eq(status, "done", "Purchased upgrade must report 'done'")

func test_kit05_locked_below_level5() -> void:
	var status := upgrade.get_status("KIT_05", 4)
	assert_eq(status, "locked", "KIT_05 must be locked below Level 5")

# ── PURCHASE ──────────────────────────────────────────────────────────────────

func test_purchase_kit01_succeeds() -> void:
	var ok := upgrade.try_purchase("KIT_01", 1)
	assert_true(ok, "KIT_01 purchase must succeed")

func test_purchase_deducts_coins() -> void:
	economy.coins = 1000.0
	upgrade.try_purchase("KIT_01", 1)   ## cost 300₺
	assert_almost_eq(economy.coins, 700.0, 0.01,
		"300₺ must be deducted")

func test_purchase_fails_insufficient_coins() -> void:
	economy.coins = 100.0
	var ok := upgrade.try_purchase("KIT_01", 1)   ## requires 300₺
	assert_false(ok, "Insufficient coins must fail purchase")

func test_purchase_same_upgrade_twice_fails() -> void:
	upgrade.try_purchase("KIT_01", 1)
	var ok2 := upgrade.try_purchase("KIT_01", 1)
	assert_false(ok2, "Same upgrade cannot be purchased twice")

func test_purchase_locked_upgrade_fails() -> void:
	var ok := upgrade.try_purchase("KIT_02", 1)  ## locked at Level 1
	assert_false(ok, "Locked upgrade must not be purchasable")

func test_purchase_emits_signal() -> void:
	watch_signals(EventBus)
	upgrade.try_purchase("KIT_01", 1)
	assert_signal_emitted(EventBus, "upgrade_purchased")

# ── EFFECT APPLICATION ────────────────────────────────────────────────────────

func test_kit01_increases_speed_multiplier() -> void:
	var before := upgrade.speed_multiplier
	upgrade.try_purchase("KIT_01", 1)
	assert_almost_eq(upgrade.speed_multiplier, before + 0.15, 0.001,
		"KIT_01 must increase speed_multiplier by 0.15")

func test_kit02_stacks_speed_multiplier() -> void:
	upgrade.purchased["KIT_01"] = true
	upgrade.speed_multiplier = 1.15
	upgrade.try_purchase("KIT_02", 2)
	assert_almost_eq(upgrade.speed_multiplier, 1.30, 0.001,
		"KIT_01+KIT_02 → speed_mult must equal 1.30 (GDD §7.3)")

func test_cnt01_increases_max_stools() -> void:
	var before := upgrade.max_stools
	upgrade.try_purchase("CNT_01", 1)
	assert_eq(upgrade.max_stools, before + 1,
		"CNT_01 must increase max_stools by 1")

func test_cnt_max_stools_capped() -> void:
	## Two stool upgrades should cap at 4
	upgrade.try_purchase("CNT_01", 1)   ## 2→3
	upgrade.purchased["CNT_01"] = true
	upgrade.max_stools = 3
	upgrade.try_purchase("CNT_02", 2)   ## 3→4
	assert_eq(upgrade.max_stools, Constants.BUFFET_MAX_STOOLS,
		"Max stools must not exceed %d" % Constants.BUFFET_MAX_STOOLS)

func test_chf01_increases_chef_quality() -> void:
	var before := upgrade.chef_quality
	upgrade.try_purchase("CHF_01", 1)
	assert_eq(upgrade.chef_quality, before + 1,
		"CHF_01 must increase chef_quality by 1")

func test_idl01_increases_max_offline_hours() -> void:
	var before := upgrade.max_offline_hours
	upgrade.try_purchase("IDL_01", 2)
	assert_true(upgrade.max_offline_hours > before,
		"IDL_01 must increase max_offline_hours")

func test_idl01_sets_6_hours() -> void:
	upgrade.try_purchase("IDL_01", 2)
	assert_almost_eq(upgrade.max_offline_hours, 6.0, 0.01,
		"IDL_01 must set max offline to 6 hours (GDD §8.4)")

# ── SERIALIZE / DESERIALIZE ───────────────────────────────────────────────────

func test_serialize_contains_purchased() -> void:
	upgrade.try_purchase("KIT_01", 1)
	var data := upgrade.serialize()
	assert_true(data.has("purchased"), "Serialize must contain 'purchased'")
	assert_true(data["purchased"].has("KIT_01"))

func test_serialize_contains_stats() -> void:
	var data := upgrade.serialize()
	assert_true(data.has("speed_multiplier"))
	assert_true(data.has("chef_quality"))
	assert_true(data.has("max_stools"))
	assert_true(data.has("max_offline_hours"))

func test_deserialize_restores_purchased() -> void:
	upgrade.try_purchase("KIT_01", 1)
	var data := upgrade.serialize()

	var upgrade2 := UpgradeSystem.new()
	add_child_autofree(upgrade2)
	upgrade2.deserialize(data)
	assert_true(upgrade2.purchased.has("KIT_01"),
		"KIT_01 must be purchased after deserialize")

func test_deserialize_restores_speed_multiplier() -> void:
	upgrade.try_purchase("KIT_01", 1)
	var data := upgrade.serialize()

	var upgrade2 := UpgradeSystem.new()
	add_child_autofree(upgrade2)
	upgrade2.deserialize(data)
	assert_almost_eq(upgrade2.speed_multiplier, 1.15, 0.001,
		"speed_multiplier must be preserved after deserialize")

func test_get_upgrades_by_category_kitchen() -> void:
	var upgrades := upgrade.get_upgrades_by_category("kitchen")
	assert_eq(upgrades.size(), 5,
		"Kitchen category must have 5 upgrades (GDD §8.1)")

func test_get_upgrades_by_category_idle() -> void:
	var upgrades := upgrade.get_upgrades_by_category("idle")
	assert_eq(upgrades.size(), 6,
		"Idle category must have 6 upgrades (GDD §8.4)")
