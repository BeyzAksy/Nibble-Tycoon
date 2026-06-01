---
paths:
  - "scripts/systems/UpgradeSystem.gd"
  - "autoload/Constants.gd"
---

# Extensibility Rules

## Yeni Upgrade: Sadece UPGRADE_DEFS'e Satır

```gdscript
"KIT_06": {
    "category":     "kitchen",
    "name":         "Upgrade Name",
    "cost":         50000,
    "unlock_level": 6,
    "requires":     "KIT_05",   ## opsiyonel
    "effect":       "speed",    ## mevcut effect tipi
},
```

Mevcut effect tipleri: `speed`, `slot`, `stool`, `queue`, `quality`, `quality_priority`, `mastery`, `offline_hours`, `offline_hours_eff`, `offline_eff`, `tip`, `price`

Yeni effect tipi → sadece `_apply_effect()` match'e ekle. Başka dosyaya dokunma.

## Yeni Menü Item: Sadece MENU_ITEMS'a Satır

```gdscript
"waffle": {
    "name": "Waffle", "price": 95, "cook_time": 20,
    "unlock_level": 6, "unlock_cost": 5000,
},
```

## Yeni Save Field: Versiyon++ + Migration

```gdscript
func deserialize(data: Dictionary) -> void:
    var version : int = data.get("version", 1)
    if version < 2:
        _migrate_v1_to_v2(data)
```

## Checklist: Yeni Özellik Eklemeden Önce

- [ ] GDD'de tanımlı mı?
- [ ] Data-driven eklenebilir mi?
- [ ] Yeni sinyal → EventBus.gd
- [ ] Yeni sabit → Constants.gd
- [ ] Save field → versiyon++ + migration
- [ ] Test yazıldı mı?
