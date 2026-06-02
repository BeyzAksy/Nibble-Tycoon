## MenuPanel.gd
## Menü ekranı — mevcut itemlar, kilit/açık durumları, fiyatlar.
## GDD §3

extends Control

var _current_level  : int  = 1
var _upgrade_system : Node = null
var _economy_system : Node = null

@onready var list_container : VBoxContainer = $ScrollContainer/ListContainer

func setup(upgrade_sys: Node, economy_sys: Node, level: int) -> void:
	_upgrade_system = upgrade_sys
	_economy_system = economy_sys
	_current_level  = level

func _on_visibility_changed() -> void:
	if visible:
		_build_list()

func _build_list() -> void:
	if not list_container: return
	for child in list_container.get_children():
		child.queue_free()

	## Başlık
	var sec1 := _make_section_label("🔓 Açık Ürünler")
	list_container.add_child(sec1)

	for item_id in Constants.MENU_ITEMS:
		var item : Dictionary = Constants.MENU_ITEMS[item_id]
		var unlocked : bool = _current_level >= item.get("unlock_level", 1)

		if item_id == "daily_special":
			continue  ## Ayrı bölümde

		if unlocked:
			list_container.add_child(_make_item_card(item_id, item, true))

	## Kilitli
	var sec2 := _make_section_label("🔒 Kilitli Ürünler")
	list_container.add_child(sec2)

	for item_id in Constants.MENU_ITEMS:
		var item : Dictionary = Constants.MENU_ITEMS[item_id]
		var unlocked : bool = _current_level >= item.get("unlock_level", 1)
		if not unlocked:
			list_container.add_child(_make_item_card(item_id, item, false))

	## Günün Özelliği
	var sec3 := _make_section_label("⭐ Özel")
	list_container.add_child(sec3)
	list_container.add_child(_make_daily_card())


func _make_section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Constants.INK_SOFT)
	return lbl


func _make_item_card(item_id: String, item: Dictionary, unlocked: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)

	## Icon mapping (item_id → emoji)
	var icons := {"tea":"🫖","pastry":"🥐","sandwich":"🍞","sausage":"🌭"}
	var icon_lbl := Label.new()
	icon_lbl.text = icons.get(item_id, "🍳")
	icon_lbl.add_theme_font_size_override("font_size", 48)
	hbox.add_child(icon_lbl)

	## Info
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl := Label.new()
	name_lbl.text = item.get("name", item_id)
	name_lbl.add_theme_font_size_override("font_size", 30)
	name_lbl.add_theme_color_override("font_color", Constants.INK if unlocked else Constants.INK_SOFT)

	var tags_box := HBoxContainer.new()
	tags_box.add_theme_constant_override("separation", 8)

	var cook_lbl := Label.new()
	cook_lbl.text = "⏱ %ds" % item.get("cook_time", 0)
	cook_lbl.add_theme_font_size_override("font_size", 22)
	cook_lbl.add_theme_color_override("font_color", Constants.BUTTER_DEEP)

	var lv_lbl := Label.new()
	lv_lbl.text = "Lv%d" % item.get("unlock_level", 1)
	lv_lbl.add_theme_font_size_override("font_size", 22)
	lv_lbl.add_theme_color_override("font_color", Constants.MINT_DEEP if unlocked else Constants.CORAL)

	tags_box.add_child(cook_lbl)
	tags_box.add_child(lv_lbl)

	vbox.add_child(name_lbl)
	vbox.add_child(tags_box)
	hbox.add_child(vbox)

	## Price
	var price_lbl := Label.new()
	price_lbl.text = "%d ₺" % item.get("price", 0)
	price_lbl.add_theme_font_size_override("font_size", 36)
	var color := Constants.BUTTER_DEEP if unlocked else Constants.INK_SOFT
	price_lbl.add_theme_color_override("font_color", color)
	hbox.add_child(price_lbl)

	## Unlock button (if locked)
	if not unlocked:
		var cost : int = item.get("unlock_cost", 0)
		if cost > 0:
			var btn := Button.new()
			btn.text = "Aç · %d 🪙" % cost
			btn.pressed.connect(func(): _try_unlock(item_id, cost))
			hbox.add_child(btn)

	card.add_child(hbox)
	if not unlocked:
		card.modulate = Color(1, 1, 1, 0.55)

	return card


func _make_daily_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 80)

	var lbl := Label.new()
	lbl.text = "⭐ Günün Özelliği — Lv5'te açılır · Günlük x1.3 fiyat · Bildirim gönderir"
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Constants.LAVENDER)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	card.add_child(lbl)
	card.modulate = Color(1, 1, 1, 0.55)
	return card


func _try_unlock(item_id: String, cost: int) -> void:
	if _economy_system and _economy_system.spend_coins(cost, "menu_unlock_" + item_id):
		EventBus.toast_requested.emit(
			"%s menüye eklendi! 🎉" % Constants.MENU_ITEMS[item_id]["name"],
			"success"
		)
		_build_list()
