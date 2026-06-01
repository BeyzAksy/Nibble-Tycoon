## AchievementSystem.gd
## Achievement kilit açma ve kalıcı bonus yönetimi. GDD §11
##
## Sorumluluklar:
##   - EventBus sinyallerini dinler: xp_gained, order_cancelled, order_ready,
##     upgrade_purchased
##   - Achievement koşullarını kontrol eder — idempotent unlock
##   - ACH_05/ACH_06 kalıcı bonuslarını offline_system/chef_system'a uygular
##   - achievement_unlocked sinyali yayar → AchievementPanel güncellenir
##   - serialize / deserialize ile save entegrasyonu
##
## Bağımlılıklar (inject — BufeScene._wire_systems):
##   - economy_system : EconomySystem   (coin/gem ödülleri)
##   - chef_system    : ChefSystem      (ACH_06 tea_cook_mult)
##   - offline_system : OfflineSystem   (ACH_05 permanent_offline_mult)
##
## ACH_05 özel: BufeScene._check_offline_earnings() sonrası
##   notify_offline_sleep(elapsed_hours) çağrılır.

extends Node

# ── INJECTED REFS ─────────────────────────────────────────────────────────────
var economy_system  : Node = null
var chef_system     : Node = null
var offline_system  : Node = null

# ── STATE ─────────────────────────────────────────────────────────────────────
var _unlocked_ids       : Dictionary = {}   ## achievement_id → true
var _order_count        : int        = 0    ## ACH_01: toplam tamamlanan sipariş
var _recent_timestamps  : Array      = []   ## ACH_03: son N siparişin timestamp'leri
var _consecutive_count  : int        = 0    ## ACH_04: iptalsiz ardışık sipariş
var _tea_count          : int        = 0    ## ACH_06: servis edilen çay sayısı
var _permanent_bonuses  : Dictionary = {}   ## {"offline_mult": float, "tea_cook_mult": float}

# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	EventBus.xp_gained.connect(_on_order_completed)
	EventBus.order_cancelled.connect(_on_order_cancelled)
	EventBus.order_ready.connect(_on_order_ready)
	EventBus.upgrade_purchased.connect(_on_upgrade_purchased)


# ── EVENT HANDLERS ────────────────────────────────────────────────────────────
## xp_gained sipariş tamamlandı proxy'sidir (OrderManager tarafından yayılır).
##
## Args:
##   _amount: Kullanılmaz.
##   _total:  Kullanılmaz.
func _on_order_completed(_amount: int, _total: int) -> void:
	_order_count       += 1
	_consecutive_count += 1

	_recent_timestamps.push_back(Time.get_unix_time_from_system())
	if _recent_timestamps.size() > Constants.ACH_03_ORDER_COUNT:
		_recent_timestamps.pop_front()

	_check_and_unlock("ACH_01")
	_check_and_unlock("ACH_03")
	_check_and_unlock("ACH_04")


## Herhangi bir iptal (queue veya angry) ACH_04 streak'ini sıfırlar.
##
## Args:
##   _customer_id: Kullanılmaz.
##   _reason: Kullanılmaz — tüm iptaller streak'i sıfırlar.
func _on_order_cancelled(_customer_id: int, _reason: String) -> void:
	_consecutive_count = 0


## order_ready item_id içerdiğinden çay sayımı için kullanılır.
##
## Args:
##   _customer_id: Kullanılmaz.
##   item_id: Pişen ürün kimliği; "tea" ise sayaç artar.
func _on_order_ready(_customer_id: int, item_id: String) -> void:
	if item_id != "tea":
		return
	_tea_count += 1
	_check_and_unlock("ACH_06")


## İlk upgrade_purchased sinyali ACH_02'yi unlock eder.
##
## Args:
##   _upgrade_id: Kullanılmaz.
func _on_upgrade_purchased(_upgrade_id: String) -> void:
	_check_and_unlock("ACH_02")


## BufeScene._check_offline_earnings() tarafından çağrılır.
## elapsed_hours >= ACH_05_MIN_OFFLINE_HOURS ise ACH_05 unlock olur.
##
## Args:
##   elapsed_hours: Oyun kapandığından bu yana geçen gerçek süre (saat).
func notify_offline_sleep(elapsed_hours: float) -> void:
	if elapsed_hours >= Constants.ACH_05_MIN_OFFLINE_HOURS:
		_check_and_unlock("ACH_05")


# ── CORE UNLOCK ───────────────────────────────────────────────────────────────
## Achievement kilit açma — idempotent.
## Koşul sağlanmamışsa veya zaten açıksa sessizce döner.
##
## Args:
##   ach_id: Constants.ACHIEVEMENT_DEFS'te tanımlı achievement kimliği.
func _check_and_unlock(ach_id: String) -> void:
	if _unlocked_ids.get(ach_id, false):
		return
	if not _is_condition_met(ach_id):
		return

	_unlocked_ids[ach_id] = true
	_grant_reward(ach_id)
	if _has_permanent_bonus(ach_id):
		_apply_permanent_bonus(ach_id)

	var def : Dictionary = Constants.ACHIEVEMENT_DEFS.get(ach_id, {})
	EventBus.toast_requested.emit(
		"🏆 %s kazanıldı!" % def.get("name", ach_id),
		"reward"
	)
	EventBus.achievement_unlocked.emit(ach_id)


## Achievement koşulunu kontrol eder. Koşul karşılanmışsa true döner.
##
## Args:
##   ach_id: Kontrol edilecek achievement kimliği.
##
## Returns:
##   bool — koşul sağlandıysa true.
func _is_condition_met(ach_id: String) -> bool:
	var result : bool = false
	match ach_id:
		"ACH_01":
			result = _order_count >= Constants.ACH_01_ORDER_THRESHOLD
		"ACH_02":
			result = true   ## upgrade_purchased zaten tetikledi
		"ACH_03":
			if _recent_timestamps.size() >= Constants.ACH_03_ORDER_COUNT:
				var window : float = _recent_timestamps.back() - _recent_timestamps.front()
				result = window <= Constants.ACH_03_TIME_WINDOW_SEC
		"ACH_04":
			result = _consecutive_count >= Constants.ACH_04_STREAK
		"ACH_05":
			result = true   ## notify_offline_sleep koşulu zaten doğruladı
		"ACH_06":
			result = _tea_count >= Constants.ACH_06_TEA_COUNT
		_:
			push_error("AchievementSystem: unknown ach_id: %s" % ach_id)
	return result


func _has_permanent_bonus(ach_id: String) -> bool:
	return ach_id in ["ACH_05", "ACH_06"]


## Kalıcı bonusu hem _permanent_bonuses dict'e hem ilgili sisteme uygular.
## Inject edilmiş sistem null ise push_error yayar, bonus dict'e yazılır.
##
## Args:
##   ach_id: "ACH_05" veya "ACH_06".
func _apply_permanent_bonus(ach_id: String) -> void:
	match ach_id:
		"ACH_05":
			_permanent_bonuses["offline_mult"] = Constants.ACH_05_OFFLINE_BONUS_MULT
			if offline_system:
				offline_system.permanent_offline_mult = Constants.ACH_05_OFFLINE_BONUS_MULT
			else:
				push_error("AchievementSystem: offline_system not injected — ACH_05 bonus not applied")
		"ACH_06":
			_permanent_bonuses["tea_cook_mult"] = Constants.ACH_06_TEA_COOK_MULT
			if chef_system:
				chef_system.tea_cook_mult = Constants.ACH_06_TEA_COOK_MULT
			else:
				push_error("AchievementSystem: chef_system not injected — ACH_06 bonus not applied")


## deserialize() sonrası kaydedilmiş tüm kalıcı bonusları sistemlere tekrar uygular.
func _reapply_permanent_bonuses() -> void:
	for ach_id in _unlocked_ids:
		if _has_permanent_bonus(ach_id):
			_apply_permanent_bonus(ach_id)


## Achievement unlock olunca coin/gem ödülünü economy_system üzerinden verir.
## economy_system inject edilmemişse ödül sessizce atlanır (push_error yok —
## soft fail: ödül miktarları küçük, eksik olması fatal değil).
##
## Args:
##   ach_id: Ödülü verilecek achievement kimliği.
func _grant_reward(ach_id: String) -> void:
	if not economy_system:
		return
	match ach_id:
		"ACH_01":
			economy_system.earn_coins(Constants.ACH_01_REWARD_COINS, "achievement")
		"ACH_02":
			economy_system.earn_coins(Constants.ACH_02_REWARD_COINS, "achievement")
			economy_system.earn_gems(Constants.ACH_02_REWARD_GEMS,   "achievement")
		"ACH_04":
			economy_system.earn_coins(Constants.ACH_04_REWARD_COINS, "achievement")
		"ACH_05":
			economy_system.earn_gems(Constants.ACH_05_REWARD_GEMS, "achievement")
		"ACH_06":
			economy_system.earn_coins(Constants.ACH_06_REWARD_COINS, "achievement")


# ── SAVE / LOAD ───────────────────────────────────────────────────────────────
## Sistemi kayıt için sözlüğe dönüştürür.
##
## Returns:
##   Dictionary — unlocked listesi, sayaçlar ve kalıcı bonuslar.
func serialize() -> Dictionary:
	return {
		"unlocked":          _unlocked_ids.keys(),
		"order_count":       _order_count,
		"consecutive_count": _consecutive_count,
		"tea_count":         _tea_count,
		"permanent_bonuses": _permanent_bonuses,
	}


## Kayıt verisinden sistemi yükler ve kalıcı bonusları uygular.
## Eksik key'ler için güvenli default kullanır.
##
## Args:
##   data: Daha önce serialize() ile üretilmiş sözlük veya {}.
func deserialize(data: Dictionary) -> void:
	_unlocked_ids = {}
	for id in data.get("unlocked", []):
		_unlocked_ids[id] = true

	_order_count       = data.get("order_count",       0)
	_consecutive_count = data.get("consecutive_count", 0)
	_tea_count         = data.get("tea_count",         0)
	_permanent_bonuses = data.get("permanent_bonuses", {})

	_reapply_permanent_bonuses()
