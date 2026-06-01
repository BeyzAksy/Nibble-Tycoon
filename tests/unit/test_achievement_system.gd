## test_achievement_system.gd
## AchievementSystem kilit açma testleri: ACH_01–ACH_04.

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


# ── ACH_01: İlk Sipariş ──────────────────────────────────────────────────────

func test_ach01_unlocks_on_first_order() -> void:
	EventBus.xp_gained.emit(1, 0)
	assert_true(ach._unlocked_ids.get("ACH_01", false))


func test_ach01_not_unlocked_before_order() -> void:
	assert_false(ach._unlocked_ids.get("ACH_01", false))


func test_ach01_emits_achievement_unlocked() -> void:
	watch_signals(EventBus)
	EventBus.xp_gained.emit(1, 0)
	assert_signal_emitted(EventBus, "achievement_unlocked")


func test_ach01_grants_reward_coins() -> void:
	EventBus.xp_gained.emit(1, 0)
	assert_almost_eq(economy.coins, Constants.ACH_01_REWARD_COINS, 0.01)


# ── ACH_02: İlk Yükseltme ────────────────────────────────────────────────────

func test_ach02_unlocks_on_first_upgrade() -> void:
	EventBus.upgrade_purchased.emit("KIT_01")
	assert_true(ach._unlocked_ids.get("ACH_02", false))


func test_ach02_grants_gems() -> void:
	EventBus.upgrade_purchased.emit("KIT_01")
	assert_eq(economy.gems, Constants.ACH_02_REWARD_GEMS)


# ── ACH_03: Hızlı Aşçı ───────────────────────────────────────────────────────

func test_ach03_not_unlocked_with_only_4_orders() -> void:
	for i in 4:
		EventBus.xp_gained.emit(1, i)
	assert_false(ach._unlocked_ids.get("ACH_03", false))


func test_ach03_unlocks_when_5_orders_within_window() -> void:
	for i in Constants.ACH_03_ORDER_COUNT:
		EventBus.xp_gained.emit(1, i)
	assert_true(ach._unlocked_ids.get("ACH_03", false))


func test_ach03_not_unlocked_when_5_orders_outside_window() -> void:
	var old_ts : float = Time.get_unix_time_from_system() - 200.0
	for i in 4:
		ach._recent_timestamps.push_back(old_ts)
	EventBus.xp_gained.emit(1, 4)
	assert_false(ach._unlocked_ids.get("ACH_03", false))


# ── ACH_04: Sıfır İptal ──────────────────────────────────────────────────────

func test_ach04_not_unlocked_before_20_streak() -> void:
	for i in 19:
		EventBus.xp_gained.emit(1, i)
	assert_false(ach._unlocked_ids.get("ACH_04", false))


func test_ach04_unlocks_at_20_consecutive() -> void:
	for i in Constants.ACH_04_STREAK:
		EventBus.xp_gained.emit(1, i)
	assert_true(ach._unlocked_ids.get("ACH_04", false))


func test_ach04_cancel_resets_streak() -> void:
	for i in 19:
		EventBus.xp_gained.emit(1, i)
	EventBus.order_cancelled.emit(1, "angry")
	EventBus.xp_gained.emit(1, 20)
	assert_false(ach._unlocked_ids.get("ACH_04", false))


func test_ach04_queue_cancel_resets_streak() -> void:
	for i in 19:
		EventBus.xp_gained.emit(1, i)
	EventBus.order_cancelled.emit(1, "queue")
	assert_eq(ach._consecutive_count, 0)
