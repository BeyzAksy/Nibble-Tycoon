---
paths:
  - "**/*.gd"
---

# GDScript Conventions

## Tip Zorunlu

```gdscript
## CORRECT
var coins : float = 0.0
func earn_coins(amount: float, source: String = "") -> void:

## WRONG
var coins = 0
func earn_coins(amount, source = ""):
```

## Magic Number Yasak

```gdscript
## FORBIDDEN
if patience_ratio >= 0.65:
var cook_time := 8.0

## CORRECT
if patience_ratio >= Constants.PATIENCE_HAPPY_THRESHOLD:
var cook_time : float = Constants.MENU_ITEMS[item_id]["cook_time"]
```

## Docstring — Her Public Fonksiyon

```gdscript
## Coin bakiyesini artırır ve EventBus sinyali yayar.
##
## Args:
##   amount: Kazanılacak coin. Sıfır veya negatif kabul edilmez.
##   source: Kaynak etiketi ("order", "offline", "ad_reward").
func earn_coins(amount: float, source: String = "") -> void:
```

## Hata Yönetimi

```gdscript
## CORRECT — soft fail
if not _orders.has(order_id):
    push_error("OrderManager: Order not found: %d" % order_id)
    return null

## WRONG — crash
return _orders[order_id]
```

`push_error` → beklenmeyen durum. `push_warning` → beklenen ama olağandışı. `print()` yasak.

## İsimlendirme

| Tip | Format | Örnek |
|-----|--------|-------|
| Değişken | `snake_case` | `coin_balance` |
| Private | `_underscore` | `_cooking_slots` |
| Sabit | `SCREAMING_SNAKE` (sadece Constants.gd) | `BUFFET_MAX_STOOLS` |
| Sınıf | `PascalCase` | `ChefSystem` |
| Sinyal handler | `_on_` prefix | `_on_order_queued` |

## Sinyal Bağlantısı

```gdscript
## _ready() içinde bağla, başka yerde değil
func _ready() -> void:
    EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
```

## Kod Dili

Tüm kod İngilizce: identifier, dict key, inline comment, push_error mesajı.
Türkçe kabul edilen: docstring (`##`), UI metinleri, `.md` prose.

```gdscript
## WRONG
var ekonomi : Node
push_error("Sipariş bulunamadı")

## CORRECT
var economy : Node
push_error("Order not found: %d" % order_id)
```

## Null Check

```gdscript
func process() -> void:
    if not order_manager:
        push_error("ChefSystem: order_manager not injected!")
        return
```

Tam detay: `CONVENTIONS.md`
