## ProgressionSystem.gd
## XP ve level ilerleme sistemi. GDD §12 — Level & İlerleme.
##
## Sorumluluklar:
##   - EventBus.xp_gained dinler, total_orders sayar
##   - Constants.LEVEL_THRESHOLDS eşiği geçilince level_up emit eder
##   - Level ve toplam sipariş sayısını serialize/deserialize eder
##
## Bağımlılıklar:
##   - EventBus.xp_gained (dinler)
##   - EventBus.level_up  (yayar)
##   - Constants.LEVEL_THRESHOLDS

extends Node

# ── STATE ─────────────────────────────────────────────────────────────────────
var current_level : int = 1
var total_orders  : int = 0

# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	EventBus.xp_gained.connect(_on_xp_gained)


# ── XP HANDLER ────────────────────────────────────────────────────────────────
## xp_gained sinyalini dinler, toplam siparişi artırır ve level kontrolü yapar.
##
## Args:
##   amount: Kazanılan XP miktarı (genellikle 1).
##   _total: OrderManager'dan gelen anlık toplam (kullanılmaz; sistem kendi sayar).
func _on_xp_gained(amount: int, _total: int) -> void:
	total_orders += amount
	_check_level_up()


# ── LEVEL CHECK ───────────────────────────────────────────────────────────────
## Sonraki level eşiğine ulaşıldıysa level_up emit eder.
## Birden fazla eşik aynı anda geçildiyse recursive olarak tüm level'ları işler.
func _check_level_up() -> void:
	var next_level : int = current_level + 1
	if not Constants.LEVEL_THRESHOLDS.has(next_level):
		return
	if total_orders >= Constants.LEVEL_THRESHOLDS[next_level]:
		current_level = next_level
		EventBus.level_up.emit(current_level)
		_check_level_up()


# ── HELPERS ───────────────────────────────────────────────────────────────────
## Mevcut level içindeki XP ilerleme oranını döndürür (0.0–1.0).
## Max level'daysa 1.0 döner.
##
## Returns:
##   float — 0.0 (level başı) ile 1.0 (bir sonraki level eşiği) arası oran.
func get_xp_ratio() -> float:
	var cur_threshold  : int = Constants.LEVEL_THRESHOLDS.get(current_level,     0)
	var next_threshold : int = Constants.LEVEL_THRESHOLDS.get(current_level + 1, -1)
	if next_threshold < 0 or next_threshold <= cur_threshold:
		return 1.0
	return float(total_orders - cur_threshold) / float(next_threshold - cur_threshold)


# ── SAVE / LOAD ───────────────────────────────────────────────────────────────
## Sistemi kayıt için sözlüğe dönüştürür.
##
## Returns:
##   Dictionary — {"level": int, "total_orders": int}
func serialize() -> Dictionary:
	return {
		"level":        current_level,
		"total_orders": total_orders,
	}


## Kayıt verisinden sistemi yükler.
## Eksik key'ler için güvenli default değerler kullanır.
##
## Args:
##   data: Daha önce serialize() ile üretilmiş sözlük.
func deserialize(data: Dictionary) -> void:
	current_level = data.get("level",        1)
	total_orders  = data.get("total_orders", 0)
