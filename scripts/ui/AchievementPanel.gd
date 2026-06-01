## AchievementPanel.gd
## Başarım listesi — GDD §11

extends Control

@onready var list_container : VBoxContainer = $ScrollContainer/ListContainer
@onready var points_label   : Label         = $Header/PointsLabel

const ACHIEVEMENT_DEFS := {
	"ACH_01": {"name":"İlk Sipariş",    "desc":"1 sipariş tamamla",                 "reward":"100₺ + rozet",      "hidden":false, "icon":"🍽️"},
	"ACH_02": {"name":"İlk Yükseltme",  "desc":"İlk upgrade'i satın al",            "reward":"200₺ + 2💎",        "hidden":false, "icon":"⬆️"},
	"ACH_03": {"name":"Hızlı Aşçı",     "desc":"5 siparişi 3 dakikada servis et",   "reward":"300₺",              "hidden":false, "icon":"⚡", "max":5},
	"ACH_04": {"name":"Sıfır İptal",    "desc":"20 siparişi iptalsiz tamamla",      "reward":"500₺ + dekor",      "hidden":false, "icon":"🎯", "max":20},
	"ACH_05": {"name":"İlk Uyku",       "desc":"2 saat offline bekle",              "reward":"1💎 + offline+%5", "hidden":false, "icon":"🌙"},
	"ACH_06": {"name":"Çay Ustası",     "desc":"50 çay servis et",                  "reward":"300₺ + çay−%10",   "hidden":false, "icon":"🫖", "max":50},
	"ACH_07": {"name":"Tam Dolu",       "desc":"Tüm tabure + sıra aynı anda dolu", "reward":"500₺",              "hidden":false, "icon":"💯"},
	"ACH_08": {"name":"Menü Tamamlandı","desc":"4 menü itemını aç",                 "reward":"1.000₺ + 5💎",     "hidden":false, "icon":"📋"},
	"ACH_09": {"name":"Büfe Emektarı",  "desc":"500 sipariş tamamla",               "reward":"2.000₺ + unvan",   "hidden":false, "icon":"🏅", "max":500},
	"ACH_10": {"name":"Gece Kuşu",      "desc":"???",                               "reward":"Gizli kostüm",     "hidden":true,  "icon":"🌙"},
}

var _unlocked  : Dictionary = {}   ## achievement_id → bool
var _progress  : Dictionary = {}   ## achievement_id → int (ilerleme)
var _total_pts : int        = 0

func _ready() -> void:
	EventBus.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_visibility_changed() -> void:
	if visible:
		_build_list()

func _on_achievement_unlocked(ach_id: String) -> void:
	_unlocked[ach_id] = true
	_total_pts += 100
	if points_label:
		points_label.text = "🏆 %d puan" % _total_pts
	if visible:
		_build_list()

func update_progress(ach_id: String, value: int) -> void:
	_progress[ach_id] = value
	var def : Dictionary = ACHIEVEMENT_DEFS.get(ach_id, {})
	if value >= def.get("max", 1) and not _unlocked.get(ach_id, false):
		EventBus.achievement_unlocked.emit(ach_id)

func _build_list() -> void:
	if not list_container: return
	for child in list_container.get_children():
		child.queue_free()

	for ach_id in ACHIEVEMENT_DEFS:
		var def     : Dictionary = ACHIEVEMENT_DEFS[ach_id]
		var done    : bool       = _unlocked.get(ach_id, false)
		var prog    : int        = _progress.get(ach_id, 0)
		var hidden  : bool       = def.get("hidden", false)
		list_container.add_child(_make_card(ach_id, def, done, prog, hidden))


func _make_card(ach_id: String, def: Dictionary, done: bool, prog: int, hidden: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)

	## İkon
	var icon_lbl := Label.new()
	icon_lbl.text = def.get("icon", "🏆") if (done or not hidden) else "❓"
	icon_lbl.add_theme_font_size_override("font_size", 44)
	hbox.add_child(icon_lbl)

	## İçerik
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl := Label.new()
	name_lbl.text = (def.get("name", ach_id) + " · " + ach_id) if not hidden else "Gizli Başarım"
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", Constants.PLUM if hidden else Constants.INK)

	var desc_lbl := Label.new()
	desc_lbl.text = def.get("desc", "") if (not hidden or done) else "???"
	desc_lbl.add_theme_font_size_override("font_size", 22)
	desc_lbl.add_theme_color_override("font_color", Constants.INK_SOFT)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD

	var footer := HBoxContainer.new()

	## Progress bar
	if def.has("max") and not done:
		var prog_bar := ProgressBar.new()
		prog_bar.max_value = def["max"]
		prog_bar.value     = prog
		prog_bar.custom_minimum_size = Vector2(200, 12)
		prog_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		footer.add_child(prog_bar)

		var prog_lbl := Label.new()
		prog_lbl.text = "%d/%d" % [prog, def["max"]]
		prog_lbl.add_theme_font_size_override("font_size", 22)
		prog_lbl.add_theme_color_override("font_color", Constants.SKY_DEEP)
		footer.add_child(prog_lbl)

	## Ödül
	var rew_lbl := Label.new()
	rew_lbl.text = "🏆 " + def.get("reward", "")
	rew_lbl.add_theme_font_size_override("font_size", 22)
	rew_lbl.add_theme_color_override("font_color", Constants.BUTTER_DEEP)
	rew_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END

	## Durum
	var status_lbl := Label.new()
	if done:
		status_lbl.text = "✅ TAMAMLANDI"
		status_lbl.add_theme_color_override("font_color", Constants.MINT_DEEP)
	elif hidden:
		status_lbl.text = "🔮 GİZLİ"
		status_lbl.add_theme_color_override("font_color", Constants.LAVENDER)
	else:
		status_lbl.text = "⏳ DEVAM EDİYOR"
		status_lbl.add_theme_color_override("font_color", Constants.SKY_DEEP)
	status_lbl.add_theme_font_size_override("font_size", 20)

	footer.add_child(rew_lbl)

	vbox.add_child(name_lbl)
	vbox.add_child(desc_lbl)
	vbox.add_child(footer)
	vbox.add_child(status_lbl)

	hbox.add_child(vbox)
	card.add_child(hbox)

	if done:
		card.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif hidden:
		card.modulate = Color(0.8, 0.8, 0.9, 0.7)
	else:
		card.modulate = Color(1.0, 1.0, 1.0, 0.85)

	return card
