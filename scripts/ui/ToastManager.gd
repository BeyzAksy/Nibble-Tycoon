## ToastManager.gd
## Alt ekrandan kayan bildirim sistemi. GDD §8 animasyon takvimi
##
## Kullanım:
##   EventBus.toast_requested.emit("Mesaj", "reward")
##   Tipler: "reward" | "success" | "warning" | "error" | "idle"

extends VBoxContainer

const AUTO_DISMISS_SEC := 4.0
const SLIDE_IN_SEC     := 0.32
const FADE_OUT_SEC     := 0.40

## Achievement banner — full width, slides in from bottom
const ACHIEVEMENT_BANNER_HEIGHT := 64

# ── Toast color map ───────────────────────────────────────────────────────────
const TOAST_COLORS := {
	"reward":  {"border": Constants.BUTTER_DEEP,  "icon": "🎉"},
	"success": {"border": Constants.MINT_DEEP,    "icon": "✅"},
	"warning": {"border": Constants.BUTTER_DEEP,  "icon": "⚠️"},
	"error":   {"border": Constants.CORAL_DEEP,   "icon": "❌"},
	"idle":    {"border": Constants.SKY_DEEP,     "icon": "💤"},
}

## Max concurrent toasts (z-order rule — GDD §6)
const MAX_TOASTS := 3

var _active_toasts : Array = []

# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	EventBus.toast_requested.connect(show_toast)
	EventBus.achievement_unlocked.connect(_on_achievement_unlocked)


# ── SHOW TOAST ────────────────────────────────────────────────────────────────
func show_toast(message: String, type: String = "success") -> void:
	if _active_toasts.size() >= MAX_TOASTS:
		## Dismiss oldest toast
		_dismiss_toast(_active_toasts[0])

	var config  : Dictionary = TOAST_COLORS.get(type, TOAST_COLORS["success"])
	var panel   := _build_toast(message, config)

	add_child(panel)
	_active_toasts.append(panel)

	## Slide in
	panel.modulate.a = 0.0
	panel.position.x = 60.0
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(panel, "modulate:a", 1.0, SLIDE_IN_SEC * 0.5)
	t.parallel().tween_property(panel, "position:x", 0.0, SLIDE_IN_SEC)

	## Auto dismiss
	await get_tree().create_timer(AUTO_DISMISS_SEC).timeout
	if is_instance_valid(panel):
		_dismiss_toast(panel)


func _dismiss_toast(panel: Control) -> void:
	if not is_instance_valid(panel):
		return
	_active_toasts.erase(panel)
	var t := create_tween().set_ease(Tween.EASE_IN)
	t.tween_property(panel, "modulate:a", 0.0, FADE_OUT_SEC)
	t.tween_callback(panel.queue_free)


func _build_toast(message: String, config: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 56)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	var icon_lbl := Label.new()
	icon_lbl.text = config["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 32)

	var msg_lbl := Label.new()
	msg_lbl.text = message
	msg_lbl.add_theme_font_size_override("font_size", 24)
	msg_lbl.add_theme_color_override("font_color", Constants.INK)
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	hbox.add_child(icon_lbl)
	hbox.add_child(msg_lbl)
	panel.add_child(hbox)

	return panel


# ── ACHIEVEMENT BANNER ────────────────────────────────────────────────────────
func _on_achievement_unlocked(achievement_id: String) -> void:
	## GDD §6 — Alt ekrandan bounce ile girer, 2.5sn bekler
	## Şimdilik toast olarak gösterilir; gerçek banner ayrı scene olacak
	show_toast("🏆 Başarım açıldı! %s" % achievement_id, "reward")
