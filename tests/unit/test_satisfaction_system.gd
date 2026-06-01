## test_satisfaction_system.gd
## SatisfactionSystem ceza, recovery, clamp, sinyal ve serialize testleri.

extends GutTest

const SatisfactionSystem = preload("res://scripts/systems/SatisfactionSystem.gd")

var satisfaction : SatisfactionSystem

func before_each() -> void:
	satisfaction = SatisfactionSystem.new()
	add_child_autofree(satisfaction)
	satisfaction.satisfaction_score = Constants.SATISFACTION_INITIAL


# ── PENALTY ───────────────────────────────────────────────────────────────────

func test_cancelled_angry_reduces_score() -> void:
	EventBus.order_cancelled.emit(1, "angry")
	assert_eq(
		satisfaction.satisfaction_score,
		Constants.SATISFACTION_INITIAL - Constants.SATISFACTION_PENALTY_ANGRY
	)


func test_cancelled_queue_does_not_reduce_score() -> void:
	EventBus.order_cancelled.emit(1, "queue")
	assert_eq(satisfaction.satisfaction_score, Constants.SATISFACTION_INITIAL)


func test_multiple_angry_cancels_accumulate() -> void:
	EventBus.order_cancelled.emit(1, "angry")
	EventBus.order_cancelled.emit(2, "angry")
	assert_eq(
		satisfaction.satisfaction_score,
		Constants.SATISFACTION_INITIAL - Constants.SATISFACTION_PENALTY_ANGRY * 2
	)


func test_score_does_not_go_below_min() -> void:
	satisfaction.satisfaction_score = Constants.SATISFACTION_MIN
	EventBus.order_cancelled.emit(1, "angry")
	assert_eq(satisfaction.satisfaction_score, Constants.SATISFACTION_MIN)


# ── RECOVERY ──────────────────────────────────────────────────────────────────

func test_completed_order_increases_score() -> void:
	satisfaction.satisfaction_score = 50
	EventBus.xp_gained.emit(1, 0)
	assert_eq(
		satisfaction.satisfaction_score,
		50 + Constants.SATISFACTION_RECOVERY_PER_ORDER
	)


func test_score_does_not_exceed_max() -> void:
	satisfaction.satisfaction_score = Constants.SATISFACTION_MAX
	EventBus.xp_gained.emit(1, 0)
	assert_eq(satisfaction.satisfaction_score, Constants.SATISFACTION_MAX)


# ── SIGNAL ────────────────────────────────────────────────────────────────────

func test_angry_cancel_emits_satisfaction_changed() -> void:
	watch_signals(EventBus)
	EventBus.order_cancelled.emit(1, "angry")
	assert_signal_emitted(EventBus, "satisfaction_changed")


func test_queue_cancel_does_not_emit_satisfaction_changed() -> void:
	watch_signals(EventBus)
	EventBus.order_cancelled.emit(1, "queue")
	assert_signal_emit_count(EventBus, "satisfaction_changed", 0)


func test_completed_order_emits_satisfaction_changed() -> void:
	satisfaction.satisfaction_score = 50
	watch_signals(EventBus)
	EventBus.xp_gained.emit(1, 0)
	assert_signal_emitted(EventBus, "satisfaction_changed")


func test_recovery_at_max_does_not_emit_signal() -> void:
	satisfaction.satisfaction_score = Constants.SATISFACTION_MAX
	watch_signals(EventBus)
	EventBus.xp_gained.emit(1, 0)
	assert_signal_emit_count(EventBus, "satisfaction_changed", 0)


func test_penalty_at_min_does_not_emit_signal() -> void:
	satisfaction.satisfaction_score = Constants.SATISFACTION_MIN
	watch_signals(EventBus)
	EventBus.order_cancelled.emit(1, "angry")
	assert_signal_emit_count(EventBus, "satisfaction_changed", 0)


# ── SERIALIZE / DESERIALIZE ───────────────────────────────────────────────────

func test_serialize_returns_score() -> void:
	satisfaction.satisfaction_score = 75
	var data : Dictionary = satisfaction.serialize()
	assert_eq(data["score"], 75)


func test_deserialize_restores_score() -> void:
	satisfaction.deserialize({"score": 60})
	assert_eq(satisfaction.satisfaction_score, 60)


func test_deserialize_missing_key_uses_default() -> void:
	satisfaction.deserialize({})
	assert_eq(satisfaction.satisfaction_score, Constants.SATISFACTION_INITIAL)


func test_deserialize_clamps_out_of_range_high() -> void:
	satisfaction.deserialize({"score": 999})
	assert_eq(satisfaction.satisfaction_score, Constants.SATISFACTION_MAX)


func test_deserialize_clamps_out_of_range_low() -> void:
	satisfaction.deserialize({"score": -50})
	assert_eq(satisfaction.satisfaction_score, Constants.SATISFACTION_MIN)


func test_serialize_deserialize_roundtrip() -> void:
	satisfaction.satisfaction_score = 42
	var data := satisfaction.serialize()
	satisfaction.satisfaction_score = 0
	satisfaction.deserialize(data)
	assert_eq(satisfaction.satisfaction_score, 42)
