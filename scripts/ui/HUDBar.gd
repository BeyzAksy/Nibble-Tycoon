## HUDBar.gd
## Üst HUD şeridi: Coin, Gem, Level/XP, Ayarlar
## EventBus sinyallerine bağlanır, güncelleme otomatiktir.

extends Control

# ── NODE REFERENCES ───────────────────────────────────────────────────────────
@onready var coin_label  : Label = $HBox/CoinChip/CoinLabel
@onready var gem_label   : Label = $HBox/GemChip/GemLabel
@onready var level_label : Label = $HBox/LevelBadge/LevelLabel
@onready var xp_bar      : TextureProgressBar = $HBox/LevelBadge/XPBar
@onready var settings_btn: Button = $HBox/SettingsBtn
@onready var coin_chip   : PanelContainer = $HBox/CoinChip
@onready var boost_badge : Label = $BoostBadge   ## Speed boost timer display

# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	EventBus.balance_changed.connect(_on_balance_changed)
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.level_up.connect(_on_level_up)

	if boost_badge:
		boost_badge.visible = false

	## Initial render
	_refresh_display(0.0, 0)



# ── UPDATES ───────────────────────────────────────────────────────────────────
func _on_balance_changed(coins: float, gems: int) -> void:
	_animate_coin_update(coins)
	if gem_label:
		gem_label.text = str(gems)


func _animate_coin_update(coins: float) -> void:
	if not coin_label:
		return

	## Small "tick" scale animation
	var t := create_tween().set_ease(Tween.EASE_OUT)
	t.tween_property(coin_chip, "scale", Vector2(1.08, 1.08), 0.08)
	t.tween_property(coin_chip, "scale", Vector2(1.0, 1.0), 0.08)

	coin_label.text = _format_coins(coins)


func _on_xp_gained(_amount: int, _total: int) -> void:
	## XP barını güncelle (BufeScene'den gelen toplam XP ile)
	pass   ## BufeScene _on_xp_gained'da hesaplı yüzde ile çağırır


func _on_level_up(new_level: int) -> void:
	if level_label:
		level_label.text = "Lv.%d" % new_level
	## Level up flash effect
	var t := create_tween().set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate", Color(1.2, 1.1, 0.8, 1.0), 0.15)
	t.tween_property(self, "modulate", Color.WHITE, 0.3)


func update_xp_bar(ratio: float) -> void:
	if xp_bar:
		xp_bar.value = ratio * 100.0


func set_level(level: int) -> void:
	if level_label:
		level_label.text = "Lv.%d" % level


func _refresh_display(coins: float, gems: int) -> void:
	if coin_label:
		coin_label.text = _format_coins(coins)
	if gem_label:
		gem_label.text = str(gems)


# ── BOOST TIMER ───────────────────────────────────────────────────────────────
func show_boost(remaining: float) -> void:
	if not boost_badge:
		return
	boost_badge.visible = remaining > 0.0
	var minutes : int = int(remaining) / 60
	var seconds : int = int(remaining) % 60
	boost_badge.text = "⚡ %d:%02d" % [minutes, seconds]


# ── SETTINGS BUTTON ───────────────────────────────────────────────────────────
func _on_settings_pressed() -> void:
	## Open SettingsPanel — handled by BufeScene
	EventBus.screen_transition_requested.emit("settings")


# ── HELPERS ───────────────────────────────────────────────────────────────────
func _format_coins(amount: float) -> String:
	if amount >= 1_000_000:
		return "%.1fM" % (amount / 1_000_000.0)
	if amount >= 1_000:
		return "%.1fK" % (amount / 1_000.0)
	return str(int(amount))
