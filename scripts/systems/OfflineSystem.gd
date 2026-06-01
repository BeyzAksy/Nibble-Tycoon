## OfflineSystem.gd
## Oyun kapalıyken geçen sürenin kazancını hesaplar. GDD §10

extends Node

# ── STATE ─────────────────────────────────────────────────────────────────────
var max_offline_hours   : float = 4.0
var offline_efficiency  : float = Constants.MIN_OFFLINE_EFFICIENCY

## Referanslar
var economy_system  : Node = null
var upgrade_system  : Node = null

# ── SAVE ──────────────────────────────────────────────────────────────────────
func save_close_data(hourly_rate: float) -> Dictionary:
	## GDD §10.2 — Oyun kapanırken çağrılır
	return {
		"close_timestamp":   Time.get_unix_time_from_system(),
		"hourly_rate":       hourly_rate,
		"offline_efficiency":offline_efficiency,
		"max_offline_hours": max_offline_hours,
	}


# ── CALCULATE ─────────────────────────────────────────────────────────────────
func calculate_earnings(save_data: Dictionary) -> Dictionary:
	## GDD §10.2 — Oyun açılırken çağrılır
	var close_ts    : float = save_data.get("close_timestamp",   0.0)
	var hourly_rate : float = save_data.get("hourly_rate",       0.0)
	var efficiency  : float = save_data.get("offline_efficiency",offline_efficiency)
	var max_hours   : float = save_data.get("max_offline_hours", max_offline_hours)

	var elapsed_sec   : float = Time.get_unix_time_from_system() - close_ts
	var elapsed_hours : float = elapsed_sec / 3600.0
	var offline_hours : float = minf(elapsed_hours, max_hours)

	var earnings := Constants.calc_offline_earnings(
		hourly_rate,
		offline_hours,
		max_hours,
		efficiency
	)

	## Depo doluysa uyarı (GDD §8 — "⚠ Depo doldu" mesajı)
	var storage_full : bool = elapsed_hours > max_hours

	return {
		"earnings":      earnings,
		"elapsed_hours": elapsed_hours,
		"offline_hours": offline_hours,
		"storage_full":  storage_full,
	}


# ── 2× AD REWARD ──────────────────────────────────────────────────────────────
func apply_2x_reward(base_earnings: float) -> void:
	## Reklam tamamlandıktan sonra WelcomeScreen tarafından çağrılır
	## Fark (1×) eklenir — base zaten toplandı
	var bonus := base_earnings   ## toplam = 2× → bonus = 1 kez daha
	if economy_system:
		economy_system.earn_coins(bonus, "offline_2x")
	EventBus.toast_requested.emit(
		"2× Bonus! +%.0f 🪙 eklendi" % bonus,
		"reward"
	)


func collect_earnings(amount: float) -> void:
	if economy_system:
		economy_system.earn_coins(amount, "offline")
	EventBus.offline_earnings_ready.emit(amount, 0.0)
