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

## Asset Hizalama Kuralları

### 1. Zemin Referans Noktası (Pivot)

Tüm environment sprite'larının pivot noktası **izometrik ayak izinin ön-merkezi**nde
olmalıdır — yani nesnenin zemine temas ettiği nokta. Sprite'ın üst köşesi değil.

```
İzometrik tile'ın "zemin temas noktası":

        /▔▔▔\
       /  ×  \    ← × = pivot noktası (sprite.offset ile ayarlanır)
       \     /
        \▄▄▄/

Sprite2D.offset: genellikle (0, -sprite_height/2) değil,
sprite'ın "ayak" noktasına göre ayarlanır.
```

**Kural:** Aynı tipteki tüm sprite'lar (tüm duvarlar, tüm tezgahlar, tüm tabureler)
**aynı offset değerini** kullanır. Birinden farklı offset = görsel boşluk veya yükseklik farkı.

```gdscript
## WRONG — her sprite farklı offset
wall_a.offset = Vector2(0, -45)
wall_b.offset = Vector2(0, -48)   ## 3px fark = boşluk görünür

## CORRECT — sabit, tüm duvarlar aynı
const WALL_OFFSET := Vector2(0, -Constants.WALL_SPRITE_HALF_HEIGHT)
wall_a.offset = WALL_OFFSET
wall_b.offset = WALL_OFFSET
```

---

### 2. Grid Hizalaması — Zorunlu

Her environment objesi izometrik grid'e snap'lenmeli. Pozisyon hesabı:

```gdscript
## Tek doğru yol — magic number yok
func iso_to_screen(col: int, row: int) -> Vector2:
    return Vector2(
        Constants.ISO_ORIGIN_X + col * Constants.ISO_TILE_HALF_W - row * Constants.ISO_TILE_HALF_W,
        Constants.ISO_ORIGIN_Y + col * Constants.ISO_TILE_HALF_H + row * Constants.ISO_TILE_HALF_H
    )

## Kullanım
wall_sprite.position = iso_to_screen(col, row)
```

Sub-pixel offset (örn. `position = iso_to_screen(...) + Vector2(0.5, 0)`) **yasak** —
bitişik tile'lar arasında 1px boşluk açar.

---

### 3. Duvar Yüksekliği Tutarlılığı

Tüm duvar sprite'ları aynı piksel yüksekliğinde olmalı. Farklı yükseklik =
duvarlar arasında görsel kopukluk.

```gdscript
## Constants.gd'de tanımlanır
const WALL_HEIGHT_PX : int = 96    ## tüm duvar sprite'larının yüksekliği
```

Yeni asset eklenirken bu değere göre crop/resize yapılır.
Kod tarafında scale ile kompanse etmek **yasak**.

---

### 4. Birleşik Obje Boşluksuzluğu

Counter, duvar gibi yan yana gelen parçalar arasında boşluk **olamaz**:

```gdscript
## WRONG — 0.5px fazla offset = gözle görülür dikiş
counter_m.position = iso_to_screen(1, 2) + Vector2(0.5, 0)

## CORRECT
counter_l.position = iso_to_screen(0, 2)
counter_m.position = iso_to_screen(1, 2)
counter_r.position = iso_to_screen(2, 2)
```

Bitişik parçalar her zaman ardışık (col, col+1, col+2) grid pozisyonlarında olur.
Aralarında ek offset **yasak**.

---

### 5. Scale Tekliği

Aynı kategorideki tüm sprite'lar aynı scale değerini kullanır:

```gdscript
## Constants.gd
const ENV_SPRITE_SCALE := Vector2(1.0, 1.0)   ## veya proje genelinde kararlaştırılan değer
```

Tek bir sprite'ı büyütmek/küçültmek için scale kullanmak **yasak**.
Farklı boyut gerekiyorsa ayrı bir asset kullanılır.

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
