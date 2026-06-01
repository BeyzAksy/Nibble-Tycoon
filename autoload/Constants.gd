## Constants.gd
## Lezzet İmparatorluğu — Design System Tokens
## Tüm renk, spacing, timing ve oyun sabitleri burada tanımlanır.
## Autoload olarak yüklenir — her yerden Constants.CORAL gibi erişilir.
##
## Kaynak: bufe_uiux_kilavuzu.html + bufe_asama_gdd.md

extends Node

# ── COLOR PALETTE (GUI-DD v0.1) ───────────────────────────────────────────────

## Zemin renkleri
const CREAM        := Color("#FFF6EC")
const CREAM2       := Color("#FBEEDD")
const CARD         := Color("#FFFFFF")

## Metin renkleri
const INK          := Color("#3E3238")
const INK_SOFT     := Color("#8A7E84")
const LINE         := Color("#F0E2D2")

## Coral — birincil CTA, sinirli müşteri, pişirme göstergesi
const CORAL        := Color("#FF8A6B")
const CORAL_DEEP   := Color("#F2714F")
const CORAL_SHADOW := Color("#CF5638")

## Mint — pozitif/kazanç, READY durumu, 2× reklam butonu
const MINT         := Color("#A8E6CF")
const MINT_DEEP    := Color("#5CC39A")
const MINT_SHADOW  := Color("#3F9C79")

## Butter — coin/para, offline kazanç, coin float
const BUTTER       := Color("#FFE08A")
const BUTTER_DEEP  := Color("#F2B705")
const BUTTER_SHADOW:= Color("#C99200")

## Sky — QUEUED durumu, bilgi/nötr, menü bilgi kartları
const SKY          := Color("#A5D8F3")
const SKY_DEEP     := Color("#4FA8DF")

## Plum — premium/gem, gem harcama
const PLUM         := Color("#9B6FC4")
const LAVENDER     := Color("#CBB6E8")

## Peach — uyarı, orta sabır eşiği (%35–65)
const PEACH        := Color("#FFC9B5")

## Sabır barı renkleri (eşiğe göre değişir)
const PATIENCE_HIGH   := MINT        ## > %65 — mutlu 😊
const PATIENCE_MID    := BUTTER      ## %35–65 — nötr 😐
const PATIENCE_LOW    := CORAL       ## < %35  — sinirli 😠

# ── TYPOGRAPHY ────────────────────────────────────────────────────────────────
## Font dosyaları res://assets/fonts/ altında bekleniyor
## Fredoka One → başlık, sayaç, buton label
## Nunito       → body, açıklama, tooltip

const FONT_DISPLAY   := "res://assets/fonts/Fredoka-SemiBold.ttf"
const FONT_BODY      := "res://assets/fonts/Nunito-Regular.ttf"
const FONT_BODY_BOLD := "res://assets/fonts/Nunito-Bold.ttf"

## Font boyutları (sp cinsinden, 1080px viewport bazında)
const FS_DISPLAY_XL  := 72   ## Splash title
const FS_DISPLAY_L   := 56   ## Achievement popup
const FS_HEADING_M   := 40   ## HUD chip
const FS_LABEL_L     := 36   ## Buton label
const FS_LABEL_M     := 30   ## Kart başlıkları
const FS_BODY        := 26   ## Açıklama metni
const FS_CAPTION     := 22   ## Badge, tag
const FS_TINY        := 18   ## Timer overlay

# ── SPACING (px, 1080 viewport) ──────────────────────────────────────────────
const S4  :=  4
const S8  :=  8
const S12 := 12
const S16 := 16
const S20 := 20
const S24 := 24
const S32 := 32
const S48 := 48

# ── BORDER RADIUS ────────────────────────────────────────────────────────────
const R_SM  := 12
const R_MD  := 18
const R_LG  := 28
const R_PILL:= 999

# ── ANIMATION DURATIONS (seconds) ─────────────────────────────────────────────
const ANIM_FAST       := 0.08   ## Buton basış
const ANIM_NORMAL     := 0.15   ## Hover, renk geçişi
const ANIM_SLOW       := 0.28   ## Bottom-sheet, transition
const ANIM_COIN_FLOAT := 0.60   ## Coin sayaca uçuş
const ANIM_SHAKE_FREQ := 0.15   ## Sabır barı titreme periyodu
const ANIM_PATIENCE_SHAKE_AMP_LOW  := 2.0   ## px, %35 altı
const ANIM_PATIENCE_SHAKE_AMP_CRIT := 4.0   ## px, %10 altı

# ── SPLASH SCREEN ─────────────────────────────────────────────────────────────
const SPLASH_DURATION      := 2.5   ## Saniye — sonra main scene'e geç
const SPLASH_FADE_DURATION := 0.4   ## Fade-out süresi

# ── SAVE VERSIONING ───────────────────────────────────────────────────────────
const CURRENT_SAVE_VERSION := 2

# ── BUFFET STAGE CONSTANTS (GDD §14) ─────────────────────────────────────────

## Kapasite
const BUFFET_MAX_STOOLS        := 4
const BUFFET_MAX_QUEUE         := 7
const BUFFET_MAX_COOKING_SLOTS := 2

## Offline sistem
const STOOL_UTILIZATION     := 0.75
const FOOD_COST_FACTOR      := 0.70
const MIN_OFFLINE_EFFICIENCY:= 0.30
const MAX_OFFLINE_EFFICIENCY:= 0.45

## Bahşiş formülü
const TIP_PATIENCE_MULT  := 0.15
const TIP_QUALITY_MULT   := 0.04
const ORDER_QUALITY_MULT := 0.04

## Yeme ve teslim
const EATING_DURATION_SEC := 15.0
const PICKUP_DELAY_SEC    := 2.5

## Sabır eşikleri — paylaşımlı (CustomerNode renk mantığı)
const PATIENCE_HAPPY_THRESHOLD   := 0.65
const PATIENCE_NEUTRAL_THRESHOLD := 0.35

## Müşteri tipleri — GDD §2.1
## Dict'e yeni satır = yeni tip; CustomerSystem/CustomerNode kodu değişmez.
##
## Alanlar:
##   unlock_level:     Hangi oyun level'ında spawn başlar
##   spawn_interval:   Kaç saniyede bir spawn (sn)
##   patience_queue:   Sıra sabrı süresi (sn)
##   patience_food:    Yemek sabrı süresi (sn)
##   coin_mult:        Sipariş değeri çarpanı
##   tip_mult:         Bahşiş çarpanı
##   item_pool:        Sipariş edebileceği item ID'leri (boş = tüm unlocked)
##   preferred_item:   Öncelikli item ID (boş = öncelik yok)
##   preferred_weight: preferred_item seçilme olasılığı (0.0 = rastgele)
const CUSTOMER_TYPES := {
	"regular": {
		"unlock_level":    1,
		"spawn_interval":  25.0,
		"patience_queue":  40.0,
		"patience_food":   30.0,
		"coin_mult":       1.00,
		"tip_mult":        1.00,
		"item_pool":       [],
		"preferred_item":  "",
		"preferred_weight": 0.0,
	},
	"impatient": {
		"unlock_level":    2,
		"spawn_interval":  30.0,
		"patience_queue":  18.0,
		"patience_food":   15.0,
		"coin_mult":       1.20,
		"tip_mult":        1.00,
		"item_pool":       ["tea", "pastry", "sandwich"],
		"preferred_item":  "",
		"preferred_weight": 0.0,
	},
	"tourist": {
		"unlock_level":    3,
		"spawn_interval":  35.0,
		"patience_queue":  65.0,
		"patience_food":   55.0,
		"coin_mult":       1.00,
		"tip_mult":        1.30,
		"item_pool":       ["sausage", "tea"],
		"preferred_item":  "sausage",
		"preferred_weight": 0.6,
	},
}

## Menü itemları — base fiyat (₺) ve pişirme süresi (sn)
const MENU_ITEMS := {
	"tea":          {"name": "Çay",            "price": 25, "cook_time":  8, "unlock_level": 1},
	"pastry":       {"name": "Poğaça",          "price": 40, "cook_time": 12, "unlock_level": 1},
	"sandwich": {
		"name": "Tost", "price": 65, "cook_time": 15,
		"unlock_level": 2, "unlock_cost": 600,
	},
	"sausage": {
		"name": "Sosisli Sandviç", "price": 75, "cook_time": 14,
		"unlock_level": 3, "unlock_cost": 2000,
	},
	"daily_special":{"name": "Günün Özelliği",  "price": 0,  "cook_time":  0, "unlock_level": 5},
}

## Memnuniyet sistemi (GDD §2.2)
const SATISFACTION_INITIAL       := 100   ## Oyun başlangıç skoru
const SATISFACTION_MIN           := 0
const SATISFACTION_MAX           := 100
const SATISFACTION_PENALTY_ANGRY := 10    ## CANCELLED_ANGRY başına düşüş
const SATISFACTION_RECOVERY_PER_ORDER := 2  ## Tamamlanan sipariş başına artış

## Level eşikleri (toplam tamamlanan sipariş)
const LEVEL_THRESHOLDS := {
	1: 0,
	2: 30,
	3: 100,
	4: 250,
	5: 500,
}

## Kafe geçiş koşulu
const CAFE_TRANSITION_COST := 5000

# ── ACHIEVEMENT SYSTEM (GDD §11) ─────────────────────────────────────────────

## Achievement tanımları — AchievementSystem ve AchievementPanel paylaşır
const ACHIEVEMENT_DEFS := {
	"ACH_01": {
		"name": "İlk Sipariş", "desc": "1 sipariş tamamla",
		"reward": "100₺ + rozet", "hidden": false, "icon": "🍽️",
	},
	"ACH_02": {
		"name": "İlk Yükseltme", "desc": "İlk upgrade'i satın al",
		"reward": "200₺ + 2💎", "hidden": false, "icon": "⬆️",
	},
	"ACH_03": {
		"name": "Hızlı Aşçı", "desc": "5 siparişi 3 dakikada servis et",
		"reward": "300₺", "hidden": false, "icon": "⚡", "max": 5,
	},
	"ACH_04": {
		"name": "Sıfır İptal", "desc": "20 siparişi iptalsiz tamamla",
		"reward": "500₺ + dekor", "hidden": false, "icon": "🎯", "max": 20,
	},
	"ACH_05": {
		"name": "İlk Uyku", "desc": "2 saat offline bekle",
		"reward": "1💎 + offline+%5", "hidden": false, "icon": "🌙",
	},
	"ACH_06": {
		"name": "Çay Ustası", "desc": "50 çay servis et",
		"reward": "300₺ + çay−%10", "hidden": false, "icon": "🫖", "max": 50,
	},
	"ACH_07": {
		"name": "Tam Dolu", "desc": "Tüm tabure + sıra aynı anda dolu",
		"reward": "500₺", "hidden": false, "icon": "💯",
	},
	"ACH_08": {
		"name": "Menü Tamamlandı", "desc": "4 menü itemını aç",
		"reward": "1.000₺ + 5💎", "hidden": false, "icon": "📋",
	},
	"ACH_09": {
		"name": "Büfe Emektarı", "desc": "500 sipariş tamamla",
		"reward": "2.000₺ + unvan", "hidden": false, "icon": "🏅", "max": 500,
	},
	"ACH_10": {
		"name": "Gece Kuşu", "desc": "???",
		"reward": "Gizli kostüm", "hidden": true, "icon": "🌙",
	},
}

## Achievement koşulları (GDD §11)
const ACH_01_ORDER_THRESHOLD    := 1      ## İlk Sipariş: kaç sipariş
const ACH_03_ORDER_COUNT        := 5      ## Hızlı Aşçı: penceredeki sipariş sayısı
const ACH_03_TIME_WINDOW_SEC    := 180.0  ## Hızlı Aşçı: pencere genişliği (saniye)
const ACH_04_STREAK             := 20     ## Sıfır İptal: arka arkaya iptalsiz sipariş
const ACH_05_MIN_OFFLINE_HOURS  := 2.0    ## İlk Uyku: minimum offline süre (saat)
const ACH_05_OFFLINE_BONUS_MULT := 1.05   ## İlk Uyku: offline kazanç kalıcı çarpanı
const ACH_06_TEA_COUNT          := 50     ## Çay Ustası: kaç çay servis edilmeli
const ACH_06_TEA_COOK_MULT      := 0.9    ## Çay Ustası: çay pişirme süresi çarpanı (−%10)

## Achievement coin/gem ödülleri (GDD §11)
const ACH_01_REWARD_COINS  := 100.0
const ACH_02_REWARD_COINS  := 200.0
const ACH_02_REWARD_GEMS   := 2
const ACH_04_REWARD_COINS  := 500.0
const ACH_05_REWARD_GEMS   := 1
const ACH_06_REWARD_COINS  := 300.0

# ── HELPER FUNCTIONS ──────────────────────────────────────────────────────────

## Sabır oranına göre renk döndürür
static func get_patience_color(ratio: float) -> Color:
	if ratio >= PATIENCE_HAPPY_THRESHOLD:
		return PATIENCE_HIGH
	if ratio >= PATIENCE_NEUTRAL_THRESHOLD:
		return PATIENCE_MID
	return PATIENCE_LOW

## Sipariş değeri hesapla
static func calc_order_value(base_price: int, chef_quality: int) -> float:
	return base_price * (1.0 + chef_quality * ORDER_QUALITY_MULT)

## Bahşiş hesapla
static func calc_tip(base_price: int, patience_ratio: float, chef_quality: int) -> float:
	return base_price * patience_ratio * TIP_PATIENCE_MULT \
		+ chef_quality * TIP_QUALITY_MULT

## Offline kazanç hesapla
static func calc_offline_earnings(
	hourly_rate: float,
	elapsed_hours: float,
	max_hours: float,
	efficiency: float
) -> float:
	var clamped := minf(elapsed_hours, max_hours)
	return hourly_rate * clamped * efficiency
