# Visual & Sprite Kuralları

## Constants.SPRITES — Tek Kaynak

Tüm sprite/texture path'leri `Constants.SPRITES` dict'inden okunur.
Script içinde `"res://assets/sprites/..."` string'i **asla** hardcode edilmez.

```gdscript
## WRONG
sprite.texture = load("res://assets/sprites/characters/chef.png")

## CORRECT
sprite.texture = load(Constants.SPRITES["chef"])
```

---

## SPRITES Dict Formatı

```gdscript
## Constants.gd
const SPRITES := {
    ## Characters
    "chef":               "res://assets/sprites/characters/chef.png",
    "customer_regular":   "res://assets/sprites/characters/customer_regular.png",
    "customer_impatient": "res://assets/sprites/characters/customer_impatient.png",
    "customer_tourist":   "res://assets/sprites/characters/customer_tourist.png",

    ## Environment
    "stove":    "res://assets/sprites/environment/stove.png",
    "counter":  "res://assets/sprites/environment/counter.png",

    ## UI icons
    "icon_tea":    "res://assets/sprites/ui/icon_tea.png",
    "icon_pastry": "res://assets/sprites/ui/icon_pastry.png",
}
```

**Key formatı:** `{kategori}_{detay}` — snake_case, İngilizce.
Yeni sprite = dict'e satır ekle, kod değişmez.

---

## Sprite Swap Prosedürü

Kenney'den özel asset'e geçiş:
1. Yeni dosyayı `assets/sprites/` altına ekle (aynı klasör yapısı)
2. `Constants.SPRITES`'taki path'i güncelle
3. `make test` çalıştır — sprite yükleme logic'e bağlı değil, test kırılmaz
4. Godot'ta validate et

Başka dosyaya **dokunma**.

---

## İzometrik TileMap Kuralları

```gdscript
## TileMap ayarları (Godot editor'da):
## - TileSet → Tile Shape: Isometric
## - Tile Size: Vector2i(128, 64)
## - Y Sort: aktif (rendering doğru sıra için)
```

- Zemin tile'ları Layer 0'da
- Objeler (tezgah, ocak) Layer 1'de — Y-sort bu layer'da aktif
- Her sahnede sadece bir TileMap node'u (BufeScene, KafeScene vb.)

---

## Y-Sort Kuralı

İzometrik derinlik için tüm sahne object'leri Y pozisyonuna göre render sıralanır:

```gdscript
## Her Node2D / sprite için editor'da:
## Y Sort Enabled: true
## Ordering: pozisyon.y büyüdükçe önde çizilir (oyuncu kameraya yakın)
```

CustomerNode ve StoveSlot'ta `y_sort_enabled = true` olmalı.

---

## Animasyon — Şimdilik Yok

Animasyon Sprint 9 kapsamı dışında. Sprite statik yüklenebilir, `AnimatedSprite2D`
frame count = 1 olarak ayarlanabilir. Animasyon gelince `SpriteFrames` resource eklenir.

```gdscript
## Şimdilik: static texture yükle
if sprite and Constants.SPRITES.has(sprite_key):
    sprite.texture = load(Constants.SPRITES[sprite_key])
```
