## EventBus.gd
## Global sinyal merkezi — sistemler arası direkt çağrı yerine sinyal kullanılır.
## Autoload olarak yüklenir.
##
## Kullanım:
##   EventBus.order_queued.emit(customer_id)
##   EventBus.order_queued.connect(_on_order_queued)

extends Node

# ── ORDER SIGNALS ─────────────────────────────────────────────────────────────
signal order_queued(customer_id: int)
signal order_seated(customer_id: int)
signal order_cooking(customer_id: int, item_id: String)
signal order_ready(customer_id: int, item_id: String)
signal order_served(customer_id: int)
signal order_cancelled(customer_id: int, reason: String)  ## reason: "queue" | "angry"

# ── ECONOMY SIGNALS ───────────────────────────────────────────────────────────
signal coin_earned(amount: float, source: String)
signal coin_spent(amount: float, target: String)
signal gem_earned(amount: int, source: String)
signal gem_spent(amount: int, target: String)
## Yayıldığı zaman: Her coin/gem bakiye değişiminde
## Dinleyenler: HUDBar
signal balance_changed(coins: float, gems: int)

# ── CHEF SIGNALS ──────────────────────────────────────────────────────────────
## Yayıldığı zaman: Bir ocak slotu pişirmeye başladığında
## Dinleyenler: BufeScene (StoveSlot görseli)
signal chef_slot_started_cooking(slot_index: int, order_id: int, item_id: String, cook_time: float)
## Yayıldığı zaman: Bir ocak slotu pişirmeyi tamamladığında
## Dinleyenler: BufeScene (StoveSlot görseli)
signal chef_slot_finished(slot_index: int, order_id: int)
## Yayıldığı zaman: Hız bostu aktifken her frame
## Dinleyenler: HUDBar (boost timer göstergesi)
signal chef_boost_tick(remaining: float)

# ── UPGRADE SIGNALS ───────────────────────────────────────────────────────────
signal upgrade_purchased(upgrade_id: String)
signal chef_stats_updated(speed_mult: float, quality: int, slot_count: int)

# ── CUSTOMER SIGNALS ──────────────────────────────────────────────────────────
signal customer_spawned(customer_id: int, customer_type: String)
signal customer_patience_changed(customer_id: int, ratio: float)
signal customer_left(customer_id: int)

# ── SATISFACTION ──────────────────────────────────────────────────────────────
## Yayıldığı zaman: Her satisfaction skoru değiştiğinde
## Dinleyenler: HUDBar (ileride), AchievementSystem (ileride)
signal satisfaction_changed(score: int, delta: int)

# ── LEVEL / PROGRESS ──────────────────────────────────────────────────────────
signal level_up(new_level: int)
signal xp_gained(amount: int, total: int)
signal achievement_unlocked(achievement_id: String)

# ── OFFLINE ───────────────────────────────────────────────────────────────────
signal offline_earnings_ready(amount: float, elapsed_hours: float)

# ── UI SIGNALS ────────────────────────────────────────────────────────────────
signal toast_requested(message: String, type: String)  ## type: "reward"|"success"|"warning"|"error"
signal screen_transition_requested(target_scene: String)
