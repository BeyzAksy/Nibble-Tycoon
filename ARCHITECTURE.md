# ARCHITECTURE.md — Mimari Kararlar

> "Neden böyle?" sorularının cevabı burada.
> Tasarım kararı değişirse nedeni commit mesajına, eski versiyon git history'e.

---

## §0 Felsefe: Tasarım Geniş, İnşa Aşamalı

Bu oyun büfeden başlar ama büfe olarak kalmaz. Kafe, Bistro ve ötesi gelecek. Bugünden bunları düşünerek tasarla, ama bugün sadece büfenin kodunu yaz.

**İki ilke çatışması yönetimi:**
1. *Premature abstraction* — bugün kullanılmayan interface yazma
2. *Tight coupling* — genişlemeyi imkânsız kılacak bağımlılık kurma

**Çözüm:** Stage izolasyonu + EventBus + data-driven config. Bugün Büfe kodlarını yaz. Kafe gerektiğinde Büfe'ye dokunmadan yeni scene ekle; paylaşılan sabitler/sinyal kontratı korunur.

---

## §1 Katman Mimarisi

```
┌─────────────────────────────────────────┐
│            PRESENTATION LAYER           │
│   scenes/  +  scripts/ui/               │
│   UI bileşenleri, animasyonlar, input   │
└────────────────┬────────────────────────┘
                 │ EventBus sinyalleri
                 │ (yukarı sinyal, aşağı method call)
┌────────────────▼────────────────────────┐
│             GAME LOGIC LAYER            │
│   scripts/systems/                      │
│   OrderManager, ChefSystem, vb.         │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│             DATA / CONFIG LAYER         │
│   autoload/Constants.gd                 │
│   autoload/SaveSystem.gd                │
│   Tüm oyun değerleri + kayıt            │
└─────────────────────────────────────────┘
```

**Kurallar:**
- Presentation → Game Logic: EventBus üzerinden veya inject edilmiş ref
- Game Logic → Presentation: EventBus sinyalleri (doğrudan referans almaz)
- Game Logic → Data: doğrudan Constants okuma (OK)
- Katmanlar arası atlamak yok (Presentation → Data direkt = yasak)

---

## §2 EventBus Pattern

### Neden?

Godot'ta sistemler arası iletişim için iki alternatif:
1. **Direkt referans**: `chef_system.take_order(order)` — hızlı, ama sıkı bağımlı
2. **EventBus**: `EventBus.order_seated.emit(id)` — gevşek bağımlı, genişleyebilir

**Tercih: EventBus** — çünkü:
- Yeni bir sistem (SatisfactionSystem, AchievementSystem) mevcut kodu değiştirmeden sinyal dinleyebilir
- Test ortamında sistemler izole edilebilir
- Log/debug için sinyaller tek noktadan izlenebilir

### Ne Zaman Direkt Çağrı Yapılır?

Sadece **sahip → çocuk ilişkisi** ve **BufeScene._ready()** inject bağlamında:

```gdscript
## BufeScene.gd _ready() — KABUL EDİLEBİLİR
func _ready() -> void:
    chef_system.order_manager   = order_manager   ## inject
    order_manager.chef_system   = chef_system     ## inject
    order_manager.economy_system = economy_system ## inject
```

Bunun dışında `get_node()` veya doğrudan referans yoktur.

### Sinyal Kontratı

EventBus.gd bir "kontrat"tır. Silinip düzenlenemeyen sinyaller:

| Sinyal | Garanti | Kullanan |
|--------|---------|---------|
| `order_queued` | Her create_order sonrası | CustomerSystem, UI |
| `order_cooking` | Her start_cooking sonrası | StoveSlot UI, HUD |
| `order_ready` | Her mark_ready sonrası | CustomerNode, HUD |
| `balance_changed` | Her earn/spend sonrası | HUDBar |
| `upgrade_purchased` | Her başarılı satın alma sonrası | ChefSystem, UI |

**Yeni sinyal eklemek serbesttir. Mevcut sinyali silmek veya parametresini değiştirmek kırılma değişikliğidir — tüm bağlananlar güncellenmeli.**

---

## §3 Data-Driven Config (Constants.gd)

### Neden Tek Dosya?

Alternatif: Her sistemin kendi sabitleri.

**Sorun:** `ChefSystem.MAX_COOK_TIME` ve `OrderManager.COOK_THRESHOLD` aynı sayıya bağlıysa, ikisini ayrı tutmak tutarsızlığa yol açar.

**Karar:** Tüm oyun değerleri `Constants.gd`'de. Bu dosya GDD'nin kodu'dur.

### Büfeden Kafe'ye Geçişte Ne Olur?

Kafe'ye özgü sabitler Constants.gd'ye `KAFE_` prefix ile eklenir:

```gdscript
## Buffet constants (current)
const BUFFET_MAX_STOOLS        := 4
const BUFFET_MAX_COOKING_SLOTS := 2

## Cafe constants (future)
const CAFE_MAX_TABLES        := 8
const CAFE_MAX_SERVERS       := 3
const CAFE_MAX_COOKING_SLOTS := 4
```

Stage-specific sabitler `stage_` prefix alır. Aynı isimsiz çakışma olmaz.

### Customer Types: Dictionary vs Enum

Mevcut durum: `customer_type : String = "regular"`

**Neden string?** Dictionary key olarak kullanmak için. Enum şimdi eklenseydi `CustomerSystem._pick_item_for_type()` match bloğu genişleyemezdi.

**Planlanan gelişim (Kafe+):** `CustomerType` resource veya enum + string map.

---

## §4 Upgrade Sistemi Tasarımı

### Veri-Driven Upgrade Tree

```gdscript
const UPGRADE_DEFS := {
    "KIT_01": {
        "category":     "mutfak",
        "name":         "Ocak Hızı 1",
        "cost":         300,
        "unlock_level": 1,
        "effect":       "speed",
    },
}
```

**Yeni upgrade = yeni dictionary key.** `_apply_effect()` `effect` string'ini okur ve uygulamayı bilir.

**Yeni effect tipi eklemek** için `_apply_effect()` match bloğuna yeni case ekle — başka değişiklik yok.

### Prerequisite Chain

`"requires": "KIT_01"` ile linear chain kurulur. GDD'nin tree yapısı bu şekilde modellenir.

**Gelecek ihtiyaç:** Birden fazla prerequisite (`requires_all: ["KIT_01", "CHF_01"]`). Şimdi yok, Dictionary format buna hazır.

### Stage Filtresi

Kafe upgradeları için `"stage": "kafe"` eklenecek. `UpgradePanel` bu field'ı okuyarak sadece aktif stage'in upgradelerini gösterecek.

---

## §5 Save System Tasarımı

### JSON + Versiyon

```gdscript
{
    "version": 2,
    "economy": { "coins": 1234.5, "gems": 5 },
    "upgrade": { "purchased": {...}, "speed_multiplier": 1.15 },
    "offline": { "close_timestamp": 1748789000, "hourly_rate": 2574 },
    "progress": { "level": 3, "total_orders": 145, "permanent_bonuses": {} },
}
```

**Versiyon yükseltme stratejisi:**
```gdscript
func deserialize(data: Dictionary) -> void:
    var version : int = data.get("version", 1)
    if version < 2:
        _migrate_v1_to_v2(data)
    ## Normal yükleme...

func _migrate_v1_to_v2(data: Dictionary) -> void:
    ## v1'de "gems" yoktu, default 0 ekle
    if not data.has("economy"):
        data["economy"] = {}
    data["economy"]["gems"] = data["economy"].get("gems", 0)
```

### Neden SQLite/Database Değil?

Büfe aşamasında save veri küçüktür (<5KB). JSON yeterlidir, Godot'ta kullanımı kolaydır, insan okunabilirdir (debug kolaylığı). PostgreSQL/SQLite ileride ihtiyaç varsa `SaveSystem` interface'i değiştirilmeden backend swap edilebilir.

---

## §6 Müşteri ve Order Lifecycle

```
CustomerSystem._try_spawn()
    → CustomerNode oluştur + setup
    → _try_seat_next() dene

CustomerSystem._try_seat_next()
    → OrderManager.create_order()       [QUEUED]
    → CustomerNode.on_seated()
    → OrderManager.seat_order()         [SEATED]

OrderManager.seat_order()
    → ChefSystem.try_take_order()       [tetikle]

ChefSystem.try_take_order()
    → OrderManager.start_cooking()      [COOKING]
    → Timer başlat (cook_time)
    → Timer bitince OrderManager.mark_ready()  [READY]

CustomerNode (READY sinyalini dinler)
    → 2.5 sn sonra OrderManager.start_eating() [EATING]

CustomerNode.eating_timer bitti
    → OrderManager.complete_order()     [DONE]
    → EconomySystem.process_order_done()
    → EventBus.xp_gained.emit()
    → CustomerSystem._remove_customer()
    → CustomerSystem._try_seat_next()   → döngü
```

**Bu döngü Büfe'de sabit kalır.** Kafe'de masa servisi farklı olsa bile `OrderManager` state machine korunur; sadece yeni state'ler (`TABLE_SEATED`, `WAITER_DELIVERING`) eklenebilir.

---

## §7 Offline Sistem Tasarımı

### Büfe'de Manager Yok

GDD §10.1'e göre Büfe aşamasında "Manager" karakteri yoktur — bu Bistro aşaması mekanizmasıdır. Büfe offline kazancı salt formül tabanlıdır.

```
offline_earnings = hourly_rate × min(elapsed, max_hours) × efficiency
```

`hourly_rate` oyun kapanırken hesaplanır ve kaydedilir. Açılırken formül uygulanır.

### Sahtecilik Önlemi

`close_timestamp` Unix epoch. Cihaz saati değiştirilerek hile yapılmasını tam olarak önlemez (client-side game), ama belirgin tutarsızlıklar (2000 saatlik offline) `max_offline_hours` cap'i ile sınırlanır.

---

## §8 Aşama Geçiş Tasarımı (Büfe → Kafe)

### Geçiş Koşulları (GDD §12.2)

```
level == 5
AND total_orders_completed >= 500
AND coins >= 5000
```

### Sahne Geçişi

```gdscript
## BufeScene.gd
func _on_kafe_transition_requested() -> void:
    SaveSystem.save(_build_full_save_data())
    ## 1 interstitial reklam (GDD §9.5)
    get_tree().change_scene_to_file("res://scenes/kafe/KafeScene.tscn")
```

### Kalıcı Bonuslar

Achievement bonusları (ACH_05, ACH_06) `permanent_bonuses` olarak save'e kaydedilir ve Kafe'ye taşınır. Bu field aşamadan bağımsızdır.

```gdscript
## SaveSystem'deki save payload
"permanent_bonuses": {
    "offline_efficiency_bonus": 0.05,   ## ACH_05
    "cay_cook_time_reduction": 0.10,   ## ACH_06
}
```

---

## §9 UI Mimarisi

### Bileşen Tipleri

| Tip | Açıklama | Örnek |
|-----|---------|-------|
| HUD | Her zaman görünür, durum gösterir | HUDBar |
| Panel | Açılıp kapanır, belirli context | UpgradePanel, MenuPanel |
| Modal | Kullanıcı aksiyon gerektirir | WelcomeModal |
| Float | Geçici, animated | CoinFloat, ToastManager |
| Prefab | Tekrar eden entity UI'ı | CustomerNode (UI kısmı), StoveSlot |

### State Yönetimi Prensibi

UI kendi state'ini tutmaz. EventBus sinyalinden güncellenir:

```gdscript
## HUDBar.gd
func _ready() -> void:
    EventBus.balance_changed.connect(_on_balance_changed)

func _on_balance_changed(coins: float, _gems: int) -> void:
    coin_label.text = "%.0f₺" % coins
    ## Hiçbir local state yok
```

### BottomNav Genişlemesi

Kafe'de yeni sekmeler (Personel, Müşteri, vs.) gelecek. `BottomNav.gd` tab listesini data-driven alır:

```gdscript
## Planlanan yapı
const TABS := [
    {"id": "upgrade", "icon": "🔧", "label": "Geliştir", "stage": "bufe"},
    {"id": "menu",    "icon": "🍽", "label": "Menü",    "stage": "bufe"},
    {"id": "staff",   "icon": "👨‍🍳", "label": "Personel","stage": "kafe"},
]
```

---

## §10 Extensibility Checklist

Yeni özellik eklerken şu soruları sor:

- [ ] Bu özellik sadece büfeye mi özgü? → `scenes/bufe/` altına
- [ ] Tüm aşamalar kullanır mı? → `autoload/` veya paylaşılan `scripts/shared/`
- [ ] Yeni sinyal gerekiyor mu? → `EventBus.gd`'ye ekle, imzayı belgele
- [ ] Yeni sabit gerekiyor mu? → `Constants.gd`'ye `STAGE_` prefix ile ekle
- [ ] Save'e yeni field? → versiyon güncelle, migration yaz
- [ ] Yeni upgrade? → sadece `UPGRADE_DEFS` dict'e satır ekle
- [ ] Yeni müşteri tipi? → `CUSTOMER_TYPES` dict'e satır ekle (planlanan)
- [ ] Yeni menü item? → `MENU_ITEMS` dict'e satır ekle
- [ ] Test yazıldı mı? → GUT unit + gerekirse integration

---

## Açık Mimari Soruları

| Konu | Durum | Karar Tarihi |
|------|-------|-------------|
| CustomerSystem → `CUSTOMER_TYPES` dict | Planlandı | Büfe bitmeden implement |
| AchievementSystem mimarisi | Belirsiz | GDD §11 var, kod yok |
| SatisfactionSystem | Sinyal var, sistem yok | Sprint 2 |
| ReklamSystem adaptörü | Yok | Platforma göre abstract interface |
| Günün Özelliği | Constants'ta placeholder | Level 5 impl sırasında |
