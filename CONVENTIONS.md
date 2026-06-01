# CONVENTIONS.md — GDScript Kod Kalite Kontratı

> Lezzet İmparatorluğu — Büfe Aşaması ve ötesi için geçerlidir.
> Her pull request veya görev bu kurallara uymak zorundadır.

---

## 1. Dosya ve Sınıf İsimlendirme

### 1.1 GDScript Dosyaları

| Kategori | Convention | Örnek |
|----------|-----------|-------|
| Sistemler (Autoload/Node) | PascalCase | `EconomySystem.gd`, `ChefSystem.gd` |
| UI Bileşenleri | PascalCase | `HUDBar.gd`, `UpgradePanel.gd` |
| Yardımcı sınıflar | PascalCase | `OrderData.gd`, `CustomerConfig.gd` |
| Test dosyaları | `test_` prefix + snake_case | `test_economy_system.gd` |
| Autoload | PascalCase | `Constants.gd`, `EventBus.gd` |

### 1.2 Sahne Dosyaları

```
scenes/
  bufe/
    BufeScene.tscn        ← mekan sahnesi
    CustomerNode.tscn     ← müşteri prefab'ı
    StoveSlot.tscn         ← stove slot component
    ui/
      HUDBar.tscn
      UpgradePanel.tscn
  kafe/                   ← ileride
  splash/
    SplashScreen.tscn
```

**Kural:** Sahne ve script dosyaları aynı isimle eşleşmeli. `BufeScene.tscn` → `BufeScene.gd`.

---

## 2. Değişken ve Fonksiyon İsimlendirme

### 2.1 Değişkenler

```gdscript
## Sınıf değişkenleri → snake_case
var coin_balance    : float = 0.0
var chef_quality    : int   = 1
var is_boost_active : bool  = false

## Private değişkenler → _ prefix
var _cooking_slots  : Array = []
var _order_queue    : Array = []
var _next_order_id  : int   = 1

## Sabitler → SCREAMING_SNAKE_CASE (sadece Constants.gd'de)
const MAX_STOOLS := 4
const TIP_MULT   := 0.15
```

### 2.2 Fonksiyonlar

```gdscript
## Public → snake_case, fiil-isim
func earn_coins(amount: float, source: String = "") -> void:
func get_order(order_id: int) -> Order:
func try_purchase(upgrade_id: String, level: int) -> bool:

## Private → _ prefix
func _calc_cook_time(base: float, item_id: String) -> float:
func _cleanup_order(order_id: int) -> void:
func _on_upgrade_purchased(id: String) -> void:   ## event handler

## Sinyal handler'ları → _on_ prefix
func _on_balance_changed(coins: float, gems: int) -> void:
func _on_order_queued(customer_id: int) -> void:
```

### 2.3 Sinyaller

```gdscript
## snake_case, geçmiş zaman veya isim olayı
signal order_queued(customer_id: int)
signal balance_changed(coins: float, gems: int)
signal upgrade_ui_refresh_needed()
signal slot_started_cooking(slot_index: int, order_id: int)

## YANLIŞ
signal OrderQueued        ## PascalCase değil
signal on_order_queued    ## on_ prefix değil
```

---

## 3. Tip Belirtimi (Type Hints)

Her değişken ve dönüş değeri tip belirtmeli. İstisna yoktur.

```gdscript
## DOĞRU
var coins : float = 0.0
var items : Array[Dictionary] = []
func get_order(id: int) -> Order:

## YANLIŞ
var coins = 0.0
func get_order(id):
```

**Godot'a özgü tipler:**
```gdscript
var node_ref   : Node          = null
var packed_scn : PackedScene   = null
var timer_node : Timer         = null
var sprite     : Sprite2D      = null
```

---

## 4. Docstring Formatı

Her public fonksiyon, her sınıf, her sinyal için docstring zorunludur.

```gdscript
## Single-line açıklama (##  ile başlar).
##
## Args:
##   amount: Kazanılacak coin miktarı. Sıfır veya negatif kabul edilmez.
##   source: Kazanç kaynağı (örn. "order", "offline", "ad_reward").
##
## Returns:
##   Bakiye güncellenirse true, amount <= 0 ise false.
##
## Emits:
##   EventBus.coin_earned — her başarılı çağrıda
##   balance_changed      — lokal UI güncellemesi için
func earn_coins(amount: float, source: String = "") -> bool:
    ...
```

**Sınıf başına:**
```gdscript
## ChefSystem.gd
## Şef otomasyon motoru. GDD §7 — Şef (Büfeci) Sistemi.
##
## Sorumluluklar:
##   - Sıradaki siparişi almak (FIFO veya priority bump)
##   - Pişirme timerını yönetmek (slot başına)
##   - Hız Bostu (5 dk, -50% süre) uygulamak
##
## Bağımlılıklar:
##   - order_manager : OrderManager (inject edilir, null check gerekli)
##   - UpgradeSystem sinyalleri (EventBus üzerinden)
```

---

## 5. Constants Kullanımı

```gdscript
## YANLIŞ — magic number
if patience_ratio >= 0.65:
var cook : float = 8.0 / 1.15

## DOĞRU
if patience_ratio >= Constants.PATIENCE_HAPPY_THRESHOLD:
var cook : float = base_time / speed_multiplier  ## speed_mult Constants'tan geldi
```

**Kural:** GDD'den gelen her sayı `Constants.gd`'ye taşınır. Kod içinde `0.65`, `8.0`, `25` gibi "oyun değerleri" görünmez.

---

## 6. Hata Yönetimi

```gdscript
## push_error → kritik, beklenmeyen durum (ama crash ettirme)
## push_warning → beklenen ama olağandışı
## assert() → sadece debug build, production'da kapat

## DOĞRU
func _get_order(id: int) -> Order:
    if not _orders.has(id):
        push_error("OrderManager: Sipariş bulunamadı: %d" % id)
        return null
    return _orders[id]

## YANLIŞ
func _get_order(id: int) -> Order:
    return _orders[id]  ## KeyError crash

## YANLIŞ
func _get_order(id: int) -> Order:
    try:  ## GDScript'te try-catch yoktur, buna benzer pattern kullanılmaz
```

**Soft fail vs Hard fail:**
- Kullanıcı aksiyonu başarısızsa → `push_warning`, fonksiyon `false` veya `null` döner
- Programcı hatası (null referans, beklenmeyen state) → `push_error`
- Hiçbir zaman `assert()` production koduna bırakılmaz

---

## 7. Sinyal Bağlantı Kuralları

```gdscript
## _ready() içinde bağla, başka yerde değil
func _ready() -> void:
    EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
    EventBus.order_ready.connect(_on_order_ready)

## Parametre isimleri orijinal sinyal parametreleriyle eşleşmeli
func _on_upgrade_purchased(upgrade_id: String) -> void:
    ...

## Lambda sadece tek satır logic için
EventBus.toast_requested.connect(func(msg, t): toast_label.text = msg)
```

---

## 8. Extensibility Patterns

### 8.1 Yeni Müşteri Tipi Ekleme

`Constants.gd`'ye ekle → CustomerSystem otomatik tanır:

```gdscript
## Constants.gd
const CUSTOMER_TYPES := {
    "regular": {
        "patience_queue": 40.0,
        "patience_food":  30.0,
        "coin_mult":      1.0,
        "tip_mult":       1.0,
        "unlock_level":   1,
        "spawn_interval": 25.0,
    },
    "impatient": { ... },
    "tourist":  { ... },
    ## NEW TYPE:
    "vip":     {
        "patience_queue": 20.0,
        "patience_food":  15.0,
        "coin_mult":      2.0,
        "tip_mult":       1.5,
        "unlock_level":   6,   ## Cafe stage
        "spawn_interval": 60.0,
    },
}
```

### 8.2 Yeni Upgrade Ekleme

`UpgradeSystem.UPGRADE_DEFS`'e ekle → UI otomatik render eder:

```gdscript
"KIT_06": {
    "category":     "mutfak",
    "name":         "Endüstriyel Ocak",
    "cost":         50000,
    "unlock_level": 6,        ## Kafe aşaması
    "requires":     "KIT_05",
    "effect":       "speed",
    "stage":        "kafe",   ## Stage filtresi (ileride)
},
```

### 8.3 Yeni Menü Item Ekleme

```gdscript
## Constants.MENU_ITEMS'a ekle:
"waffle": {
    "name":         "Waffle",
    "price":        95,
    "cook_time":    20,
    "unlock_level": 6,
    "unlock_cost":  5000,
    "stage":        "kafe",
},
```

### 8.4 Yeni Achievement Ekleme

```gdscript
## Constants.ACHIEVEMENTS (henüz yok, eklenecek):
"ACH_11": {
    "name":       "Kafe Ustası",
    "condition":  "stage_reached",
    "value":      "kafe",
    "reward_coins": 5000,
    "reward_gems":  10,
    "is_secret":  false,
},
```

---

## 9. Sahne Bileşen Organizasyonu

**Her sahne/node için sorumluluk sınırı:**

| Katman | Sorumluluk | Örnek |
|--------|-----------|-------|
| Autoload | Global state, sinyaller | Constants, EventBus |
| System Node | İş mantığı, state | ChefSystem, OrderManager |
| Scene Script | Sahne orchestration, inject | BufeScene.gd |
| UI Component | Görsel gösterim, input | HUDBar, UpgradePanel |
| Prefab/Node | Tek entity lifecycle | CustomerNode, StoveSlot |

**Kural:** UI component asla iş mantığı içermez. System node asla UI mantığı içermez.

---

## 10. Test Yazım Kuralları (GUT)

```gdscript
## Her test tek bir davranışı test eder (single assertion tercih)
func test_earn_coins_increases_balance() -> void:
    economy.earn_coins(100.0)
    assert_almost_eq(economy.coins, 100.0, 0.01)

## İsim: test_[ne test ediliyor]_[koşul]_[beklenen sonuç]
func test_spend_coins_returns_false_if_insufficient() -> void:
    ...

## before_each temiz state başlatır
func before_each() -> void:
    system = preload("res://scripts/systems/XSystem.gd").new()
    add_child_autofree(system)
    ## Explicit init — do not rely on defaults
    system.coins = 0.0

## Signal testleri watch_signals + assert_signal_emitted
func test_earn_coins_emits_signal() -> void:
    watch_signals(economy)
    economy.earn_coins(100.0)
    assert_signal_emitted(economy, "balance_changed")
```

**Coverage beklentisi:**
- Her public fonksiyon için en az 1 happy path + 1 edge case testi
- Her `if` dalı için test (özellikle `spend_*`, `try_purchase`)
- Formüllerin doğru hesapladığı (especially economy formulas)

---

## 11. Commit Mesaj Formatı

```
feat(system): KIT_03 second stove slot upgrade effect

fix(ui): HUDBar coin animation crash on negative value

test(economy): impatient customer +20% coin bonus test

refactor(chef): _calc_cook_time boost stack mantığı netleştirildi

docs(gdd): Buffet Level 5 economy table updated
```

Format: `<type>(<scope>): <açıklama>`

Types: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`

---

## 12. Yasaklı Pratikler

```gdscript
## ❌ Magic number
if coins > 5000:

## ❌ print() production kodunda
print("Debug: coins =", coins)

## ❌ Bare get_node() path string
get_node("/root/BufeScene/Systems/ChefSystem")

## ❌ Static referans (singleton benzeri)
var _instance : EconomySystem = null
static func get_instance():

## ❌ Uzun fonksiyon (>40 satır kural değil kılavuz; >80 satır split et)

## ❌ Gereksiz comment (kodu tekrar etme)
## Coin'i artır        ← YANLIŞ
coins += amount

## ❌ TODO yorumu commitlemek
## TODO: bunu düzelt  ← YANLIŞ — ya düzelt ya issue aç
```
