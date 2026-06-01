---
paths:
  - "scripts/**/*.gd"
  - "scenes/**/*.gd"
  - "autoload/**/*.gd"
---

# Game Architecture Rules

## EventBus: Sistemler Arası Direkt Çağrı Yasak

```gdscript
## FORBIDDEN
chef_system.take_order(order)
economy_system.coins += 100

## CORRECT
EventBus.order_seated.emit(customer_id)
EventBus.coin_earned.emit(amount, "order")
```

**Tek istisna:** `BufeScene._ready()` inject atamaları:
```gdscript
chef_system.order_manager = order_manager   ## acceptable
```

## UI → Sistem: Sadece EventBus

```gdscript
## WRONG
get_node("/root/BufeScene/EconomySystem").coins

## CORRECT
EventBus.balance_changed.connect(_on_balance_changed)
```

## Constants.gd: Tek Kaynak

Tüm oyun değerleri `Constants.gd`'de. Bu dosya GDD'nin kodudur.

Yeni sabit eklerken:
- GDD referansı yaz: `## GDD §X.X`
- Stage prefix kullan: `BUFFET_`, `CAFE_`
- Dict entry silme — `MENU_ITEMS` ve `LEVEL_THRESHOLDS` key'leri silinmez (save bozulur)

## EventBus Sinyal Kontratı

Mevcut sinyaller **silinmez, parametre değiştirilmez**. Yeni sinyal eklemek serbesttir.

Kritik sinyaller: `order_queued`, `order_cooking`, `order_ready`, `balance_changed`, `upgrade_purchased`

## Stage İzolasyonu

Büfe kodu `scenes/bufe/` ve `scripts/systems/` altındadır. Kafe kodu buraya bağımlı olamaz.

Global autoload sadece: `Constants`, `EventBus`, `SaveSystem`

## Katman Kuralı

```
Presentation (UI) ←EventBus→ Game Logic (Systems) → Data (Constants)
```

Presentation → Data direkt atlama yasak.

Tam detay: `ARCHITECTURE.md`
