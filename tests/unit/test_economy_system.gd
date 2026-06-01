## test_economy_system.gd
## EconomySystem coin/gem kazanma, harcama ve sipariş ödeme testleri.

extends GutTest

const EconomySystem = preload("res://scripts/systems/EconomySystem.gd")

var economy : EconomySystem

func before_each() -> void:
	economy = EconomySystem.new()
	add_child_autofree(economy)
	economy.coins = 0.0
	economy.gems  = 0

# ── COIN EARN ─────────────────────────────────────────────────────────────────

func test_earn_coins_increases_balance() -> void:
	economy.earn_coins(100.0)
	assert_almost_eq(economy.coins, 100.0, 0.01)

func test_earn_coins_accumulates() -> void:
	economy.earn_coins(50.0)
	economy.earn_coins(75.0)
	assert_almost_eq(economy.coins, 125.0, 0.01)

func test_earn_coins_emits_signal() -> void:
	watch_signals(economy)
	economy.earn_coins(200.0, "order")
	assert_signal_emitted(economy, "balance_changed",
		"balance_changed signal must fire when coins are earned")

func test_earn_coins_zero_does_not_change_balance() -> void:
	economy.earn_coins(0.0)
	assert_almost_eq(economy.coins, 0.0, 0.01)

# ── COIN SPEND ────────────────────────────────────────────────────────────────

func test_spend_coins_decreases_balance() -> void:
	economy.coins = 500.0
	var ok := economy.spend_coins(200.0)
	assert_true(ok, "Spending with sufficient balance must succeed")
	assert_almost_eq(economy.coins, 300.0, 0.01)

func test_spend_coins_returns_false_if_insufficient() -> void:
	economy.coins = 100.0
	var ok := economy.spend_coins(200.0)
	assert_false(ok, "Insufficient coins must return false")

func test_spend_coins_does_not_go_negative() -> void:
	economy.coins = 50.0
	economy.spend_coins(200.0)
	assert_true(economy.coins >= 0.0, "Coins must not go negative")

func test_spend_coins_exact_balance() -> void:
	economy.coins = 300.0
	var ok := economy.spend_coins(300.0)
	assert_true(ok, "Spending exact balance must succeed")
	assert_almost_eq(economy.coins, 0.0, 0.01)

func test_spend_coins_emits_signal_on_success() -> void:
	economy.coins = 1000.0
	watch_signals(economy)
	economy.spend_coins(500.0)
	assert_signal_emitted(economy, "balance_changed")

# ── GEM EARN ──────────────────────────────────────────────────────────────────

func test_earn_gems_increases_balance() -> void:
	economy.earn_gems(5)
	assert_eq(economy.gems, 5)

func test_earn_gems_accumulates() -> void:
	economy.earn_gems(3)
	economy.earn_gems(2)
	assert_eq(economy.gems, 5)

# ── GEM SPEND ─────────────────────────────────────────────────────────────────

func test_spend_gems_decreases_balance() -> void:
	economy.gems = 10
	var ok := economy.spend_gems(5)
	assert_true(ok)
	assert_eq(economy.gems, 5)

func test_spend_gems_returns_false_if_insufficient() -> void:
	economy.gems = 3
	var ok := economy.spend_gems(5)
	assert_false(ok, "Insufficient gems must return false")
	assert_eq(economy.gems, 3, "Gem amount must not change on failure")

# ── ORDER PAYMENT ─────────────────────────────────────────────────────────────

func test_process_order_done_adds_coins() -> void:
	economy.coins = 0.0
	economy.process_order_done(25, 1.0, 1, "regular")
	assert_true(economy.coins > 0.0,
		"Completing an order must add coins")

func test_process_order_done_happy_customer_earns_more() -> void:
	economy.coins = 0.0
	economy.process_order_done(25, 1.0, 1, "regular")   ## happy
	var happy_earnings := economy.coins

	economy.coins = 0.0
	economy.process_order_done(25, 0.10, 1, "regular")  ## angry
	var angry_earnings := economy.coins

	assert_true(happy_earnings > angry_earnings,
		"Happy customer must earn more tip than angry customer")

func test_process_order_done_impatient_bonus() -> void:
	economy.coins = 0.0
	economy.process_order_done(25, 1.0, 1, "regular")
	var regular_earnings := economy.coins

	economy.coins = 0.0
	economy.process_order_done(25, 1.0, 1, "impatient")
	var impatient_earnings := economy.coins

	assert_true(impatient_earnings > regular_earnings,
		"Impatient customer must give +20%% coin bonus (GDD §2.1)")

func test_process_order_done_tourist_tip_bonus() -> void:
	economy.coins = 0.0
	economy.process_order_done(75, 1.0, 1, "regular")
	var regular_earnings := economy.coins

	economy.coins = 0.0
	economy.process_order_done(75, 1.0, 1, "tourist")
	var tourist_earnings := economy.coins

	assert_true(tourist_earnings > regular_earnings,
		"Tourist must give +30%% tip bonus (GDD §2.1)")
