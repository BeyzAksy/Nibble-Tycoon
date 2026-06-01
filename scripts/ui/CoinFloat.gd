## CoinFloat.gd
## Sipariş tamamlandığında tezgahtan HUD'a uçan coin efekti.
## GDD §6 — Coin float animasyonu

extends Label

## Quadratic Bezier ile yay çizer: başlangıç → kontrol noktası → hedef
static func spawn(
	parent       : Node,
	world_pos    : Vector2,
	amount       : float,
	is_tip       : bool = false
) -> void:
	var label := CoinFloat.new()

	## Metin — GDD: Fredoka 18sp, Butter-deep
	label.text = "+%.0f %s" % [amount, "☕" if is_tip else "🪙"]
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override(
		"font_color",
		Constants.MINT_DEEP if is_tip else Constants.BUTTER_DEEP
	)

	parent.add_child(label)
	label.global_position = world_pos
	label.modulate = Color.WHITE

	## Animasyon: 600ms ease-in-out, yay yolu
	## Hedef: HUD coin sayacının pozisyonu (sabit üst-sol bölge)
	var target : Vector2 = Vector2(120, 60)   ## Düzeltilecek: HUD'dan alınacak
	var ctrl   : Vector2 = Vector2(
		(world_pos.x + target.x) / 2.0,
		world_pos.y - 120
	)

	var t := label.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	## Bezier interpolasyonu manuel — position'ı adım adım güncelle
	t.tween_method(
		func(r: float):
			var p := _bezier(world_pos, ctrl, target, r)
			label.global_position = p
		, 0.0, 1.0, Constants.ANIM_COIN_FLOAT
	)

	## Bahşiş biraz gecikmeli çıkar
	if is_tip:
		await label.get_tree().create_timer(0.1).timeout

	## Metin yukarı süzülüp solar
	t.tween_property(label, "modulate:a", 0.0, 0.3)
	t.tween_callback(label.queue_free)


static func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2
