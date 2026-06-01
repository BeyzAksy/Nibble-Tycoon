## BottomNav.gd
## Alt navigasyon çubuğu — 4 sekme.
## Aktif sekme coral, pasif ink-soft.
## Upgrade sekmesinde "yeni upgrade" badge noktası gösterilir.

extends Control

# ── ENUM ─────────────────────────────────────────────────────────────────────
enum Tab { RESTAURANT, MENU, UPGRADE, ACHIEVEMENT }

# ── STATE ─────────────────────────────────────────────────────────────────────
var _active_tab : Tab = Tab.RESTAURANT

# ── NODE REFERENCES ───────────────────────────────────────────────────────────
@onready var tab_restaurant : Button = $HBox/TabRestoran
@onready var tab_menu       : Button = $HBox/TabMenu
@onready var tab_upgrade    : Button = $HBox/TabUpgrade
@onready var tab_achievement: Button = $HBox/TabBasarim
@onready var upgrade_dot    : Control = $HBox/TabUpgrade/NewDot  ## Mint nokta

# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	tab_restaurant.pressed.connect(func(): _switch(Tab.RESTAURANT))
	tab_menu.pressed.connect(func():       _switch(Tab.MENU))
	tab_upgrade.pressed.connect(func():    _switch(Tab.UPGRADE))
	tab_achievement.pressed.connect(func(): _switch(Tab.ACHIEVEMENT))

	EventBus.upgrade_purchased.connect(func(_id): _hide_upgrade_dot())

	_refresh_visuals()
	set_upgrade_dot(true)   ## Başlangıçta alınabilir upgrade var


# ── TAB SWITCH ────────────────────────────────────────────────────────────────
func _switch(tab: Tab) -> void:
	_active_tab = tab
	_refresh_visuals()

	match tab:
		Tab.RESTAURANT:  EventBus.screen_transition_requested.emit("game")
		Tab.MENU:        EventBus.screen_transition_requested.emit("menu")
		Tab.UPGRADE:
			EventBus.screen_transition_requested.emit("upgrade")
			_hide_upgrade_dot()
		Tab.ACHIEVEMENT: EventBus.screen_transition_requested.emit("achievement")


func _refresh_visuals() -> void:
	var buttons := {
		Tab.RESTAURANT:  tab_restaurant,
		Tab.MENU:        tab_menu,
		Tab.UPGRADE:     tab_upgrade,
		Tab.ACHIEVEMENT: tab_achievement,
	}
	for tab in buttons:
		var btn : Button = buttons[tab]
		if not btn: continue
		var is_active := tab == _active_tab
		btn.add_theme_color_override("font_color",
			Constants.CORAL if is_active else Constants.INK_SOFT)


# ── BADGE MANAGEMENT ──────────────────────────────────────────────────────────
func set_upgrade_dot(visible_state: bool) -> void:
	if upgrade_dot:
		upgrade_dot.visible = visible_state


func _hide_upgrade_dot() -> void:
	set_upgrade_dot(false)


# ── PUBLIC API ────────────────────────────────────────────────────────────────
func force_tab(tab: Tab) -> void:
	_switch(tab)
