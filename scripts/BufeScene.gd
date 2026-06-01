## BufeScene.gd
## Büfe aşamasının ana koordinatör scripti.
## Tüm sistemleri bağlar, save/load yönetir, XP/Level takip eder.
##
## Sahne yapısı (BufeScene.tscn):
##   BufeScene (Node2D)
##   ├── GameWorld (Node2D)
##   │   ├── TileMap (TileMap)            ← zemin deseni
##   │   ├── WallSprite (Sprite2D)
##   │   ├── CounterBody (StaticBody2D)
##   │   ├── ChefSprite (AnimatedSprite2D)
##   │   ├── OcakContainer (Node2D)
##   │   │   ├── StoveSlot1 (Node2D)
##   │   │   └── StoveSlot2 (Node2D)
##   │   ├── StoolContainer (Node2D)
##   │   └── CustomerContainer (Node2D)
##   ├── UILayer (CanvasLayer)
##   │   ├── HUDBar (Control)
##   │   ├── BottomNav (Control)
##   │   ├── ToastContainer (VBoxContainer) ← ToastManager
##   │   ├── CoinFloatLayer (Node2D)
##   │   ├── UpgradePanel (Control)         ← başta gizli
##   │   ├── MenuPanel (Control)            ← başta gizli
##   │   ├── AchievementPanel (Control)     ← başta gizli
##   │   └── WelcomeModal (Control)         ← offline reward
##   └── Systems (Node)
##       ├── CustomerSystem
##       ├── OrderManager
##       ├── ChefSystem
##       ├── EconomySystem
##       ├── UpgradeSystem
##       ├── OfflineSystem
##       ├── SaveSystem
##       ├── ProgressionSystem
##       └── SatisfactionSystem

extends Node2D

# ── NODE REFERENCES ───────────────────────────────────────────────────────────
@onready var customer_container : Node    = $GameWorld/CustomerContainer
@onready var chef_sprite        : Node    = $GameWorld/ChefSprite
@onready var stove_slots        : Node    = $GameWorld/OcakContainer

@onready var hud_bar            : Control = $UILayer/HUDBar
@onready var bottom_nav         : Control = $UILayer/BottomNav
@onready var toast_manager      : Node    = $UILayer/ToastContainer
@onready var coin_float_layer   : Node    = $UILayer/CoinFloatLayer
@onready var upgrade_panel      : Control = $UILayer/UpgradePanel
@onready var menu_panel         : Control = $UILayer/MenuPanel
@onready var achievement_panel  : Control = $UILayer/AchievementPanel
@onready var welcome_modal      : Control = $UILayer/WelcomeModal

## Sistemler
@onready var customer_system    : Node = $Systems/CustomerSystem
@onready var order_manager      : Node = $Systems/OrderManager
@onready var chef_system        : Node = $Systems/ChefSystem
@onready var economy_system     : Node = $Systems/EconomySystem
@onready var upgrade_system     : Node = $Systems/UpgradeSystem
@onready var offline_system     : Node = $Systems/OfflineSystem
@onready var save_system        : Node = $Systems/SaveSystem
@onready var progression_system    : Node = $Systems/ProgressionSystem
@onready var satisfaction_system   : Node = $Systems/SatisfactionSystem
@onready var achievement_system    : Node = $Systems/AchievementSystem

var _pending_offline_earnings : float = 0.0

# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_wire_systems()
	_connect_signals()
	_load_save()
	_check_offline_earnings()
	_start_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_game()


# ── SYSTEM WIRING ─────────────────────────────────────────────────────────────
func _wire_systems() -> void:
	## Referansları birbirine bağla
	order_manager.chef_system    = chef_system
	order_manager.economy_system = economy_system

	chef_system.order_manager    = order_manager

	upgrade_system.economy_system  = economy_system
	upgrade_system.offline_system  = offline_system
	upgrade_system.customer_system = customer_system

	offline_system.economy_system = economy_system
	offline_system.upgrade_system = upgrade_system

	customer_system.order_manager   = order_manager
	customer_system.customer_parent = customer_container

	if achievement_system:
		achievement_system.economy_system = economy_system
		achievement_system.chef_system    = chef_system
		achievement_system.offline_system = offline_system

	## Upgrade/MenuPanel referansları
	if upgrade_panel and upgrade_panel.has_method("setup"):
		upgrade_panel.setup(upgrade_system, economy_system)


func _connect_signals() -> void:
	EventBus.xp_gained.connect(_on_xp_gained_hud)
	EventBus.level_up.connect(_on_level_up_scene)
	EventBus.coin_earned.connect(_on_coin_earned_for_float)
	EventBus.screen_transition_requested.connect(_on_screen_transition)

	EventBus.chef_slot_started_cooking.connect(_on_slot_cooking)
	EventBus.chef_slot_finished.connect(_on_slot_finished)
	EventBus.chef_boost_tick.connect(_on_boost_tick)
	EventBus.upgrade_purchased.connect(func(_id: String) -> void: _refresh_upgrade_ui())


# ── SAVE SYSTEM ───────────────────────────────────────────────────────────────
func _load_save() -> void:
	var data := save_system.load_data()
	if data.is_empty():
		return

	## Economy
	if economy_system:
		economy_system.coins = data.get("coins", 0.0)
		economy_system.gems  = data.get("gems",  0)

	## XP / Level — migration: eski kayıtlarda flat key'ler vardı
	var prog_data : Dictionary = data.get("progression", {
		"level":        data.get("level",    1),
		"total_orders": data.get("total_xp", 0),
	})
	progression_system.deserialize(prog_data)

	## Satisfaction
	if satisfaction_system:
		satisfaction_system.deserialize(data.get("satisfaction", {}))

	## Achievements (deserialize kalıcı bonusları da uygular)
	if achievement_system:
		achievement_system.deserialize(data.get("achievements", {}))

	## Upgrade
	if upgrade_system and data.has("upgrades"):
		upgrade_system.deserialize(data["upgrades"])

	## Menü unlock'ları (UpgradeSystem'da menü unlock yok, Constants'tan level bazlı kontrol)


func _save_game() -> void:
	var hourly := economy_system.calculate_hourly_rate(upgrade_system) if economy_system else 0.0
	var offline_data := offline_system.save_close_data(hourly) if offline_system else {}

	var ach_data := achievement_system.serialize() if achievement_system else {}
	var data := {
		"version":           Constants.CURRENT_SAVE_VERSION,
		"achievements":      ach_data,
		"permanent_bonuses": ach_data.get("permanent_bonuses", {}),
		"coins":             economy_system.coins if economy_system else 0.0,
		"gems":              economy_system.gems  if economy_system else 0,
		"progression":       progression_system.serialize()  if progression_system  else {},
		"satisfaction":      satisfaction_system.serialize() if satisfaction_system else {},
		"upgrades":          upgrade_system.serialize()      if upgrade_system      else {},
	}
	data.merge(offline_data)
	save_system.save(data)


# ── OFFLINE CHECK ─────────────────────────────────────────────────────────────
func _check_offline_earnings() -> void:
	var saved := save_system.load_data()
	if not saved.has("close_timestamp"):
		return

	var result := offline_system.calculate_earnings(saved)

	## ACH_05: 2 saat offline bekleme koşulu
	if achievement_system:
		achievement_system.notify_offline_sleep(result.get("elapsed_hours", 0.0))

	var earnings : float = result.get("earnings", 0.0)
	if earnings <= 0.0:
		return

	_pending_offline_earnings = earnings

	## Welcome modal'ı göster
	if welcome_modal:
		welcome_modal.show_earnings(
			earnings,
			result.get("elapsed_hours", 0.0),
			result.get("storage_full", false),
			progression_system.current_level
		)
		welcome_modal.collect_pressed.connect(_on_offline_collect)
		welcome_modal.watch_ad_pressed.connect(_on_offline_2x)
		welcome_modal.visible = true


func _on_offline_collect() -> void:
	offline_system.collect_earnings(_pending_offline_earnings)
	welcome_modal.visible = false
	_pending_offline_earnings = 0.0


func _on_offline_2x() -> void:
	## Reklam izleme (AdMobPlugin entegrasyonu sonrası)
	## Şimdilik direkt 2× ver
	offline_system.collect_earnings(_pending_offline_earnings)          ## 1×
	offline_system.apply_2x_reward(_pending_offline_earnings)           ## +1× bonus
	welcome_modal.visible = false
	_pending_offline_earnings = 0.0


# ── START GAME ────────────────────────────────────────────────────────────────
func _start_game() -> void:
	customer_system.current_level = progression_system.current_level
	## Müşteri spawn döngüsü CustomerSystem._process içinde otomatik başlar

	## İlk balance render
	if hud_bar:
		hud_bar.set_level(progression_system.current_level)
		hud_bar.update_xp_bar(progression_system.get_xp_ratio())


# ── XP / LEVEL ────────────────────────────────────────────────────────────────
## xp_gained sinyali gelince sadece HUD XP barını günceller.
## Level hesabı ProgressionSystem tarafından yapılır.
func _on_xp_gained_hud(_amount: int, _total: int) -> void:
	if hud_bar:
		hud_bar.update_xp_bar(progression_system.get_xp_ratio())


## ProgressionSystem level_up emit edince UI ve bağlı sistemleri günceller.
##
## Args:
##   new_level: Ulaşılan yeni level.
func _on_level_up_scene(new_level: int) -> void:
	customer_system.current_level = new_level
	if hud_bar:
		hud_bar.set_level(new_level)
		hud_bar.update_xp_bar(progression_system.get_xp_ratio())
	EventBus.toast_requested.emit("Level %d! Yeni icerikler acildi!" % new_level, "reward")
	if new_level >= 5:
		_check_cafe_transition()


func _check_cafe_transition() -> void:
	if economy_system and economy_system.coins >= Constants.CAFE_TRANSITION_COST:
		EventBus.toast_requested.emit(
			"Kafe'ye gecmeye hazirsin! Upgrade ekranini kontrol et.",
			"reward"
		)


# ── CHEF / STOVE VISUALS ──────────────────────────────────────────────────────
func _on_slot_cooking(slot_index: int, order_id: int, item_id: String, cook_time: float) -> void:
	## Update the StoveSlot node
	var slot := stove_slots.get_child(slot_index) if stove_slots else null
	if slot and slot.has_method("start_cooking"):
		slot.start_cooking(item_id, cook_time)


func _on_slot_finished(slot_index: int, _order_id: int) -> void:
	var slot := stove_slots.get_child(slot_index) if stove_slots else null
	if slot and slot.has_method("finish_cooking"):
		slot.finish_cooking()


func _on_boost_tick(remaining: float) -> void:
	if hud_bar:
		hud_bar.show_boost(remaining)


# ── COIN FLOAT ────────────────────────────────────────────────────────────────
func _on_coin_earned_for_float(amount: float, source: String) -> void:
	if source not in ["order", "offline_2x"]:
		return
	if not coin_float_layer:
		return
	## Spawn coin float — pozisyon counter'dan alınacak (şimdilik merkez)
	var world_pos := Vector2(540, 600)
	CoinFloat.spawn(coin_float_layer, world_pos, amount, source == "tip")


# ── PANEL NAVIGATION ──────────────────────────────────────────────────────────
func _on_screen_transition(target: String) -> void:
	_hide_all_panels()
	match target:
		"game":
			pass   ## Oyun zaten görünür
		"upgrade":
			if upgrade_panel: upgrade_panel.visible = true
		"menu":
			if menu_panel: menu_panel.visible = true
		"achievement":
			if achievement_panel: achievement_panel.visible = true
		"settings":
			pass   ## SettingsPanel ayrıca implemente edilecek


func _hide_all_panels() -> void:
	for panel in [upgrade_panel, menu_panel, achievement_panel]:
		if panel:
			panel.visible = false


func _refresh_upgrade_ui() -> void:
	if upgrade_panel and upgrade_panel.has_method("refresh"):
		upgrade_panel.refresh(progression_system.current_level)
