## test_achievement_save.gd
## AchievementSystem kalıcı bonus, idempotency ve serialize testleri.

extends GutTest

const AchievementSystem = preload("res://scripts/systems/AchievementSystem.gd")
const EconomySystem     = preload("res://scripts/systems/EconomySystem.gd")
const ChefSystem        = preload("res://scripts/systems/ChefSystem.gd")
const OfflineSystem     = preload("res://scripts/systems/OfflineSystem.gd")

var ach     : AchievementSystem
var economy : EconomySystem
var chef    : ChefSystem
var offline : OfflineSystem


func before_each() -> void:
	economy = EconomySystem.new()
	add_child_autofree(economy)
	economy.coins = 0.0
	economy.gems  = 0

	chef = ChefSystem.new()
	add_child_autofree(chef)
	chef.tea_cook_mult = 1.0

	offline = OfflineSystem.new()
	add_child_autofree(offline)
	offline.permanent_offline_mult = 1.0

	ach = AchievementSystem.new()
	add_child_autofree(ach)
	ach.economy_system = economy
	ach.chef_system    = chef
	ach.offline_system = offline


# ── ACH_05: İlk Uyku ─────────────────────────────────────────────────────────

func test_ach05_unlocks_after_2h_offline() -> void:
	ach.notify_offline_sleep(Constants.ACH_05_MIN_OFFLINE_HOURS)
	assert_true(ach._unlocked_ids.get("ACH_05", false))


func test_ach05_not_unlocked_below_threshold() -> void:
	ach.notify_offline_sleep(Constants.ACH_05_MIN_OFFLINE_HOURS - 0.1)
	assert_false(ach._unlocked_ids.get("ACH_05", false))


func test_ach05_applies_offline_mult_to_system() -> void:
	ach.notify_offline_sleep(Constants.ACH_05_MIN_OFFLINE_HOURS)
	assert_almost_eq(
		offline.permanent_offline_mult, Constants.ACH_05_OFFLINE_BONUS_MULT, 0.001
	)


func test_ach05_saves_to_permanent_bonuses() -> void:
	ach.notify_offline_sleep(Constants.ACH_05_MIN_OFFLINE_HOURS)
	assert_true(ach._permanent_bonuses.has("offline_mult"))


# ── ACH_06: Çay Ustası ───────────────────────────────────────────────────────

func test_ach06_counts_tea_orders() -> void:
	for i in 10:
		EventBus.order_ready.emit(i, "tea")
	assert_eq(ach._tea_count, 10)


func test_ach06_ignores_non_tea_orders() -> void:
	EventBus.order_ready.emit(1, "pastry")
	assert_eq(ach._tea_count, 0)


func test_ach06_unlocks_at_50_teas() -> void:
	for i in Constants.ACH_06_TEA_COUNT:
		EventBus.order_ready.emit(i, "tea")
	assert_true(ach._unlocked_ids.get("ACH_06", false))


func test_ach06_applies_tea_cook_mult_to_chef() -> void:
	for i in Constants.ACH_06_TEA_COUNT:
		EventBus.order_ready.emit(i, "tea")
	assert_almost_eq(chef.tea_cook_mult, Constants.ACH_06_TEA_COOK_MULT, 0.001)


# ── IDEMPOTENCY ───────────────────────────────────────────────────────────────

func test_ach01_does_not_unlock_twice() -> void:
	watch_signals(EventBus)
	EventBus.xp_gained.emit(1, 0)
	EventBus.xp_gained.emit(1, 1)
	assert_signal_emit_count(EventBus, "achievement_unlocked", 1)


func test_ach02_does_not_unlock_twice_on_second_upgrade() -> void:
	watch_signals(EventBus)
	EventBus.upgrade_purchased.emit("KIT_01")
	EventBus.upgrade_purchased.emit("KIT_02")
	assert_signal_emit_count(EventBus, "achievement_unlocked", 1)


# ── SERIALIZE / DESERIALIZE ───────────────────────────────────────────────────

func test_serialize_includes_unlocked_list() -> void:
	EventBus.xp_gained.emit(1, 0)
	var data : Dictionary = ach.serialize()
	assert_true("ACH_01" in data["unlocked"])


func test_serialize_includes_counters() -> void:
	EventBus.xp_gained.emit(1, 0)
	var data : Dictionary = ach.serialize()
	assert_eq(data["order_count"], 1)


func test_deserialize_restores_unlocked_ids() -> void:
	ach.deserialize({"unlocked": ["ACH_01", "ACH_02"], "permanent_bonuses": {}})
	assert_true(ach._unlocked_ids.get("ACH_01", false))
	assert_true(ach._unlocked_ids.get("ACH_02", false))


func test_deserialize_reapplies_ach05_bonus() -> void:
	ach.deserialize({
		"unlocked":          ["ACH_05"],
		"permanent_bonuses": {"offline_mult": Constants.ACH_05_OFFLINE_BONUS_MULT},
	})
	assert_almost_eq(
		offline.permanent_offline_mult, Constants.ACH_05_OFFLINE_BONUS_MULT, 0.001
	)


func test_deserialize_reapplies_ach06_bonus() -> void:
	ach.deserialize({
		"unlocked":          ["ACH_06"],
		"permanent_bonuses": {"tea_cook_mult": Constants.ACH_06_TEA_COOK_MULT},
	})
	assert_almost_eq(chef.tea_cook_mult, Constants.ACH_06_TEA_COOK_MULT, 0.001)


func test_serialize_deserialize_roundtrip() -> void:
	EventBus.xp_gained.emit(1, 0)
	ach.notify_offline_sleep(3.0)
	var data := ach.serialize()

	var ach2 := AchievementSystem.new()
	add_child_autofree(ach2)
	ach2.economy_system = economy
	ach2.chef_system    = chef
	ach2.offline_system = offline
	ach2.deserialize(data)

	assert_true(ach2._unlocked_ids.get("ACH_01", false))
	assert_true(ach2._unlocked_ids.get("ACH_05", false))
	assert_eq(ach2._order_count, ach._order_count)


func test_deserialize_empty_dict_starts_clean() -> void:
	ach.deserialize({})
	assert_eq(ach._unlocked_ids.size(), 0)
	assert_eq(ach._order_count, 0)
