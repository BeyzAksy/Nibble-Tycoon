# Sprite Render Sözleşmesi — Lezzet İmparatorluğu

> Bu belge, oyundaki tüm environment sprite'larının Blender'da nasıl
> render edileceğini tanımlar. Bir kez uygula, tüm asset'lerde tutarlılık sağlanır.

---

## Neden Bu Sözleşme Gerekli?

Eskiden asset'lerin diamond boyutları tutarsızdı (standart kamera ayarı yoktu):

```
floor.png    → diamond 201×130px   (eski — düzeltildi)
wall.png     → diamond 142×233px   (eski — düzeltildi)
counter.png  → diamond 161×133px   (eski — düzeltildi)
stool.png    → diamond  64×61px    (eski — düzeltildi)
```

Sonuç: tile'lar arası boşluk/binme, offset tahminleri, her yeni asset ayrı ölçüm.

**Bu sözleşme ile:** Kamera bir kez doğru kurulur (X=60°, ortho, Sensor Fit Horizontal),
render alınan her asset 256×512 canvas'ta 2:1 diamond ile gelir ve grid'e oturur.
Ek ölçüm, boşluk sorunu olmaz; offset tüm asset'lerde sabit (-95).

> **Durum (Haziran 2026):** floor + wall + wall_side + counter + stool — hepsi sözleşmeye
> geçti, 256×512, offset -95. Sahne hizası Godot'ta doğrulandı.

---

## Sözleşme: Canvas Standardı

```
Canvas boyutu  : 256 × 512 px   (genişlik 256, yükseklik 512)
Arka plan      : Şeffaf (alpha = 0)
Anti-aliasing  : EEVEE, 8+ sample

Zemin diamond  : Tam 256px geniş, tam 128px yüksek

Zemin temas    : Blender origin (0,0,0) → canvas'ta y=351 pikseline düşer
                 (kamera sabit olduğu için her asset'te aynı yere düşer)
                 Diamond merkezi = bu nokta = nesnenin grid temas noktası

Nesne gövdesi  : Temas noktasının üstündeki ~351px'e uzar (duvar yüksekliği için)
                 Genişlik sabit 256px, yükseklik 512px tall asset'leri kapsar
```

> **Neden 256×512 ve neden y=351?** Genişlik 256, zemin diamond'ını (256px) tam
> doldurur. Yükseklik 512, duvar gibi yüksek nesnelerin yukarı uzamasına yer açar.
> Sensor Fit = Horizontal sayesinde yükseklik artışı diamond genişliğini bozmaz.
> Origin canvas merkezinde (256) değil, alt-orta bölgede (351) — çünkü nesne gövdesi
> yukarı doğru uzadığından üstte daha çok boşluk gerekir.

```
     0
     ┌──────────────────────────┐  ← y=0
     │                          │
     │    nesne gövdesi         │   ← duvar/tezgah gövdesi yukarı uzar
     │    (duvar, tezgah vs.)   │
     │                          │
     │      /◆◆◆◆◆◆◆◆◆\         │  ← y=287  zemin diamond başlar (N vertex)
351  │─────◆──────────◆─────────│  ← y=351  TEMAS NOKTASI = origin = diamond merkezi
     │      \◆◆◆◆◆◆◆◆◆/         │  ← y=434  zemin diamond biter (S vertex)
     │                          │
512  └──────────────────────────┘  ← y=512
```

**Kural:** Blender'da her nesneyi dünya orijinine (0, 0, 0) — zemin temas merkezine —
hizala. Kamera sabit olduğu için orijin her render'da canvas'ta aynı piksele (y=351)
düşer. Bu, tüm asset'lerin tek bir offset ile hizalanmasını sağlar.

---

## Blender Kurulumu — Adım Adım

### 1. Sahneyi Aç / Temizle

- Blender'ı aç, mevcut `.blend` dosyasını aç
- Kamera varsa seç, yoksa **Add → Camera** ekle

### 2. Kamerayı Seç

- Viewport'ta kameraya sol tık (seçili olsun)
- Sağ panelde **Object Properties** (turuncu kare ikon) aç

### 3. Kamera Rotation Ayarla

**Transform → Rotation** altına şu değerleri gir:

```
X = 60°
Y = 0°
Z = 45°
```

> **Neden 60°?** Bu açı, game isometric 2:1 projeksiyon üretir: diamond tam olarak
> 2× geniş, 1× yüksek çıkar → `ISO_TILE_HALF_W = ISO_TILE_HALF_H × 2` ile tutarlı.
> 54.7356° ise "true isometric" açısıdır — 3 ekseni eşit uzunlukta gösterir ama
> 1.73:1 diamond üretir, 2:1 değil. Game sprite'ları için yanlış açıdır.

### 4. Kamera Konumu Ayarla

**Transform → Location** altına:

```
X =  5
Y = -5
Z =  7
```

> Orthographic kamerada konum uzaklığı render'ı etkilemez.
> Sahnenin önünde ve üstünde bir yerde olması yeterli.

### 5. Kamera Tipini Orthographic Yap

- Kamera seçiliyken **Object Data Properties** (yeşil kamera ikon)
- **Lens** bölümünde **Type → Orthographic** seç
- **Sensor Fit → Horizontal** seç (ÖNEMLİ — bu, ortho scale'i genişliğe kilitler;
  canvas yüksekliğini artırsan bile diamond genişliği bozulmaz)
- **Orthographic Scale** değerini gir:

```
Tile Blender'da 1×1 birim ise  → Orthographic Scale = 1.4142  (= √2)
Tile Blender'da 2×2 birim ise  → Orthographic Scale = 2.8284  (= 2√2)
Tile Blender'da 4×4 birim ise  → Orthographic Scale = 5.6569  (= 4√2)
```

> Formül: `Scale = tile_boyutu × √2`
>
> Emin olmak için: Render'ı al, floor tile'ın sol ve sağ köşesi tam canvas
> kenarına mı değiyor? Evet → doğru. Değilse Scale'i küçük artır/azalt.

### 6. Render Çözünürlüğü

- **Render Properties** (kamera ikon) → **Output** bölümü
- **Resolution X = 256, Resolution Y = 512**
- Genişlik 256 (diamond'ı doldurur), yükseklik 512 (yüksek duvarlara yer açar)
- **Frame Rate** önemli değil (tek kare render alacaksın)

### 7. Şeffaf Arka Plan

- **Render Properties → Film** bölümü
- **Transparent** kutusunu işaretle ✓

Kontrol: Render aldığında arka plan grid deseni (şeffaflık) görünmeli, koyu renk değil.

### 8. Render Engine

- **Render Properties → Render Engine → EEVEE** (daha hızlı, sprite için yeterli)
- **Sampling** → **Render** değerini `64` yap (temiz görüntü için)

---

## Nesne Yerleştirme Kuralları

### Floor Tile (Zemin)

```
Dünya orijini (0, 0, 0) = tile'ın merkezi

Tile geometry: 1×1 birim düzlem (Z=0)
Tile'ın tam ortası orijinde olmalı.

Kontrol: Render'da diamond tam ortalanmış, sol-sağ eşit boşluk
```

### Wall (Duvar)

```
Duvarın TABAN MERKEZİ orijinde (0, 0, 0)
Duvar gövdesi +Z yönüne uzar

Tipik duvar: 1×0.1 birim taban, 1.5 birim yükseklik
Taban merkezi: (0, 0, 0)
Duvar üstü: (0, 0, 1.5)

Kontrol: Render'da duvar tabanı canvas merkezi (128px, 128px) civarında
```

### Counter / Stool / Diğer Mobilya

```
Nesnenin TABAN MERKEZİ orijinde (0, 0, 0)
Nesne gövdesi +Z yönüne uzar

Kontrol: Render'da nesnenin zemin temas noktası canvas orta çizgisinde
```

---

## Export (PNG Kaydetme)

Render aldıktan sonra:

1. **Image → Save As**
2. Dosya formatı: **PNG**
3. **Color Mode: RGBA** (şeffaflık dahil)
4. **Color Depth: 8** (yeterli)
5. `assets/sprites/environment/` klasörüne kaydet

Komut satırından render almak için (opsiyonel, hızlı tekrar render):

```bash
blender -b dosya.blend -o //render_ -f 1
```

---

## Godot'ta Kod Değişikliği (Bir Kez)

Bu sözleşme uygulandıktan sonra Constants.gd şu değerlere geçer:

```gdscript
## Sözleşme: 256×512 canvas, diamond tam 256×128px
const ISO_TILE_HALF_W  : int = 128   ## diamond 256/2
const ISO_TILE_HALF_H  : int = 64    ## diamond 128/2
const ENV_SPRITE_SCALE := Vector2(0.5, 0.5)  ## 256 × 0.5 = 128px efektif

## Zemin temas noktası canvas merkezinde (256) değil, y=351'de.
## offset.y = -(351 - 256) = -95 — tüm asset'lerde aynı (kamera sabit).
const SPRITE_OFFSET_FLOOR     := Vector2(0, -95)
const SPRITE_OFFSET_WALL      := Vector2(0, -95)
const SPRITE_OFFSET_WALL_SIDE := Vector2(0, -95)
const SPRITE_OFFSET_COUNTER   := Vector2(0, -95)
const SPRITE_OFFSET_STOOL     := Vector2(0, -95)
```

Kamera sabit olduğu için offset her asset'te aynı (-95). Per-asset offset takibi olmaz.

---

## Kontrol Listesi (Her Asset için)

Render almadan önce:

- [ ] Kamera X=60°, Y=0°, Z=45° (bir kez ayarlandı, değiştirme)
- [ ] Kamera Orthographic, Sensor Fit = Horizontal, Scale = tile_boyutu × √2
- [ ] Track-To vb. constraint YOK (rotasyonu ezer, açıyı bozar)
- [ ] Film → Transparent işaretli
- [ ] Çözünürlük 256×512
- [ ] Nesnenin TABAN MERKEZİ dünya orijininde (0, 0, 0)
- [ ] Render sonrası: zemin diamond 256×128px (2:1) mi? Sol-sağ simetrik mi?
- [ ] PNG RGBA olarak kaydedildi

---

## Sık Yapılan Hatalar

| Hata | Belirti | Düzeltme |
|------|---------|----------|
| Kamera açısı yanlış | Diamond 2:1 değil | X=60° kontrol et (54.7° true-iso, 1.73:1 verir — YANLIŞ) |
| Track-To constraint var | Açı rotasyondan değil konumdan hesaplanıyor | Constraint'i sil, açıyı elle gir |
| Sensor Fit Vertical | Canvas uzayınca diamond küçülüyor | Sensor Fit → Horizontal |
| Nesne orijinde değil | Offset, render'da kaymış | Object → Apply → All Transforms |
| Scale yanlış | Diamond canvas'ı taşıyor/doldurmıyor | Scale = tile_boyutu × √2 |
| Transparent kapatık | Siyah arka plan | Film → Transparent işaretle |
| RGBA değil RGB | Godot'ta şeffaflık yok | Export'ta RGBA seç |

---

*v1.0 — Haziran 2026*
*Referans: `autoload/Constants.gd` ISO sabitleri, `.claude/rules/visual.md`*
