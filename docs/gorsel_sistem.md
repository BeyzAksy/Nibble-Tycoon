# Görsel Sistem — Sanat Yönü ve Asset Stratejisi

> "Nasıl görünecek?" sorusunun cevabı burada.
> Teknik sprite kuralları için: `.claude/rules/visual.md`

---

## Stil Kararı

**İzometrik 2.5D** — Büfe, Kafe, Bistro aşamalarının tamamında kullanılır.

- Kamera açısı: klasik izometrik (45° yatay, ~30° dikey)
- Tile boyutu: 128×64 px (Godot izometrik TileMap standardı)
- Render sırası: Y-sort aktif — önde duran karakter üstte çizilir
- UI overlay: her zaman 2D flat, oyun dünyasından bağımsız katman

---

## Asset Stratejisi

### Şimdiki Durum (Geliştirme)

Kenney ücretsiz paketlerinden geçici asset'ler kullanılır:

| Paket | Kullanım |
|-------|---------|
| [Kenney Isometric City Tiles](https://kenney.nl/assets/isometric-city-tiles) | Zemin, duvar, tezgah, masa |
| [Kenney Isometric Characters](https://kenney.nl/assets/isometric-characters) | Müşteri figürleri, şef |
| [Kenney Food Kit](https://kenney.nl/assets/food-kit) | Sipariş bubble'larındaki item ikonları |

Asset'ler `assets/sprites/` altında gruplandırılır:

```
assets/sprites/
  characters/
    chef.png
    customer_regular.png
    customer_impatient.png
    customer_tourist.png
  environment/
    floor_tile.png
    wall.png
    stove.png
    counter.png
  ui/
    (ikonlar, buton görselleri)
```

### Hedef Durum (Ürün) — Pre-Rendered 3D Workflow

Özel asset'ler **pre-rendered 3D** yöntemiyle üretilir.
Oyun runtime'da 3D çalıştırmaz — sadece PNG yükler, performans/boyut etkisi yoktur.

#### Çevre Objeleri (ocak, tezgah, sandalye, dekor)

```
Midjourney / DALL-E
  prompt: "isometric restaurant [obje], game asset, white background"
      ↓
Trellis (Microsoft) — tek image'dan 3D mesh + PBR texture üretir
      ↓
Blender — izometrik kamera (orthographic, X: 60°, Z: 45°, Sensor Fit Horizontal)
          256×512 canvas, render → transparent background PNG
      ↓
assets/sprites/environment/[obje].png
      ↓
Constants.SPRITES'ta path güncelle → bitti
```

#### Karakterler (chef, müşteri tipleri)

```
Midjourney
  prompt: "isometric 2.5D character [chef/customer], Hay Day style, white background"
      ↓
HunyuanH3D-2 (Tencent) — karakterler için tercih edilir, daha temiz topology
      ↓
Mixamo (mixamo.com — Adobe, ücretsiz)
  FBX yükle → otomatik rig → animasyon seç (idle / walk / sitting_idle)
  FBX export
      ↓
Blender — FBX import, izometrik kamera, her frame render → PNG dizisi
      ↓
Sprite sheet → assets/sprites/characters/[tip]/
```

#### Karakter Varyasyonları

Aynı base model, Blender'da material rengi değiştir → tekrar render:

| Tip | Değişiklik |
|-----|-----------|
| regular | Mavi/neutral kıyafet |
| impatient | Kırmızı/canlı renk tonu |
| tourist | Şapka + renkli kıyafet |

Her varyasyon ~5 dakika.

#### Yön Stratejisi

İzometrik'te karakter asla önden/arkadan görünmez. **2 render + flip = 4 yön:**

| Yön | Yöntem |
|-----|--------|
| SE (sağ-aşağı) | Blender'da render al |
| NE (sağ-yukarı) | Blender'da render al |
| SW | SE'nin yatay flip'i (`flip_h: true`) |
| NW | NE'nin yatay flip'i (`flip_h: true`) |

Büfede müşteri path'i sabittir, 2 yön yeterlidir.

#### Sprite Sıkıştırma

- Godot import: **Compress Mode → VRAM Compressed** (mobil zorunlu)
- Sprite atlas: aynı karakterin tüm frame'leri tek PNG'ye → `TextureAtlas`
- Runtime bellek etkisi: Kenney sprite'ı ile aynı düzeyde

**Swap maliyeti sıfır** — sadece `Constants.SPRITES` dict'indeki path değişir.
Bkz. `.claude/rules/visual.md` §Sprite Swap Prosedürü.

#### Araçlar

| Araç | Link | Ücret |
|------|------|-------|
| Midjourney | midjourney.com | ~$10/ay |
| Trellis | github.com/microsoft/TRELLIS | Ücretsiz |
| HunyuanH3D-2 | Tencent HuggingFace Space | Ücretsiz |
| Mixamo | mixamo.com | Ücretsiz (Adobe hesabı) |
| Blender | blender.org | Ücretsiz |

---

## UI Katmanı

Overlay UI (HUD, paneller, modaller) **flat tasarım** kullanır — izometrik dünyadan görsel olarak ayrı.

**Neden flat?**
- Okunabilirlik: izometrik arka plan üzerinde 3D UI kaybolur
- Geliştirme hızı: tema/renk sistemi yeterli, asset beklemiyor
- Standart mobil UX beklentisi

UI renk sistemi `autoload/Constants.gd` içinde tanımlıdır.
Bileşen kuralları `scripts/ui/CLAUDE.md` içindedir.

---

## Animasyon Kuralları

> Animasyon sistemi şu an implement edilmemiş (LI-67 kapsamı dışı). Aşağıdakiler planlanan yaklaşım.

- `AnimatedSprite2D` kullanılır, `AnimationPlayer` değil (basitlik)
- Animasyon adı formatı: `{customer_type}_idle`, `{customer_type}_walk`, `{customer_type}_sit`
- Frame'ler `SpriteFrames` resource üzerinden yönetilir (Constants.SPRITES değil)
- Mixamo walk cycle: ~8 frame yeterli, Blender'da her frame ayrı render

---

## Versiyon

**v1.1** — Haziran 2026. Pre-rendered 3D workflow eklendi: Midjourney → HunyuanH3D-2/Trellis → Mixamo → Blender → PNG. Araç listesi, yön stratejisi, sprite sıkıştırma kararları.

**v1.0** — Haziran 2026. İzometrik 2.5D kararı, Kenney geçiş stratejisi, flat UI kararı.
