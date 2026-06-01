# scripts/systems/ — Modül Rehberi

> Bu klasör oyunun tüm iş mantığını içerir. UI yoktur, render yoktur.
> Her dosya için GDD referans bölümü vardır.

---

## Modül Kuralları

1. **Sistemler arası direkt çağrı yoktur** → EventBus sinyali kullan
2. **UI referansı yoktur** → sinyal yay, UI dinlesin
3. **Constants.gd dışında magic number yoktur**
4. **Her public metot typed + docstring**
5. **Inject pattern**: referanslar BufeScene._ready() içinde atanır, null check gereklidir

```gdscript
## null check pattern — required for all injected refs
func take_order() -> void:
    if not order_manager:
        push_error("ChefSystem: order_manager not injected!")
        return
```

---

## Sistemler ve Sorumlulukları

### ChefSystem.gd — GDD §7
**Sorumluluk:** Otonom pişirme motoru.

- `_process(delta)` → her 0.5 sn'de sıra kontrol
- `try_take_order()` → boş slot varsa sipariş al
- `_start_cooking_slot()` → pişirme başlat + timer
- `activate_boost()` → 5 dk %50 hız bostu (reklam/gem)
- `_on_stats_updated()` → UpgradeSystem'den stat güncellemesi

**Extension noktaları:**
- Yeni slot tipi (fırın, derin yağ vs.) → `_cooking_slots` array genişler, item'da `required_slot_type` ekle
- Özel pişirme efekti → `_calc_cook_time()` içine item_id match bloğu

---

### CustomerSystem.gd — GDD §2
**Sorumluluk:** Müşteri spawn, sabır, oturma.

- `_update_spawn_timers()` → tipe göre spawn interval
- `_try_spawn()` → kapasite kontrolü + CustomerNode oluştur
- `_try_seat_next()` → boş tabure varsa oturtur + sipariş açar
- `_on_patience_timeout()` → sabır bitti → cancel

**Extension noktaları:**
- Yeni müşteri tipi → `Constants.CUSTOMER_TYPES` dict'e ekle, `_try_spawn()` loop okur
- Özel spawn mantığı → `_pick_item_for_type()` match'e ekle
- Kapasite artışı (tabure/kuyruk) → `max_stools`, `max_queue` UpgradeSystem tarafından set edilir

**Planlanan:** `Constants.CUSTOMER_TYPES` dict okunarak spawn intervalleri ve sabır değerleri dinamik alınacak. Şu an hardcoded Constants sabitler kullanılıyor.

---

### EconomySystem.gd — GDD §5
**Sorumluluk:** Coin ve gem kazanma/harcama.

- `earn_coins(amount, source)` → bakiye artır + sinyal yay
- `spend_coins(amount, target)` → bakiye kontrol + düş (false dönerse yetersiz)
- `earn_gems()` / `spend_gems()` → aynı pattern
- `process_order_done()` → GDD §5.2 formülü uygula
- `calculate_hourly_rate()` → offline sistem için saatlik kazanç hesabı

**Formüller (değiştirme, sadece Constants'taki çarpanları güncelle):**
```
order_value = base_price × (1 + chef_quality × ORDER_QUALITY_MULT)
tip         = base_price × patience_ratio × TIP_PATIENCE_MULT + chef_quality × TIP_QUALITY_MULT
total       = order_value + tip × (müşteri tipi çarpanı)
```

**Extension noktaları:**
- Yeni para birimi (token, yıldız) → ayrı field ekle, aynı earn/spend pattern
- Prestige/reset → `reset_coins()` ekle, `permanent_bonuses` korunur

---

### OfflineSystem.gd — GDD §10
**Sorumluluk:** Oyun kapandığında geçen sürenin kazancını hesaplamak.

- `save_close_data(hourly_rate)` → timestamp + rate kaydet
- `calculate_earnings(save_data)` → elapsed × rate × efficiency × cap
- `collect_earnings(amount)` → forward to EconomySystem
- `apply_2x_reward(base)` → reklam sonrası 2× bonus

**Extension noktaları:**
- Manager karakteri (Bistro aşaması) → `manager_bonus_mult` field + formüle ekle
- Offline animasyon kuyruğu → kazanç ayrıntılarını dönen payload'a ekle

---

### OrderManager.gd — GDD §6
**Sorumluluk:** Sipariş state machine.

State geçişleri:
```
QUEUED → SEATED → COOKING → READY → EATING → DONE
QUEUED → CANCELLED_QUEUE
SEATED → CANCELLED_ANGRY
```

- `create_order()` → yeni Order nesnesi + QUEUED
- `seat_order()` → SEATED + ChefSystem tetikle
- `start_cooking()` / `mark_ready()` / `start_eating()` / `complete_order()`
- `cancel_order(reason)` → "queue" | "angry"
- `get_next_order_for_chef(chef_level)` → FIFO or impatient priority bump

**Extension noktaları:**
- Yeni state (TABLE_SEATED, WAITING_WAITER) → `OrderState` enum genişler
- Kafe masa servisi → `complete_order()` sonrası `tip_to_table()` gibi hook
- SatisfactionSystem entegrasyonu → `cancel_order()` içinde sinyal hazır

---

### SaveSystem.gd — GDD §10.2
**Sorumluluk:** JSON kayıt/yükleme.

- `save(data: Dictionary)` → user://lezzet_save.json
- `load_data()` → Dictionary (boş dict yoksa)
- `delete_save()` → sıfırlama

**Versiyon kuralı:** Her yeni field için `"version"` güncelle + migration yaz. Bkz. `ARCHITECTURE.md §5`.

**Extension noktaları:**
- Cloud save → `save()` signature değişmez, içeride ek remote call
- Multiple save slots → path'i parametre al: `save(data, slot_id: int = 0)`
- Şifreleme → `JSON.stringify()` çıktısını şifrele, format değişmez

---

### UpgradeSystem.gd — GDD §8
**Sorumluluk:** Upgrade tanımları, satın alma, efekt uygulama.

- `try_purchase(upgrade_id, level)` → kilit/para kontrol + efekt uygula
- `get_status(upgrade_id, level)` → "done" | "available" | "locked"
- `get_upgrades_by_category(category)` → UI için filtrelenmiş liste
- `serialize()` / `deserialize()` → save/load
- `_apply_effect(id, def)` → efekt uygulama merkezi

**Yeni upgrade eklemek = sadece UPGRADE_DEFS'e satır:**
```gdscript
"KIT_06": {
    "category":     "kitchen",
    "name":         "Advanced Oven",
    "cost":         50000,
    "unlock_level": 6,       ## cafe stage
    "requires":     "KIT_05",
    "effect":       "speed",
    "stage":        "cafe",  ## future stage filter
},
```

**Yeni effect tipi = `_apply_effect()` match'e yeni case:**
```gdscript
"custom_effect":
    ## yeni efekt mantığı
```

---

## Sistem Bağımlılık Özeti

```
CustomerSystem  →[sinyal]→  OrderManager
OrderManager    →[inject]→  ChefSystem
OrderManager    →[inject]→  EconomySystem
ChefSystem      →[inject]→  OrderManager
UpgradeSystem   →[inject]→  EconomySystem
UpgradeSystem   →[inject]→  ChefSystem (stats)
UpgradeSystem   →[inject]→  CustomerSystem (capacity)
UpgradeSystem   →[inject]→  OfflineSystem (efficiency)
OfflineSystem   →[inject]→  EconomySystem
```

Inject = BufeScene._ready() içinde `system.ref = other_system`.

---

## Ortak Test Pattern

```gdscript
func before_each() -> void:
    system = preload("res://scripts/systems/XSystem.gd").new()
    add_child_autofree(system)
    ## Inject all dependencies as mock or real instances
    economy = preload("res://scripts/systems/EconomySystem.gd").new()
    add_child_autofree(economy)
    system.economy_system = economy
    ## Explicit state init
    economy.coins = 0.0
    system.reset_to_defaults()   ## optional — if method exists
```

---

<!-- Bekleyen işler Jira'da yönetilir — LI-CORE-LOOP, LI-CUSTOMER, LI-PROGRESSION epic'leri. -->
