## SplashScreen.gd
## Açılış ekranı — logo float, yükleme barı animasyonu, sahne geçişi.
##
## Beklenen sahne node ağacı (SplashScreen.tscn):
##   SplashScreen (Control — fullscreen, CREAM gradient bg)
##   ├── DecoCircle1 (ColorRect — coral, opacity .07, 200x200, top-left)
##   ├── DecoCircle2 (ColorRect — mint,  opacity .09, 160x160, bottom-right)
##   ├── LogoLabel   (Control — 90x90 yuvarlak, 🍽️ emoji, loat animasyonu)
##   ├── TitleLabel  (Label — "Lezzet\nİmparatorluğu", Fredoka, FS_DISPLAY_XL)
##   ├── SubLabel    (Label — alt yazı, Nunito, FS_BODY, INK_SOFT)
##   ├── LoadBarBG   (PanelContainer — 158px genişlik, LINE rengi)
##   │   └── LoadBarFill (ColorRect — coral→coral_deep gradient, genişlik 0'dan başlar)
##   ├── LoadLabel   (Label — "Yükleniyor... %0", FS_CAPTION, INK_SOFT)
##   ├── VersionLabel (Label — "v1.0 · Büfe Aşaması", pill stili)
##   └── BottomLine  (ColorRect — 3px yükseklik, tam genişlik, coral gradient)
##
## Referans: docs/lezzet_prototype_v3.html — s0 (Splash ekranı)

extends Control

# ── NEXT SCENE — comment out if BufeScene not ready yet ──────────────────────
const NEXT_SCENE := "res://scenes/BufeScene.tscn"

## Logo float amplitude (px) — HTML: translateY(-5px) / 640px = 0.78% → 0.78% * 1920 = ~15px
const LOGO_FLOAT_AMP   := 15.0
## Yükleme barı doldurma oranı — splash süresinin kaçta kaçında biter
const BAR_FILL_RATIO   := 0.82
## Fallback: parent layout hazır değilse kullanılan genişlik (px)
const BAR_FALLBACK_W   := 500.0

# ── STATE ─────────────────────────────────────────────────────────────────────
var _bar_tween      : Tween
var _bar_fill_node  : ColorRect   ## LoadBarFill — dinamik bulunur
var _load_lbl_node  : Label       ## LoadLabel   — dinamik bulunur

# ── _ready ────────────────────────────────────────────────────────────────────
func _ready() -> void:
	## Node'ları güvenli bul (yol uyuşmazlığına karşı)
	_bar_fill_node = _find_node("LoadBarFill") as ColorRect
	_load_lbl_node = _find_node("LoadLabel")   as Label

	_play_fade_in()
	_animate_logo()
	_animate_bar()
	_animate_deco()

	## Zamanlayıcı — Constants.SPLASH_DURATION sonra sahne geçişi
	get_tree().create_timer(Constants.SPLASH_DURATION).timeout.connect(_go_next)


# ── FADE IN ───────────────────────────────────────────────────────────────────
func _play_fade_in() -> void:
	modulate = Color.TRANSPARENT
	var t := create_tween().set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate", Color.WHITE, 0.5)


# ── LOGO FLOAT ────────────────────────────────────────────────────────────────
func _animate_logo() -> void:
	## HTML prototype: lfloat animasyonu 3s ease-in-out infinite, -5px yukarı
	var logo := _find_node("LogoLabel") as Control
	if not logo:
		return
	var base_y := logo.position.y
	var t := create_tween().set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(logo, "position:y", base_y - LOGO_FLOAT_AMP, 1.5)
	t.tween_property(logo, "position:y", base_y,                   1.5)


# ── LOADING BAR ───────────────────────────────────────────────────────────────
func _animate_bar() -> void:
	if not _bar_fill_node:
		return

	## Barın tam genişliğini al (parent'ın genişliği)
	var parent := _bar_fill_node.get_parent()
	if not parent:
		return

	## İlk kare tamamlanınca parent'ın layout genişliği hazır olur
	await get_tree().process_frame
	var full_w : float = parent.size.x
	if full_w <= 0.0:
		full_w = BAR_FALLBACK_W

	## Başlangıç genişliği 0
	_bar_fill_node.custom_minimum_size.x = 0.0
	_bar_fill_node.size.x = 0.0

	var fill_duration : float = Constants.SPLASH_DURATION * BAR_FILL_RATIO

	## Lambda'yı önceden tanımla — linter virgül sorununu önler
	var on_bar_progress := func(v: float) -> void:
		if is_instance_valid(_bar_fill_node):
			_bar_fill_node.size.x = v
		if is_instance_valid(_load_lbl_node):
			_load_lbl_node.text = "Yükleniyor... %d%%" % int(v / full_w * 100.0)

	var on_bar_done := func() -> void:
		if is_instance_valid(_load_lbl_node):
			_load_lbl_node.text = "Hazır! 🍽️"

	_bar_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_bar_tween.tween_method(on_bar_progress, 0.0, full_w, fill_duration)
	_bar_tween.tween_callback(on_bar_done)


# ── DECORATION ────────────────────────────────────────────────────────────────
func _animate_deco() -> void:
	## HTML prototype'ta 2 daire var: DecoCircle1 (coral, top-left) ve DecoCircle2 (mint, bottom-right)
	## Yavaş pulse animasyonu — scale 1.0 → 1.06 → 1.0, rastgele hız
	for circle_name in ["DecoCircle1", "DecoCircle2"]:
		var node := _find_node(circle_name) as Control
		if not node:
			continue
		var speed := randf_range(2.5, 4.0)
		var t := create_tween().set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		t.tween_property(node, "scale", Vector2(1.06, 1.06), speed)
		t.tween_property(node, "scale", Vector2(1.0,  1.0 ), speed)


# ── SCENE TRANSITION ─────────────────────────────────────────────────────────
func _go_next() -> void:
	## Tween'leri durdur
	if _bar_tween:
		_bar_tween.kill()

	## Fade-out — Constants.SPLASH_FADE_DURATION
	var t := create_tween().set_ease(Tween.EASE_IN)
	t.tween_property(self, "modulate", Color.TRANSPARENT, Constants.SPLASH_FADE_DURATION)
	await t.finished

	## Sahne geçişi
	if ResourceLoader.exists(NEXT_SCENE):
		get_tree().change_scene_to_file(NEXT_SCENE)
	else:
		## Hedef sahne hazır değil — splash'ı yeniden başlat (dev loop)
		push_warning("SplashScreen: '%s' bulunamadı — yeniden başlatılıyor." % NEXT_SCENE)
		get_tree().reload_current_scene()


# ── DEV: skip with SPACE ──────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_go_next()


# ── HELPER: find node by name in tree ────────────────────────────────────────
func _find_node(node_name: String) -> Node:
	## Önce doğrudan çocuklara bak, sonra tüm ağacı tara
	var result := find_child(node_name, true, false)
	return result
