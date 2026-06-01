## WelcomeModal.gd
## Offline reward "Hoş Geldin" ekranı. GDD §8, §10
##
## Sahne yapısı (WelcomeModal.tscn):
##   WelcomeModal (Control — fullscreen overlay)
##   ├── DimBG (ColorRect)
##   └── ModalPanel (PanelContainer)
##       ├── VBox
##       │   ├── ChefLabel (Label)          ← 🧑‍🍳 breathing
##       │   ├── TitleLabel
##       │   ├── SubLabel                   ← "6 saat 24 dakika çalıştı"
##       │   ├── AmountBox (PanelContainer)
##       │   │   ├── AmountLabel            ← count-up animasyonu
##       │   │   └── AmountSubLabel
##       │   ├── StorageWarnLabel           ← ⚠ sadece depo doluysa
##       │   ├── XPBar (TextureProgressBar)
##       │   ├── XPLabels (HBoxContainer)
##       │   ├── CollectBtn
##       │   └── WatchAdBtn

extends Control

# ── SIGNALS ───────────────────────────────────────────────────────────────────
signal collect_pressed()
signal watch_ad_pressed()

# ── NODE REFERENCES ───────────────────────────────────────────────────────────
@onready var chef_label       : Label             = $ModalPanel/VBox/ChefLabel
@onready var title_label      : Label             = $ModalPanel/VBox/TitleLabel
@onready var sub_label        : Label             = $ModalPanel/VBox/SubLabel
@onready var amount_label     : Label             = $ModalPanel/VBox/AmountBox/AmountLabel
@onready var amount_sub       : Label             = $ModalPanel/VBox/AmountBox/AmountSubLabel
@onready var storage_warn     : Label             = $ModalPanel/VBox/StorageWarnLabel
@onready var xp_bar           : TextureProgressBar= $ModalPanel/VBox/XPBar
@onready var xp_label_left    : Label             = $ModalPanel/VBox/XPLabels/LeftLabel
@onready var xp_label_right   : Label             = $ModalPanel/VBox/XPLabels/RightLabel
@onready var collect_btn      : Button            = $ModalPanel/VBox/CollectBtn
@onready var watch_ad_btn     : Button            = $ModalPanel/VBox/WatchAdBtn

var _base_earnings : float = 0.0

# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	if collect_btn:
		collect_btn.pressed.connect(_on_collect_pressed)
	if watch_ad_btn:
		watch_ad_btn.pressed.connect(_on_watch_ad_pressed)

	## Chef "breathing" animation loop
	if chef_label:
		var t := create_tween().set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		t.tween_property(chef_label, "scale", Vector2(1.04, 1.04), 1.2)
		t.tween_property(chef_label, "scale", Vector2(1.0,  1.0 ), 1.2)


# ── POPULATE UI ───────────────────────────────────────────────────────────────
func show_earnings(
	earnings      : float,
	elapsed_hours : float,
	storage_full  : bool,
	current_level : int
) -> void:
	_base_earnings = earnings

	## Duration text — "X saat Y dakika" formatı
	var hours   := int(elapsed_hours)
	var minutes := int((elapsed_hours - hours) * 60)
	if sub_label:
		sub_label.text = "%d saat %d dakika çalıştı · Lv%d" % [hours, minutes, current_level]

	## Storage warning
	if storage_warn:
		storage_warn.visible = storage_full
		storage_warn.text    = "⚠ Depo doldu, gelmeyi unuttun mu?"

	## Amount count-up animation — GDD §6: 1200ms ease-out
	if amount_label:
		amount_label.text = "+0 🪙"
		var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		t.tween_method(
			func(v: float): amount_label.text = "+%.0f 🪙" % v,
			0.0, earnings, 1.2
		)

	## 2× button text
	if watch_ad_btn:
		watch_ad_btn.text = "📺 2× İzle → +%.0f 🪙" % (earnings * 2)

	## XP bar — BufeScene tarafından doldurulur, şimdi placeholder
	if xp_bar:
		xp_bar.value = 62.0   ## Gerçek değer BufeScene._xp_ratio() * 100

	## Intro animation
	_play_intro()


func update_xp(ratio: float, level: int, total_xp: int, next_threshold: int) -> void:
	if xp_bar:
		xp_bar.value = ratio * 100.0
	if xp_label_left:
		xp_label_left.text = "Lv%d · %d sipariş" % [level, total_xp]
	if xp_label_right:
		xp_label_right.text = "Lv%d'e: %d" % [level + 1, next_threshold - total_xp]


# ── ANIMATION ─────────────────────────────────────────────────────────────────
func _play_intro() -> void:
	modulate.a = 0.0
	var t := create_tween().set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 1.0, 0.3)

	## Modal — slides in from bottom
	var modal := $ModalPanel
	if modal:
		modal.position.y = 200.0
		t.parallel().tween_property(modal, "position:y", 0.0, 0.35)


# ── BUTTON ACTIONS ────────────────────────────────────────────────────────────
func _on_collect_pressed() -> void:
	collect_pressed.emit()
	_play_outro()


func _on_watch_ad_pressed() -> void:
	watch_ad_pressed.emit()
	_play_outro()


func _play_outro() -> void:
	var t := create_tween().set_ease(Tween.EASE_IN)
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(func(): visible = false)
