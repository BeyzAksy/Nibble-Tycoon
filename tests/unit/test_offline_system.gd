## test_offline_system.gd
## OfflineSystem offline kazanç hesaplama, kayıt ve 2× reklam ödülü testleri.
## GDD §10 — Offline Kazanç Sistemi

extends GutTest

const EconomySystem = preload("res://scripts/systems/EconomySystem.gd")
const OfflineSystem = preload("res://scripts/systems/OfflineSystem.gd")

var offline : OfflineSystem
var economy : EconomySystem

func before_each() -> void:
	economy = EconomySystem.new()
	add_child_autofree(economy)
	economy.coins = 0.0

	offline = OfflineSystem.new()
	add_child_autofree(offline)
	offline.economy_system     = economy
	offline.max_offline_hours  = 4.0
	offline.offline_efficiency = Constants.MIN_OFFLINE_EFFICIENCY   ## 0.30


# ── SAVE CLOSE DATA ───────────────────────────────────────────────────────────

func test_save_close_data_has_close_timestamp() -> void:
	var data := offline.save_close_data(1350.0)
	assert_true(data.has("close_timestamp"),
		"save_close_data must contain 'close_timestamp'")


func test_save_close_data_stores_hourly_rate() -> void:
	var data := offline.save_close_data(1350.0)
	assert_almost_eq(data["hourly_rate"], 1350.0, 0.01,
		"save_close_data must store hourly_rate")


func test_save_close_data_stores_max_hours() -> void:
	offline.max_offline_hours = 6.0
	var data := offline.save_close_data(0.0)
	assert_almost_eq(data["max_offline_hours"], 6.0, 0.01,
		"save_close_data must store max_offline_hours")


func test_save_close_data_stores_efficiency() -> void:
	offline.offline_efficiency = 0.38
	var data := offline.save_close_data(0.0)
	assert_almost_eq(data["offline_efficiency"], 0.38, 0.001,
		"save_close_data must store offline_efficiency")


# ── CALCULATE EARNINGS ────────────────────────────────────────────────────────

func test_calculate_earnings_basic() -> void:
	## 2 hours offline, max 4 hours, efficiency 0.30, rate 1000
	var now_ts  : float = Time.get_unix_time_from_system()
	var save_data := {
		"close_timestamp":    now_ts - 2.0 * 3600.0,  ## 2 hours ago
		"hourly_rate":        1000.0,
		"offline_efficiency": 0.30,
		"max_offline_hours":  4.0,
	}
	var result := offline.calculate_earnings(save_data)
	var expected : float = 1000.0 * 2.0 * 0.30   ## 600₺
	assert_almost_eq(result["earnings"], expected, 50.0,
		"2-hour offline earnings must be correct (50₺ tolerance)")


func test_calculate_earnings_capped_by_max_hours() -> void:
	## 8 hours elapsed but max 4 hours → only 4 hours counted
	var now_ts : float = Time.get_unix_time_from_system()
	var save_data := {
		"close_timestamp":    now_ts - 8.0 * 3600.0,
		"hourly_rate":        1000.0,
		"offline_efficiency": 0.30,
		"max_offline_hours":  4.0,
	}
	var result   := offline.calculate_earnings(save_data)
	var expected : float = 1000.0 * 4.0 * 0.30   ## 1200₺
	assert_almost_eq(result["earnings"], expected, 50.0,
		"Exceeding max hours must cap earnings")


func test_calculate_earnings_storage_full_when_over_max() -> void:
	var now_ts : float = Time.get_unix_time_from_system()
	var save_data := {
		"close_timestamp":    now_ts - 10.0 * 3600.0,  ## 10 hours > max 4 hours
		"hourly_rate":        1000.0,
		"offline_efficiency": 0.30,
		"max_offline_hours":  4.0,
	}
	var result := offline.calculate_earnings(save_data)
	assert_true(result["storage_full"],
		"storage_full must be true when max hours exceeded")


func test_calculate_earnings_storage_not_full_within_max() -> void:
	var now_ts : float = Time.get_unix_time_from_system()
	var save_data := {
		"close_timestamp":    now_ts - 2.0 * 3600.0,  ## 2 hours < max 4 hours
		"hourly_rate":        1000.0,
		"offline_efficiency": 0.30,
		"max_offline_hours":  4.0,
	}
	var result := offline.calculate_earnings(save_data)
	assert_false(result["storage_full"],
		"storage_full must be false when within max hours")


func test_calculate_earnings_returns_elapsed_hours() -> void:
	var now_ts : float = Time.get_unix_time_from_system()
	var save_data := {
		"close_timestamp":    now_ts - 3.0 * 3600.0,  ## 3 hours
		"hourly_rate":        0.0,
		"offline_efficiency": 0.30,
		"max_offline_hours":  12.0,
	}
	var result := offline.calculate_earnings(save_data)
	assert_almost_eq(result["elapsed_hours"], 3.0, 0.1,
		"elapsed_hours must be approximately 3.0")


func test_calculate_earnings_zero_rate_returns_zero() -> void:
	var now_ts : float = Time.get_unix_time_from_system()
	var save_data := {
		"close_timestamp":    now_ts - 4.0 * 3600.0,
		"hourly_rate":        0.0,
		"offline_efficiency": 0.30,
		"max_offline_hours":  12.0,
	}
	var result := offline.calculate_earnings(save_data)
	assert_almost_eq(result["earnings"], 0.0, 0.01,
		"Hourly rate 0 → earnings must be 0")


# ── COLLECT EARNINGS ──────────────────────────────────────────────────────────

func test_collect_earnings_adds_coins() -> void:
	offline.collect_earnings(500.0)
	assert_almost_eq(economy.coins, 500.0, 0.01,
		"collect_earnings must increase economy balance")


func test_collect_earnings_emits_offline_earnings_ready() -> void:
	watch_signals(EventBus)
	offline.collect_earnings(200.0)
	assert_signal_emitted(EventBus, "offline_earnings_ready",
		"collect_earnings must emit EventBus.offline_earnings_ready")


# ── 2× AD REWARD ─────────────────────────────────────────────────────────────

func test_apply_2x_reward_adds_base_amount() -> void:
	## Base earnings already collected → bonus = one more time
	offline.apply_2x_reward(300.0)
	assert_almost_eq(economy.coins, 300.0, 0.01,
		"apply_2x_reward must add the bonus amount")


func test_apply_2x_reward_emits_toast() -> void:
	watch_signals(EventBus)
	offline.apply_2x_reward(100.0)
	assert_signal_emitted(EventBus, "toast_requested",
		"2× reward must emit a toast notification")
