# Blender — İzometrik Sprite Render Kurulumu

> Oyundaki kamera: **Orthographic, X: 60°, Z: 45°, Sensor Fit: Horizontal**
> Bu dokümandaki tüm ayarlar o açıyla eşleşecek şekilde yapılandırılmıştır.
>
> **Kamera geometrisi + canvas için tek kaynak:** `docs/sprite_render_sozlesmesi.md`
> (256×512 canvas, 2:1 diamond, offset -95). Bu dosya ışık kurulumu + workflow içindir.
>
> Bu workflow'un projedeki yeri: `docs/gorsel_sistem.md` §Pre-Rendered 3D Workflow

---

## 1. Kamera Kurulumu

Blender renderı oyunun izometrik görüşüyle örtüşmeli — aksi halde sprite sahneye oturduğunda açı tutarsız görünür.

```
Kamera tipi:  Orthographic  (Perspective değil)
X rotasyon:   60°           (game isometric — 2:1 diamond verir)
Z rotasyon:   45°           (izometrik yatay yön)
Sensor Fit:   Horizontal    (ortho scale'i genişliğe kilitler)
Ortho Scale:  tile_boyutu × √2  (4 birim tile → 5.6569)
```

**Blender'da hızlı ayarlama:**
1. Kamera seç → Properties → Object Data Properties
2. Type: Orthographic, Sensor Fit: Horizontal
3. Sağ panelde rotasyon: `X = 60`, `Z = 45`
4. Ortho Scale = tile_boyutu × √2

> **Neden 60° (54.74° değil)?** 60° game isometric'tir: diamond tam 2:1 (256×128px)
> çıkar — `ISO_TILE_HALF_W = ISO_TILE_HALF_H × 2` ile örtüşür. 54.74° "true isometric"tir
> (3 eksen eşit), 1.73:1 diamond verir — bu kod için YANLIŞTIR ve tile'ları üst üste bindirir.

### Ortho Scale ve Ortalama

**Ortho Scale = tile_boyutu × √2** — tüm asset'lerde sabit kalmalı (4 birim tile için 5.6569).
Render çıktısı **256×512 px** olduğu sürece tutarlılık bozulmaz. Sensor Fit Horizontal
sayesinde yükseklik 512 olsa da diamond genişliği 256px kalır. Oyun içi boyut Godot'ta
Sprite2D `scale` (0.5) ile ayarlanır.

**Objeyi merkeze almanın en kolay yolu — G kullanma:**
```
1. Objeyi seç
   Object → Set Origin → Origin to Geometry

2. Objeyi world origin'e taşı
   Object → Snap → Selection to Cursor  (cursor 0,0,0'da olmalı)

3. Kamera zaten origin'e bakıyor → obje otomatik ortada
```

Ya da kamera görüşündeyken:
```
Numpad 0 → kamera görüşüne gir
Numpad .  → Frame Selected (objeyi otomatik ortalar + Ortho Scale ayarlar)
```

---

## 2. Işık Kurulumu

İzometrik görüşte ışık **sol-üst köşeden** gelmelidir. Bu oyun sahnesindeki Y-sort derinliğiyle tutarlılık sağlar ve gölgeler sağ-alta düşer.

### Key Light (Ana Işık)

```
Tür:       Sun
Konum:     X: 5,  Y: -5,  Z: 8
Rotasyon:  X: 45°, Y: 0°, Z: 45°
Strength:  4  (W/m² — mesafeden bağımsız çalışır)
Renk:      #FFF5E0  (hafif sıcak beyaz)
```

> Sun ışığında Watts değil **Strength** parametresi görürsün — aynı slider, farklı birim.

### Fill Light (Dolgu — Gölgeyi Yumuşatır)

```
Tür:       Area
Konum:     X: -4,  Y: 4,  Z: 5
Rotasyon:  X: 60°, Y: 0°, Z: -30°
Güç:       1.5 W
Renk:      #D0E8FF  (soğuk mavi)
Boyut:     2 × 2
```

### World (Ortam Işığı)

```
World Properties → Surface → Background
Renk:  #505060  (nötr gri-mavi)
Güç:   0.4
```

> Fill light yoksa gölgeler sert ve siyah olur — mobilde düz bir silüet gibi görünür.
> World ambient, zemin yansımasını simüle eder ve genel parlaklığı dengeler.

---

## 3. Render Ayarları (PNG Export)

```
Render Engine:   Cycles  (veya EEVEE Next — daha hızlı, kalite yeterli)
Resolution:      256 × 512   (environment obje — genişlik 256, yükseklik 512)
                 128 × 192   (karakter — dikey uzun)
Samples:         Cycles: 128 / EEVEE: 32
Background:      Film → Transparent: ✓
Output Format:   PNG
Color:           RGBA  (alpha şart — sprite overlay için)
```

---

## 4. Nesne Tiplerine Göre Çözünürlük

| Nesne | Render Çözünürlüğü | Godot'ta Boyut | Not |
|-------|-------------------|----------------|-----|
| Zemin tile (floor) | 256 × 512 | Sprite2D scale 0.5 | diamond 256×128, sözleşme |
| Duvar (wall) | 256 × 512 | Sprite2D scale 0.5 | gövde üst boşlukta uzar |
| Orta obje (tezgah, sandalye) | 256 × 512 | Sprite2D scale 0.5 | aynı sözleşme |
| Küçük obje (bardak, tabak) | 256 × 512 | Küçük scale | UI icon olarak da kullanılabilir |
| Büyük obje (ocak, dolap) | 256 × 512 | Sprite2D scale 0.5 | gerekirse daha yüksek canvas |
| Karakter | 128 × 192 | Karakter boyutuna göre scale | Animasyon frame'leri aynı boyut |

> **Environment standardı 256×512** (`sprite_render_sozlesmesi.md`). Genişlik 256 diamond'ı
> doldurur, yükseklik 512 yüksek nesnelere yer açar — tüm set tutarlı kalır.

---

## 5. Ekran Boyutu ve Scaling

Farklı telefon ekranları için ayrı çözünürlükte sprite üretmene **gerek yok.**

Proje ayarları (`project.godot`):
```
viewport: 1080 × 1920
stretch/mode: canvas_items
stretch/aspect: expand
```

`canvas_items` modu Godot'un tüm sprite'ları ekran boyutuna göre otomatik scale etmesi demek.
Sen 256×512 sprite koy, Godot iPhone SE'de de Galaxy S24'te de doğru boyutta gösterir.

---

## 5. Adım Adım Render Workflow

```
1. Nesneyi sahneye al (import / model)
2. Kamera: Orthographic, X=60°, Z=45°, Sensor Fit Horizontal
3. Işıkları yukardaki ayarlarla ekle
4. Film → Transparent: açık
5. Çözünürlüğü nesne tipine göre ayarla
6. F12 → render
7. Image → Save As → PNG (RGBA)
8. assets/sprites/[kategori]/[obje].png olarak kaydet
9. Constants.SPRITES'ta path'i güncelle
10. make test
```

---

## 6. Karakter Animasyonu İçin Ek Adımlar

> Mixamo workflow için bkz. `docs/gorsel_sistem.md` §Karakterler

```
- Her frame için aynı kamera + ışık ayarı korunur
- Frame aralığı: Timeline'da başlangıç/bitiş frame'ini ayarla
- Render Animation (Ctrl+F12) → PNG dizisi
- Çıktı klasörü: assets/sprites/characters/[tip]/frames/
- Sonra sprite sheet'e dönüştür (opsiyonel: Texture Packer veya Pillow script)
```

---

## 7. Hızlı Kontrol Listesi

Render'dan önce şunu kontrol et:

- [ ] Kamera tipi Orthographic, Sensor Fit Horizontal
- [ ] X: 60°, Z: 45° (54.74° DEĞİL)
- [ ] Transparent background açık
- [ ] Key light sol-üstte, gölge sağ-alta düşüyor
- [ ] Output format: PNG + RGBA
- [ ] Çözünürlük nesne tipine uygun

---

## Versiyon

**v1.0** — Haziran 2026. İzometrik kamera eşleştirmesi, 3-point ışık kurulumu, nesne tipi çözünürlük tablosu.
