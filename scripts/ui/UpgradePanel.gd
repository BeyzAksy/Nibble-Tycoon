## UpgradePanel.gd
## Upgrade bottom-sheet. Ekranın %65'ini kaplar, 4 kategori tab.
## GDD §7 — Upgrade paneli

extends Control

# ── NODE REFERENCES ───────────────────────────────────────────────────────────
@onready var sheet_container : Control    = $SheetContainer
@onready var drag_handle     : Control    = $SheetContainer/DragHandle
@onready var tab_bar         : HBoxContainer = $SheetContainer/TabBar
@onready var list_container  : VBoxContainer = $SheetContainer/ScrollContainer/ListContainer

# ── STATE ─────────────────────────────────────────────────────────────────────
var _upgrade_system  : Node = null
var _economy_system  : Node = null
var _current_level   : int  = 1
var _active_category : String = "kitchen"

const CATEGORIES := ["kitchen", "counter", "chef", "idle"]
const CAT_LABELS  := {
	"kitchen": "🍳 Mutfak",
	"counter": "🪑 Tezgah",
	"chef":    "👨‍🍳 Şef",
	"idle":    "💤 Idle",
}

# ── SETUP ─────────────────────────────────────────────────────────────────────
func setup(upgrade_system: Node, economy_system: Node) -> void:
	_upgrade_system = upgrade_system
	_economy_system = economy_system


# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_tab_bar()
	EventBus.upgrade_purchased.connect(func(_id): refresh(_current_level))


func _on_visibility_changed() -> void:
	if visible:
		refresh(_current_level)
		_play_intro()


# ── TAB BAR ───────────────────────────────────────────────────────────────────
func _build_tab_bar() -> void:
	if not tab_bar: return
	for child in tab_bar.get_children():
		child.queue_free()

	for cat in CATEGORIES:
		var btn := Button.new()
		btn.text = CAT_LABELS[cat]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): _switch_category(cat))

		## New upgrade badge indicator
		var has_new := _has_available_upgrade(cat)
		if has_new:
			btn.text += " ●"
			btn.add_theme_color_override("font_color", Constants.MINT_DEEP)

		tab_bar.add_child(btn)


func _switch_category(category: String) -> void:
	_active_category = category
	refresh(_current_level)
	_update_tab_styles()


func _update_tab_styles() -> void:
	if not tab_bar: return
	for i in tab_bar.get_child_count():
		var btn : Button = tab_bar.get_child(i)
		var is_active := CATEGORIES[i] == _active_category
		btn.add_theme_color_override(
			"font_color",
			Constants.CARD if is_active else Constants.INK_SOFT
		)


# ── BUILD LIST ────────────────────────────────────────────────────────────────
func refresh(current_level: int) -> void:
	_current_level = current_level
	if not list_container or not _upgrade_system:
		return

	for child in list_container.get_children():
		child.queue_free()

	var upgrades : Array = _upgrade_system.get_upgrades_by_category(_active_category)
	for entry in upgrades:
		var id      : String     = entry["id"]
		var def     : Dictionary = entry["def"]
		var status  : String     = _upgrade_system.get_status(id, current_level)
		var card    := _build_card(id, def, status)
		list_container.add_child(card)

	_build_tab_bar()
	_update_tab_styles()


func _build_card(id: String, def: Dictionary, status: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 110)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)

	## Icon
	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(80, 80)
	var icon_lbl := Label.new()
	icon_lbl.text = _get_icon(id, status)
	icon_lbl.add_theme_font_size_override("font_size", 36)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon_box.add_child(icon_lbl)

	## Content
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var id_lbl := Label.new()
	id_lbl.text = id
	id_lbl.add_theme_font_size_override("font_size", 20)
	id_lbl.add_theme_color_override("font_color", Constants.INK_SOFT)

	var name_lbl := Label.new()
	name_lbl.text = def.get("name", "")
	name_lbl.add_theme_font_size_override("font_size", 30)
	name_lbl.add_theme_color_override("font_color",
		Constants.INK_SOFT if status == "locked" else Constants.INK)

	var eff_lbl := Label.new()
	eff_lbl.text = _get_effect_text(id)
	eff_lbl.add_theme_font_size_override("font_size", 24)
	eff_lbl.add_theme_color_override("font_color", Constants.INK_SOFT)
	eff_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD

	var footer := HBoxContainer.new()
	var tag    := _build_tag(id, status, def)
	var action := _build_action_btn(id, def, status)

	footer.add_child(tag)
	footer.add_child(action)

	vbox.add_child(id_lbl)
	vbox.add_child(name_lbl)
	vbox.add_child(eff_lbl)
	vbox.add_child(footer)

	hbox.add_child(icon_box)
	hbox.add_child(vbox)
	card.add_child(hbox)

	## Left border color for available upgrades
	if status == "available":
		card.add_theme_stylebox_override("panel", _make_left_border_style(Constants.MINT_DEEP))

	return card


func _build_tag(id: String, status: String, def: Dictionary) -> Label:
	var tag := Label.new()
	tag.add_theme_font_size_override("font_size", 20)
	match status:
		"done":
			tag.text = "COMPLETED"
			tag.add_theme_color_override("font_color", Constants.MINT_DEEP)
		"available":
			tag.text = "AVAILABLE"
			tag.add_theme_color_override("font_color", Constants.MINT_DEEP)
		"locked":
			var req_level : int = def.get("unlock_level", 1)
			tag.text = "LOCKED · Lv%d" % req_level
			tag.add_theme_color_override("font_color", Constants.INK_SOFT)
	return tag


func _build_action_btn(id: String, def: Dictionary, status: String) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END

	match status:
		"done":
			btn.text = "%d 🪙" % int(def.get("cost", 0))
			btn.disabled = true
		"available":
			btn.text = "Satın Al · %d 🪙" % int(def.get("cost", 0))
			btn.pressed.connect(func(): _on_buy_pressed(id))
		"locked":
			btn.text = "%d 🪙" % int(def.get("cost", 0))
			btn.disabled = true

	return btn


func _on_buy_pressed(upgrade_id: String) -> void:
	if not _upgrade_system: return
	var success := _upgrade_system.try_purchase(upgrade_id, _current_level)
	if success:
		refresh(_current_level)


func _make_left_border_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.border_width_left  = 4
	sb.border_color       = color
	sb.corner_radius_top_left     = 14
	sb.corner_radius_top_right    = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left  = 14
	return sb


func _has_available_upgrade(category: String) -> bool:
	if not _upgrade_system: return false
	for entry in _upgrade_system.get_upgrades_by_category(category):
		if _upgrade_system.get_status(entry["id"], _current_level) == "available":
			return true
	return false


func _get_icon(id: String, status: String) -> String:
	if status == "done":   return "✅"
	if status == "locked": return "🔒"
	var icons := {
		"KIT": "🔥", "CNT": "🪑", "CHF": "👨‍🍳", "IDL": "🌙"
	}
	for prefix in icons:
		if id.begins_with(prefix): return icons[prefix]
	return "⬆️"


func _get_effect_text(id: String) -> String:
	var effects := {
		"KIT_01": "Pişirme süresi −%15",
		"KIT_02": "Pişirme süresi −%15 daha",
		"KIT_03": "Paralel 2 sipariş pişir",
		"KIT_04": "Bahşiş çarpanı +%8",
		"KIT_05": "Tüm item fiyatları +%15",
		"CNT_01": "max_stools: 2→3",
		"CNT_02": "max_stools: 3→4 (Büfe max)",
		"CNT_03": "max_queue: 3→5 kişi",
		"CNT_04": "max_queue: 5→7 kişi",
		"CHF_01": "Hız +%10 · chef_quality: 1→2",
		"CHF_02": "Hız +%10 · chef_quality: 2→3",
		"CHF_03": "Hız +%10 · chef_quality: 3→4",
		"CHF_04": "chef_quality: 4→6 · Aceleci önceliği",
		"CHF_05": "Büfe items −%20 süre · quality→8",
		"IDL_01": "max_offline_hours: 4→6",
		"IDL_02": "max_offline_hours: 6→8 · verim +%4",
		"IDL_03": "offline_efficiency +%5",
		"IDL_04": "max_offline_hours: 8→10",
		"IDL_05": "max_offline_hours: 10→12 · verim +%3",
		"IDL_06": "offline_efficiency +%5 (max %45)",
	}
	return effects.get(id, "")


# ── ANIMATION ─────────────────────────────────────────────────────────────────
func _play_intro() -> void:
	if not sheet_container: return
	sheet_container.position.y = 300.0
	modulate.a = 0.0
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(sheet_container, "position:y", 0.0, 0.28)
	t.parallel().tween_property(self, "modulate:a", 1.0, 0.2)
