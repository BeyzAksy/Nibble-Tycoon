## CoinFloat.gd
## Sipariş tamamlandığında tezgahtan HUD'a uçan coin efekti.
## GDD §6 — Coin float animasyonu
##
## Kullanım:
##   var cf := CoinFloat.new()
##   cf.play(parent, world_pos, amount, is_tip)

extends Label

func play(
	parent    : Node,
	world_pos : Vector2,
	amount    : float,
	is_tip    : bool = false
) -> void:
	text = "+%.0f" % amount
	add_theme_font_size_override("font_size", 36)
	add_theme_color_override(
		"font_color",
		Constants.MINT_DEEP if is_tip else Constants.BUTTER_DEEP
	)

	parent.add_child(self)
	global_position = world_pos
	modulate = Color.WHITE

	var end_y : float = world_pos.y - 100.0
	if is_tip:
		end_y -= 20.0

	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "global_position:y", end_y, Constants.ANIM_COIN_FLOAT)
	t.parallel().tween_property(
		self, "global_position:x",
		world_pos.x + (12.0 if is_tip else -12.0),
		Constants.ANIM_COIN_FLOAT
	)
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(queue_free)
