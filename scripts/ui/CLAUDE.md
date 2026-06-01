# scripts/ui/ — UI Modül Rehberi

> UI bileşenleri görüntüleme ve input yapar. İş mantığı içermez.
> EventBus'tan güncellenir, sistemlere direkt referans almaz.

---

## Temel Kural: Sinyale Bağla, Sistemi Çağırma

```gdscript
## WRONG — direct system reference (forbidden)
var economy_ref : EconomySystem = null
func _ready() -> void:
    coin_label.text = "%.0f₺" % economy_ref.coins

## CORRECT — listen to signal
func _ready() -> void:
    EventBus.balance_changed.connect(_on_balance_changed)

func _on_balance_changed(coins: float, _gems: int) -> void:
    coin_label.text = "%.0f₺" % coins
```

**İstisna:** Parent scene tarafından inject edilen referanslar kabul edilir.
Örnek: `UpgradePanel` → `upgrade_system` ref alabilir çünkü "try_purchase" bir kullanıcı aksiyonudur.

---

## Bileşen Kataloğu

### HUDBar.gd — Sürekli Görünür HUD
**Dosya:** `scripts/ui/HUDBar.gd` | `scenes/ui/HUDBar.tscn`

**Sorumluluk:** Coin, gem, level, XP progress gösterimi.

**Dinlediği sinyaller:**
- `EventBus.balance_changed(coins, gems)` → coin/gem label
- `EventBus.level_up(new_level)` → level badge
- `EventBus.xp_gained(amount, total)` → XP progress bar

**Extension noktaları:**
- Yeni para birimi → yeni label + sinyal bağlantısı
- Level bar animasyonu → `_on_level_up` içine Tween ekle

---

### UpgradePanel.gd — Upgrade Satın Alma Paneli
**Dosya:** `scripts/ui/UpgradePanel.gd` | **tscn yok (todo)**

**Sorumluluk:** Upgrade ağacını göster, satın alma tetikle.

**Inject edilen:**
- `upgrade_system : UpgradeSystem` (try_purchase çağrısı için)
- `current_level : int` (kilit kontrolü için)

**Dinlediği sinyaller:**
- `EventBus.upgrade_purchased` → listeyi yenile
- `upgrade_system.upgrade_ui_refresh_needed` → listeyi yenile

**Data-driven render:** `_build_category_list()` UPGRADE_DEFS'ten kategori listesini alır. Yeni kategori eklemek = sadece UPGRADE_DEFS'te `"category"` key ekle.

---

### WelcomeModal.gd — Offline Kazanç Modalı
**Dosya:** `scripts/ui/WelcomeModal.gd` | `scenes/ui/WelcomeModal.tscn`

**Sorumluluk:** Oyun açılışında offline kazancı göster, 2× reklam teklif et.

**Inject:** `offline_system : OfflineSystem`

**Flow:** `show_earnings(amount, elapsed_h)` → "Topla" → `collect_earnings()` → "2×" → reklam → `apply_2x_reward()`

---

### ToastManager.gd — Geçici Bildirimler
**Dosya:** `scripts/ui/ToastManager.gd`

**Sorumluluk:** Ekranda geçici mesaj göster (success, warning, error, reward).

**Dinlediği sinyal:**
- `EventBus.toast_requested(message, type)` → toast queue

**Toast tipleri:**
```gdscript
const TOAST_STYLES := {
    "success": Color("#A8E6CF"),   ## mint
    "warning": Color("#FFE08A"),   ## butter
    "error":   Color("#FF8A6B"),   ## coral
    "reward":  Color("#9B6FC4"),   ## plum
}
```

**Extension noktaları:**
- Yeni tip → `TOAST_STYLES` dict'e ekle
- Toast queue (aynı anda birden fazla) → `_queue` array + animasyon zinciri
- Toast pozisyonu → Constants'ta `TOAST_POSITION` enum ekle

---

### BottomNav.gd — Alt Navigasyon
**Dosya:** `scripts/ui/BottomNav.gd` | `scenes/ui/BottomNav.tscn` (TODO: tscn ekle)

**Sorumluluk:** Büfe içi panel navigasyonu (Upgrade, Menü, Achievement).

**Kafe'ye genişleme için data-driven tab sistemi (planlandı):**
```gdscript
## Tabs array inject edilir veya Constants'tan okunur
## Şimdi hardcoded tab listesi var — taşınacak
var tabs : Array[Dictionary] = []

## Hedef:
func setup(tab_list: Array[Dictionary]) -> void:
    for tab in tab_list:
        if tab.get("stage", "buffet") == current_stage:
            _add_tab_button(tab)
```

---

### CoinFloat.gd — Coin Animasyonu
**Dosya:** `scripts/ui/CoinFloat.gd`

**Sorumluluk:** Sipariş tamamlanınca coin sayısı havada uçarak HUD'a gider.

**Dinlediği sinyal:**
- `EventBus.coin_earned(amount, source)` → `"order"` source ise animasyon

**Extension noktaları:**
- Gem animasyonu → aynı script, `source == "gem_reward"` için farklı renk/icon
- Kritik sipariş efekti (yüksek değerli) → amount > threshold ise büyük animasyon

---

### MenuPanel.gd — Menü Unlock Paneli
**Dosya:** `scripts/ui/MenuPanel.gd`

**Sorumluluk:** Menü item'larını listele, kilit aç butonu.

**Data-driven render:**
```gdscript
## Constants.MENU_ITEMS'tan listele — hardcoded item yok
func _build_menu_list() -> void:
    for item_id in Constants.MENU_ITEMS:
        var item : Dictionary = Constants.MENU_ITEMS[item_id]
        if item["unlock_level"] <= current_level:
            _render_unlocked_item(item_id, item)
        else:
            _render_locked_item(item_id, item)
```

---

### AchievementPanel.gd — Achievement Listesi
**Dosya:** `scripts/ui/AchievementPanel.gd`

**Sorumluluk:** Achievement listesini göster.

**Durum:** `AchievementSystem.gd` henüz implement edilmedi. Panel bu sisteme bağlanacak.

**Dinleyecek sinyal (ileride):**
- `EventBus.achievement_unlocked(achievement_id)` → rozet animasyon + liste güncelle

---

## Ortak UI Patterns

### 1. Animasyon: Tween Kullan, Timer Değil

```gdscript
## CORRECT — Tween
var tween := create_tween()
tween.tween_property(coin_label, "modulate:a", 0.0, Constants.ANIM_NORMAL)

## WRONG — Timer node
var timer := Timer.new()
timer.wait_time = 0.15
```

### 2. Tema: Constants'tan Renk

```gdscript
## CORRECT
button.modulate = Constants.CORAL
label.add_theme_color_override("font_color", Constants.INK)

## WRONG
button.modulate = Color("#FF8A6B")
```

### 3. Sayı Formatı

```gdscript
## Coin (₺)
"%.0f₺" % amount           ## 1234₺
"%s₺" % _format_k(amount)  ## 1.2K₺ (büyük değerler için)

## Gem
"%d 💎" % gems

## Yüzde
"%d%%" % (ratio * 100)
```

### 4. Panel Aç/Kapat

```gdscript
## Panel visibility toggle — her panel aynı pattern
func toggle_visible() -> void:
    if visible:
        _close()
    else:
        _open()

func _open() -> void:
    show()
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 1.0, Constants.ANIM_SLOW)

func _close() -> void:
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, Constants.ANIM_SLOW)
    await tween.finished
    hide()
```

---

<!-- Bekleyen işler Jira'da yönetilir — LI-UI epic'i. -->
