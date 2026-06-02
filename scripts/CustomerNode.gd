## CustomerNode.gd
## Her müşterinin görsel ve sabır mantığı. GDD §2
##
## Sahne yapısı (CustomerNode.tscn):
##   CustomerNode (Node2D)
##   ├── Sprite (AnimatedSprite2D)
##   ├── OrderBubble (CanvasGroup veya Control)
##   │   ├── BubbleBG (NinePatchRect)
##   │   ├── StatusIcon (Label)       ← ⏳ 🔥 ✅
##   │   └── TimerLabel (Label)       ← "12s"
##   ├── PatienceBarContainer (Control)
##   │   ├── QueueBar (TextureProgressBar)
##   │   └── FoodBar (TextureProgressBar)
##   ├── EmotionLabel (Label)         ← 😊 😐 😠
##   └── ShakeTween (internal)

extends Node2D

# ── SIGNALS ───────────────────────────────────────────────────────────────────
signal patience_timeout(customer_id: int, timer_type: String)

# ── STATE ─────────────────────────────────────────────────────────────────────
var customer_id    : int    = -1
var customer_type  : String = "regular"
var current_order_id: int  = -1

var _queue_patience : float = 1.0   ## 0.0 → 1.0
var _food_patience  : float = 1.0
var _queue_timer    : float = 0.0
var _food_timer     : float = 0.0
var _queue_max      : float = 0.0
var _food_max       : float = 0.0

var _is_seated      : bool  = false
var _is_eating      : bool  = false

var _order_manager  : Node  = null
var _customer_system: Node  = null

## Yürüme yönü — walk_se / walk_sw / walk_ne / walk_nw
## Hareket sistemi eklenince set_facing() çağrılır, animasyon otomatik değişir.
var facing_dir      : String = "walk_se"

## Shake animation state
var _shake_tween    : Tween = null
var _base_position  : Vector2

# ── NODE REFERENCES ───────────────────────────────────────────────────────────
@onready var sprite          : AnimatedSprite2D = $Sprite
@onready var status_icon     : Label            = $OrderBubble/BubbleBG/HBox/StatusIcon
@onready var timer_label     : Label            = $OrderBubble/BubbleBG/HBox/TimerLabel
@onready var queue_bar       : TextureProgressBar = $PatienceBarContainer/QueueBar
@onready var food_bar        : TextureProgressBar = $PatienceBarContainer/FoodBar
@onready var emotion_label   : Label            = $EmotionLabel
@onready var order_bubble    : Control          = $OrderBubble

# ── SETUP ─────────────────────────────────────────────────────────────────────
func setup(
	p_id             : int,
	p_type           : String,
	p_order_manager  : Node,
	p_customer_system: Node
) -> void:
	customer_id     = p_id
	customer_type   = p_type
	_order_manager  = p_order_manager
	_customer_system = p_customer_system
	_base_position  = position

	## CUSTOMER_TYPES dict'inden sabır sürelerini oku
	var def : Dictionary = Constants.CUSTOMER_TYPES.get(
			customer_type, Constants.CUSTOMER_TYPES["regular"])
	_queue_max = def["patience_queue"]
	_food_max  = def["patience_food"]

	## Sprite animasyonunu başlat
	_update_sprite()
	_update_bubble(OrderManager.OrderState.QUEUED)
	_update_patience_bars()

	## Sıra sabrı başlasın
	_queue_patience = 1.0
	_queue_timer    = 0.0


# ── PROCESS ───────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _is_eating:
		return

	if not _is_seated:
		## Queue patience countdown
		_queue_timer += delta
		_queue_patience = 1.0 - (_queue_timer / _queue_max)
		_queue_patience = clampf(_queue_patience, 0.0, 1.0)

		_update_patience_bars()
		_update_emotion()

		if _order_manager:
			_order_manager.update_queue_patience(current_order_id, _queue_patience)

		if _queue_patience <= 0.0:
			patience_timeout.emit(customer_id, "queue")
			set_process(false)
	else:
		## Food patience countdown (while SEATED and COOKING)
		_food_timer += delta
		_food_patience = 1.0 - (_food_timer / _food_max)
		_food_patience = clampf(_food_patience, 0.0, 1.0)

		_update_patience_bars()
		_update_emotion()

		if _order_manager:
			_order_manager.update_food_patience(current_order_id, _food_patience)

		## Shake animation at critical patience threshold
		if _food_patience < Constants.PATIENCE_NEUTRAL_THRESHOLD:
			_start_shake()

		if _food_patience <= 0.0:
			patience_timeout.emit(customer_id, "food")
			set_process(false)


# ── STATE TRANSITIONS ─────────────────────────────────────────────────────────
func on_seated(order_id: int) -> void:
	current_order_id = order_id
	_is_seated = true
	_food_timer = 0.0
	_stop_shake()
	_update_bubble(OrderManager.OrderState.SEATED)
	_update_sprite()


func on_cooking_started(cook_time: float) -> void:
	_update_bubble(OrderManager.OrderState.COOKING)
	## Bubble'da countdown timer göster
	_start_bubble_countdown(cook_time)


func on_food_ready() -> void:
	_update_bubble(OrderManager.OrderState.READY)
	_stop_shake()


func on_eating() -> void:
	_is_eating = true
	_update_bubble(OrderManager.OrderState.EATING)
	_stop_shake()
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("eating"):
		sprite.play("eating")


func play_exit_animation(reason: String) -> void:
	set_process(false)
	_stop_shake()
	match reason:
		"angry":
			## Fast exit + red flash
			var t := create_tween().set_ease(Tween.EASE_IN)
			t.tween_property(self, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.1)
			t.tween_property(self, "position:x", position.x - 200, 0.4)
			t.tween_property(self, "modulate:a", 0.0, 0.3)
		"queue":
			## Slow walk back
			var t := create_tween().set_ease(Tween.EASE_IN)
			t.tween_property(self, "position:x", position.x - 150, 0.6)
			t.tween_property(self, "modulate:a", 0.0, 0.4)
		"done":
			## Happy exit — scale up → fade
			var t := create_tween()
			t.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15)
			t.tween_property(self, "modulate:a", 0.0, 0.4)


# ── VISUAL UPDATE ─────────────────────────────────────────────────────────────
func _update_bubble(state: OrderManager.OrderState) -> void:
	if not status_icon or not order_bubble:
		return

	order_bubble.visible = true
	match state:
		OrderManager.OrderState.QUEUED:
			status_icon.text = "⏳"
			timer_label.text = "Sırada"
			order_bubble.modulate = Color(Constants.SKY_DEEP, 1.0)
		OrderManager.OrderState.SEATED:
			status_icon.text = "🪑"
			timer_label.text = "Bekliyor"
			order_bubble.modulate = Color(Constants.LAVENDER, 1.0)
		OrderManager.OrderState.COOKING:
			status_icon.text = "🔥"
			order_bubble.modulate = Color(Constants.CORAL_DEEP, 1.0)
		OrderManager.OrderState.READY:
			status_icon.text = "✅"
			timer_label.text = "Hazır!"
			order_bubble.modulate = Color(Constants.MINT_DEEP, 1.0)
		OrderManager.OrderState.EATING:
			status_icon.text = "🍽️"
			timer_label.text = "Yiyor"
			order_bubble.modulate = Color(Constants.BUTTER_DEEP, 1.0)
		_:
			order_bubble.visible = false


func _start_bubble_countdown(cook_time: float) -> void:
	## Update timer_label every 0.5s during cooking
	var remaining := cook_time
	while remaining > 0.0 and _is_seated:
		timer_label.text = "%ds" % int(remaining)
		await get_tree().create_timer(0.5).timeout
		remaining -= 0.5


func _update_patience_bars() -> void:
	if queue_bar:
		queue_bar.value = _queue_patience * 100.0
		queue_bar.visible = not _is_seated
		queue_bar.modulate = Constants.get_patience_color(_queue_patience)

	if food_bar:
		food_bar.value = _food_patience * 100.0
		food_bar.visible = _is_seated and not _is_eating
		food_bar.modulate = Constants.get_patience_color(_food_patience)


func _update_emotion() -> void:
	if not emotion_label:
		return

	var ratio := _food_patience if _is_seated else _queue_patience
	if ratio >= Constants.PATIENCE_HAPPY_THRESHOLD:
		emotion_label.text = "😊"
	elif ratio >= Constants.PATIENCE_NEUTRAL_THRESHOLD:
		emotion_label.text = "😐"
	else:
		emotion_label.text = "😠"

	## Pop animation on state change
	var t := create_tween().set_ease(Tween.EASE_OUT)
	t.tween_property(emotion_label, "scale", Vector2(1.3, 1.3), 0.04)
	t.tween_property(emotion_label, "scale", Vector2(1.0, 1.0), 0.04)


## Yönü günceller ve animasyonu oynatır.
## Hareket sistemi bu metodu çağırır — başka yerden çağrılmaz.
func set_facing(dir: String) -> void:
	facing_dir = dir
	_update_sprite()


func _update_sprite() -> void:
	if not sprite:
		return
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(facing_dir):
		sprite.play(facing_dir)


# ── SHAKE ANIMATION ───────────────────────────────────────────────────────────
func _start_shake() -> void:
	if _shake_tween and _shake_tween.is_running():
		return

	var amp : float = (
		Constants.ANIM_PATIENCE_SHAKE_AMP_CRIT
		if _food_patience < 0.10
		else Constants.ANIM_PATIENCE_SHAKE_AMP_LOW
	)

	_shake_tween = create_tween().set_loops()
	_shake_tween.tween_property(
		self, "position:x",
		_base_position.x + amp, Constants.ANIM_SHAKE_FREQ / 2.0
	)
	_shake_tween.tween_property(
		self, "position:x",
		_base_position.x - amp, Constants.ANIM_SHAKE_FREQ / 2.0
	)


func _stop_shake() -> void:
	if _shake_tween:
		_shake_tween.kill()
		_shake_tween = null
	position.x = _base_position.x
