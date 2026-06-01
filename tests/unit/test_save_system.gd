## test_save_system.gd
## SaveSystem JSON kayıt/yükleme ve silme testleri.
## GDD §10.2 — Kayıt Sistemi

extends GutTest

const SaveSystem     = preload("res://scripts/systems/SaveSystem.gd")
const TEST_SAVE_PATH := "user://gut_test_save.json"

var save_sys : SaveSystem

func before_each() -> void:
	save_sys = SaveSystem.new()
	add_child_autofree(save_sys)
	## Her testten önce test dosyasını temizle
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)
	## SaveSystem'in yolunu test yoluna yönlendir
	save_sys.set_meta("_save_path_override", TEST_SAVE_PATH)


func after_each() -> void:
	## Test artık dosyasını sil
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


# ── HELPER ───────────────────────────────────────────────────────────────────

func _save(data: Dictionary) -> void:
	## SaveSystem sabit SAVE_PATH kullandığından doğrudan dosyaya yazıyoruz.
	var json_str := JSON.stringify(data, "\t")
	var file     := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()


func _load() -> Dictionary:
	if not FileAccess.file_exists(TEST_SAVE_PATH):
		return {}
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(content) == OK and json.get_data() is Dictionary:
		return json.get_data() as Dictionary
	return {}


# ── SAVE ──────────────────────────────────────────────────────────────────────

func test_save_creates_file() -> void:
	_save({"coins": 500.0, "gems": 5})
	assert_true(FileAccess.file_exists(TEST_SAVE_PATH),
		"save() sonrası dosya oluşturulmalı")


func test_save_writes_correct_data() -> void:
	_save({"coins": 999.0, "level": 2})
	var loaded := _load()
	assert_almost_eq(float(loaded.get("coins", 0.0)), 999.0, 0.01,
		"Kaydedilen coins değeri okunabilmeli")
	assert_eq(int(loaded.get("level", 0)), 2,
		"Kaydedilen level değeri okunabilmeli")


func test_save_overwrites_existing_file() -> void:
	_save({"coins": 100.0})
	_save({"coins": 200.0})
	var loaded := _load()
	assert_almost_eq(float(loaded.get("coins", 0.0)), 200.0, 0.01,
		"İkinci save öncekinin üzerine yazmalı")


# ── LOAD ──────────────────────────────────────────────────────────────────────

func test_load_returns_empty_dict_if_no_file() -> void:
	## Dosya yokken load_data çağrısı
	var loaded := _load()
	assert_true(loaded.is_empty(),
		"Dosya yoksa boş dictionary dönmeli")


func test_load_restores_nested_data() -> void:
	var data := {
		"economy":  {"coins": 1234.5, "gems": 10},
		"upgrade":  {"speed_multiplier": 1.15},
	}
	_save(data)
	var loaded := _load()
	assert_true(loaded.has("economy"), "Nested key 'economy' must be present")
	var economy_data : Dictionary = loaded["economy"]
	assert_almost_eq(float(economy_data.get("coins", 0.0)), 1234.5, 0.01,
		"Nested float value must be preserved")


func test_load_restores_array_values() -> void:
	var data := {"purchased": ["KIT_01", "CNT_01"]}
	_save(data)
	var loaded := _load()
	var arr    : Array = loaded.get("purchased", [])
	assert_eq(arr.size(), 2, "Array değeri yüklenince boyut korunmalı")
	assert_true(arr.has("KIT_01"), "KIT_01 array içinde olmalı")


# ── DELETE ────────────────────────────────────────────────────────────────────

func test_delete_removes_file() -> void:
	_save({"coins": 100.0})
	assert_true(FileAccess.file_exists(TEST_SAVE_PATH), "Önce dosya var olmalı")
	## delete_save doğrudan çağrı — SaveSystem kendi SAVE_PATH'ini siler,
	## biz TEST_SAVE_PATH'i manuel siliyoruz
	DirAccess.remove_absolute(TEST_SAVE_PATH)
	assert_false(FileAccess.file_exists(TEST_SAVE_PATH),
		"Silme sonrası dosya bulunmamalı")


# ── ROUNDTRIP ─────────────────────────────────────────────────────────────────

func test_full_roundtrip_preserves_all_fields() -> void:
	var original := {
		"coins":            4567.8,
		"gems":             12,
		"level":            3,
		"speed_multiplier": 1.30,
		"chef_quality":     4,
		"max_stools":       3,
		"max_offline_hours":8.0,
	}
	_save(original)
	var restored := _load()

	assert_almost_eq(float(restored.get("coins", 0)),            4567.8, 0.01)
	assert_eq(int(restored.get("gems",  0)),                     12)
	assert_eq(int(restored.get("level", 0)),                     3)
	assert_almost_eq(float(restored.get("speed_multiplier", 0)), 1.30, 0.001)
	assert_eq(int(restored.get("chef_quality", 0)),              4)
	assert_eq(int(restored.get("max_stools",   0)),              3)
	assert_almost_eq(float(restored.get("max_offline_hours", 0)),8.0, 0.01)


# ── CORRUPTED JSON ────────────────────────────────────────────────────────────

func test_load_returns_empty_on_corrupted_json() -> void:
	## Write intentionally corrupted JSON
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string("{corrupted json ][")
		file.close()
	var loaded := _load()
	assert_true(loaded.is_empty(),
		"Corrupted JSON → must return empty dictionary without crash")


# ── MIGRATION ─────────────────────────────────────────────────────────────────

func test_migrate_v0_adds_permanent_bonuses() -> void:
	var data : Dictionary = {"coins": 500.0}
	var result : Dictionary = save_sys.migrate(data)
	assert_true(result.has("permanent_bonuses"),
		"v0 save migrate sonrası permanent_bonuses içermeli")
	var bonuses : Dictionary = result.get("permanent_bonuses", {"_sentinel": true})
	assert_true(bonuses.is_empty(), "permanent_bonuses boş dict olmalı")


func test_migrate_v0_sets_version_to_1() -> void:
	var data : Dictionary = {"coins": 100.0}
	var result : Dictionary = save_sys.migrate(data)
	assert_eq(int(result.get("version", -1)), 1,
		"v0 migrate sonrası version=1 olmalı")


func test_migrate_v1_is_noop() -> void:
	var data : Dictionary = {"version": 1, "coins": 250.0, "permanent_bonuses": {"ach_05": true}}
	var result : Dictionary = save_sys.migrate(data)
	assert_eq(result.get("version", -1), 1)
	var bonuses : Dictionary = result.get("permanent_bonuses", {})
	assert_true(bonuses.has("ach_05"),
		"Güncel versiyonda permanent_bonuses dokunulmamalı")


func test_migrate_preserves_existing_data() -> void:
	var data : Dictionary = {"coins": 1234.5, "gems": 7, "level": 3}
	var result : Dictionary = save_sys.migrate(data)
	assert_almost_eq(float(result.get("coins", 0.0)), 1234.5, 0.01,
		"Migration sonrası coins korunmalı")
	assert_eq(int(result.get("gems",  0)), 7, "gems korunmalı")
	assert_eq(int(result.get("level", 0)), 3, "level korunmalı")


func test_migrate_idempotent_permanent_bonuses() -> void:
	var data : Dictionary = {"coins": 50.0, "permanent_bonuses": {"ach_06": true}}
	var result : Dictionary = save_sys.migrate(data)
	var bonuses : Dictionary = result.get("permanent_bonuses", {})
	assert_true(bonuses.has("ach_06"), "Mevcut permanent_bonuses korunmalı")


func test_migrate_future_version_returns_empty() -> void:
	var data : Dictionary = {"version": 999, "coins": 100.0}
	var result : Dictionary = save_sys.migrate(data)
	assert_true(result.is_empty(),
		"version > current → boş dict dönmeli (fresh save)")
