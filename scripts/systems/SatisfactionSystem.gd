## SatisfactionSystem.gd
## Müşteri memnuniyet skoru takibi. GDD §2.2 — Yemek Sabrı / CANCELLED_ANGRY.
##
## Sorumluluklar:
##   - EventBus.order_cancelled dinler; reason="angry" → SATISFACTION_PENALTY_ANGRY düşer
##   - EventBus.xp_gained dinler; tamamlanan sipariş başına SATISFACTION_RECOVERY_PER_ORDER artar
##   - Skor Constants.SATISFACTION_MIN–MAX aralığında kalır (clamp)
##   - Her değişimde EventBus.satisfaction_changed yayar
##   - Skoru serialize/deserialize eder (save entegrasyonu)
##
## Bağımlılıklar:
##   - EventBus.order_cancelled (dinler)
##   - EventBus.xp_gained      (dinler — tamamlanan sipariş proxy)
##   - EventBus.satisfaction_changed (yayar)
##   - Constants.SATISFACTION_*

extends Node

# ── STATE ─────────────────────────────────────────────────────────────────────
var satisfaction_score : int = Constants.SATISFACTION_INITIAL

# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	EventBus.order_cancelled.connect(_on_order_cancelled)
	EventBus.xp_gained.connect(_on_order_completed)


# ── EVENT HANDLERS ────────────────────────────────────────────────────────────
## CANCELLED_ANGRY sinyali gelince skoru SATISFACTION_PENALTY_ANGRY kadar düşürür.
##
## Args:
##   _customer_id: Kullanılmaz.
##   reason: "queue" veya "angry". Sadece "angry" skoru etkiler.
func _on_order_cancelled(_customer_id: int, reason: String) -> void:
	if reason != "angry":
		return
	_apply_delta(-Constants.SATISFACTION_PENALTY_ANGRY)


## xp_gained sinyali gelince (tamamlanan sipariş) skoru SATISFACTION_RECOVERY_PER_ORDER kadar artırır.
##
## Args:
##   _amount: Kullanılmaz.
##   _total:  Kullanılmaz.
func _on_order_completed(_amount: int, _total: int) -> void:
	_apply_delta(Constants.SATISFACTION_RECOVERY_PER_ORDER)


# ── CORE ──────────────────────────────────────────────────────────────────────
## Skoru verilen delta kadar değiştirir, aralık dışına çıkmaz ve sinyal yayar.
## Delta sıfırsa veya skor zaten limitteyse sinyal yayılmaz.
##
## Args:
##   delta: Pozitif (recovery) veya negatif (penalty) değer.
func _apply_delta(delta: int) -> void:
	var new_score : int = clampi(
		satisfaction_score + delta,
		Constants.SATISFACTION_MIN,
		Constants.SATISFACTION_MAX
	)
	var actual_delta : int = new_score - satisfaction_score
	if actual_delta == 0:
		return
	satisfaction_score = new_score
	EventBus.satisfaction_changed.emit(satisfaction_score, actual_delta)


# ── SAVE / LOAD ───────────────────────────────────────────────────────────────
## Sistemi kayıt için sözlüğe dönüştürür.
##
## Returns:
##   Dictionary — {"score": int}
func serialize() -> Dictionary:
	return {"score": satisfaction_score}


## Kayıt verisinden sistemi yükler.
## Eksik key için güvenli default kullanır.
##
## Args:
##   data: Daha önce serialize() ile üretilmiş sözlük.
func deserialize(data: Dictionary) -> void:
	satisfaction_score = clampi(
		data.get("score", Constants.SATISFACTION_INITIAL),
		Constants.SATISFACTION_MIN,
		Constants.SATISFACTION_MAX
	)
