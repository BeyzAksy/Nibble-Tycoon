## SaveSystem.gd
## JSON tabanlı kayıt/yükleme sistemi. GDD §10.2

extends Node

const SAVE_PATH := "user://lezzet_save.json"

# ── SAVE ──────────────────────────────────────────────────────────────────────
func save(data: Dictionary) -> void:
	var json_str := JSON.stringify(data, "\t")
	var file     := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
	else:
		push_error("SaveSystem: Dosya yazılamadı: %s" % SAVE_PATH)


# ── LOAD ──────────────────────────────────────────────────────────────────────
func load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveSystem: Dosya okunamadı: %s" % SAVE_PATH)
		return {}

	var content  := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) == OK and json.get_data() is Dictionary:
		return json.get_data() as Dictionary

	push_error("SaveSystem: JSON ayrıştırma hatası")
	return {}


# ── RESET ─────────────────────────────────────────────────────────────────────
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
