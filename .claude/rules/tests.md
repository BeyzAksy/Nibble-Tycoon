---
paths:
  - "tests/**/*.gd"
---

# GUT Test Kuralları

## İsimlendirme

```gdscript
## Format: test_[ne]_[koşul]_[beklenen]
func test_spend_coins_returns_false_if_insufficient() -> void:
func test_order_state_is_queued_after_creation() -> void:
```

## before_each: Explicit Init

```gdscript
func before_each() -> void:
    system = preload("res://scripts/systems/XSystem.gd").new()
    add_child_autofree(system)
    system.coins = 0.0    ## explicit — default'a güvenme
```

## Sinyal Testi

```gdscript
func test_earn_coins_emits_balance_changed() -> void:
    watch_signals(economy)
    economy.earn_coins(100.0, "order")
    assert_signal_emitted(economy, "balance_changed")
```

## Float Karşılaştırma

```gdscript
assert_almost_eq(result, 26.0, 0.01, "Tea + chef_quality 1 → 26.0₺")
assert_almost_eq(offline_earn, 5400.0, 50.0, "Level 1 offline table")
```

## Integration Test: Timer Yok

State machine doğrudan sürülür, `await` kullanılmaz:
```gdscript
manager.create_order(1, "regular", "tea")
manager.seat_order(order_id)
manager.start_cooking(order_id)
manager.complete_order(order_id)
assert_true(economy.coins > 0.0)
```

## Coverage Minimumu

- Her public metod: 1 happy path
- Her `if` dalı: edge case
- Her GDD formülü: sayısal doğrulama
- Her sinyal: emit kontrolü
- Her `false`/`null` dönen durum: negatif test
