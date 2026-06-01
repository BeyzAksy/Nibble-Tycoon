## StoveSlot.gd
## Tek ocak slotunun görsel yönetimi.
## Pişirme barı, alev animasyonu, item emoji, timer label.
##
## Scene structure (inside StoveSlotN node):
##   StoveSlot (Node2D)
##   ├── StoveSprite (Sprite2D)         ← ocak gövdesi
##   ├── FlameParticles (GPUParticles2D) ← alev efekti
##   ├── ItemLabel (Label)              ← pişen item emoji
##   ├── TimerLabel (Label)             ← "8s" overlay
##   ├── CookBar (TextureProgressBar)   ← pişirme ilerlemesi
##   └── ReadyLight (PointLight2D)      ← READY pulse glow

extends Node2D

# ── NODE REFERENCES ───────────────────────────────────────────────────────────
@onready var flame_particles : GPUParticles2D    = $FlameParticles
@onready var item_label      : Label             = $ItemLabel
@onready var timer_label     : Label             = $TimerLabel
@onready var cook_bar        : TextureProgressBar= $CookBar
@onready var ready_light     : PointLight2D      = $ReadyLight
@onready var stove_sprite    : Sprite2D          = $OcakSprite

# ── STATE ─────────────────────────────────────────────────────────────────────
var _cooking      : bool  = false
var _cook_time    : float = 0.0
var _elapsed      : float = 0.0
var _item_id      : String = ""
var _ready_tween  : Tween

# ── ITEM → EMOJI MAP ──────────────────────────────────────────────────────────
const ITEM_EMOJI := {
	"tea":     "🫖",
	"pastry":  "🥐",
	"sandwich":"🍞",
	"sausage": "🌭",
}

# ── LIFECYCLE ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_set_idle_state()


func _process(delta: float) -> void:
	if not _cooking:
		return

	_elapsed += delta
	var progress := clampf(_elapsed / _cook_time, 0.0, 1.0)

	## Progress bar güncelle
	if cook_bar:
		cook_bar.value = progress * 100.0

	## Timer label güncelle
	var remaining := maxf(_cook_time - _elapsed, 0.0)
	if timer_label:
		timer_label.text = "%ds" % int(remaining)

	if _elapsed >= _cook_time:
		_cooking = false
		## ChefSystem._finish_slot zaten OrderManager'ı bilgilendiriyor


# ── PUBLIC API ────────────────────────────────────────────────────────────────
func start_cooking(item_id: String, cook_time: float) -> void:
	_item_id   = item_id
	_cook_time = cook_time
	_elapsed   = 0.0
	_cooking   = true

	## Görsel güncelle
	if item_label:
		item_label.text    = ITEM_EMOJI.get(item_id, "🍳")
		item_label.visible = true

	if timer_label:
		timer_label.text    = "%ds" % int(cook_time)
		timer_label.visible = true

	if cook_bar:
		cook_bar.value   = 0.0
		cook_bar.visible = true

	## Alev aç
	if flame_particles:
		flame_particles.emitting = true

	## Ready glow kapat (önceki varsa)
	_stop_ready_glow()

	## Ocak rengi — aktif
	if stove_sprite:
		var t := create_tween().set_ease(Tween.EASE_OUT)
		t.tween_property(stove_sprite, "modulate", Color(1.3, 0.9, 0.7, 1.0), 0.2)


func finish_cooking() -> void:
	_cooking = false

	## Alev kapat
	if flame_particles:
		flame_particles.emitting = false

	## Item ve timer gizle
	if item_label:  item_label.visible  = false
	if timer_label: timer_label.visible = false
	if cook_bar:    cook_bar.visible    = false

	## Ready glow başlat — GDD §4: mint pulse, 0.8sn döngü
	_start_ready_glow()

	## Ocak rengini normale döndür
	if stove_sprite:
		var t := create_tween().set_ease(Tween.EASE_OUT)
		t.tween_property(stove_sprite, "modulate", Color.WHITE, 0.3)


func set_slot_enabled(enabled: bool) -> void:
	## KIT_03 upgrade sonrası Slot 2 aktif edilir
	visible = enabled
	if not enabled:
		_set_idle_state()


# ── PRIVATE HELPERS ───────────────────────────────────────────────────────────
func _set_idle_state() -> void:
	_cooking = false
	if flame_particles: flame_particles.emitting = false
	if item_label:      item_label.visible        = false
	if timer_label:     timer_label.visible        = false
	if cook_bar:        cook_bar.visible           = false
	if ready_light:     ready_light.enabled        = false


func _start_ready_glow() -> void:
	if not ready_light:
		return
	ready_light.enabled = true
	_ready_tween = create_tween().set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_ready_tween.tween_property(ready_light, "energy", 0.6, 0.4)
	_ready_tween.tween_property(ready_light, "energy", 0.0, 0.4)
	ready_light.color = Constants.MINT_DEEP


func _stop_ready_glow() -> void:
	if _ready_tween:
		_ready_tween.kill()
		_ready_tween = null
	if ready_light:
		ready_light.enabled = false
		ready_light.energy  = 0.0
