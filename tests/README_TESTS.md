# Test Kurulum Kılavuzu

## GUT Kurulumu (Godot Unit Test)

1. Godot editöründe → AssetLib → "GUT" ara → indir
2. Veya: https://github.com/bitwes/Gut → zip indir → addons/ klasörüne koy
3. Project → Project Settings → Plugins → GUT → Enable

## Testleri Çalıştır

### Editörden:
- GUT panelini aç (sol altta GUT sekmesi)
- "Run All" butonuna tıkla

### Komut satırından:
```bash
godot --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/ \
  -gprefix=test_ \
  -gsuffix=.gd \
  -gexit
```

## Dosya Yapısı
```
tests/
  unit/
    test_constants.gd         ← Formula tests
    test_economy_system.gd    ← Coin/Gem earn/spend
    test_upgrade_system.gd    ← Purchase, lock, serialize
    test_order_manager.gd     ← Order state machine
    test_chef_system.gd       ← Cook speed, slot management
    test_offline_system.gd    ← Offline earnings calculation
    test_save_system.gd       ← Save/load JSON
  integration/
    test_bufe_loop.gd         ← Full order cycle (spawn→done)
```
