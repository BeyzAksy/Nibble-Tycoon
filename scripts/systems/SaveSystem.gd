## SaveSystem.gd
## JSON tabanlı kayıt/yükleme sistemi. GDD §10.2
##
## Versiyonlama:
##   Version field olmayan eski save'lar v0 kabul edilir.
##   Save version > Constants.CURRENT_SAVE_VERSION → push_error + boş dict.

extends Node

const SAVE_PATH := "user://lezzet_save.json"

# ── SAVE ──────────────────────────────────────────────────────────────────────
## Save verisini JSON olarak diske yazar.
##
## Args:
##   data: Kaydedilecek veri sözlüğü. "version" field içermeli.
func save(data: Dictionary) -> void:
	var json_str := JSON.stringify(data, "\t")
	var file     := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
	else:
		push_error("SaveSystem: Dosya yazılamadı: %s" % SAVE_PATH)


# ── LOAD ──────────────────────────────────────────────────────────────────────
## Diskten save verisini yükler ve gerekirse migration uygular.
##
## Returns:
##   Dictionary — yüklenmiş ve migrate edilmiş veri; dosya yoksa veya bozuksa {}.
func load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveSystem: Dosya okunamadı: %s" % SAVE_PATH)
		return {}

	var content := file.get_as_text()
	file.close()

	var parsed : Variant = JSON.parse_string(content)
	if parsed is Dictionary:
		return migrate(parsed as Dictionary)

	push_error("SaveSystem: JSON ayrıştırma hatası")
	return {}


# ── MIGRATION ─────────────────────────────────────────────────────────────────
## Save verisini CURRENT_SAVE_VERSION'a yükseltir.
## Version field olmayan save'ler v0 kabul edilir.
## Version > current ise bozuk save sayılır: push_error + {} döner.
##
## Args:
##   data: Ham save sözlüğü (load_data veya test tarafından verilir).
##
## Returns:
##   Dictionary — migrate edilmiş veri, ya da bozuk save durumunda {}.
func migrate(data: Dictionary) -> Dictionary:
	var version : int = data.get("version", 0)

	if version > Constants.CURRENT_SAVE_VERSION:
		push_warning(
			"SaveSystem: Save version %d > current %d — fresh save ile devam" \
			% [version, Constants.CURRENT_SAVE_VERSION]
		)
		return {}

	if version < 1:
		_migrate_v0_to_v1(data)

	if version < 2:
		_migrate_v1_to_v2(data)

	return data


## v0 → v1: permanent_bonuses field eklenir.
## Zaten varsa dokunulmaz (idempotent).
func _migrate_v0_to_v1(data: Dictionary) -> void:
	if not data.has("permanent_bonuses"):
		data["permanent_bonuses"] = {}
	data["version"] = 1


## v1 → v2: achievements field eklenir (AchievementSystem).
## Zaten varsa dokunulmaz (idempotent).
func _migrate_v1_to_v2(data: Dictionary) -> void:
	if not data.has("achievements"):
		data["achievements"] = {}
	data["version"] = 2


# ── RESET ─────────────────────────────────────────────────────────────────────
## Save dosyasını diskten siler.
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
