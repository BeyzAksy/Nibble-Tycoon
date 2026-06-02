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

### Hedef Durum (Ürün)

Özel çizilmiş / yaptırılmış asset'ler ile swap edilir.
**Swap maliyeti sıfır** — sadece `Constants.SPRITES` dict'indeki path değişir.
Bkz. `.claude/rules/visual.md` §Sprite Swap Prosedürü.

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

> Animasyon sistemi şu an implement edilmemiş. Bu bölüm ileride doldurulacak.

Planlanan:
- Her karakter tipi için `idle` ve `walk` animasyonu
- `AnimatedSprite2D` kullanılır, `AnimationPlayer` değil (basitlik)
- Animasyon adı formatı: `{customer_type}_idle`, `{customer_type}_walk`
- Animasyon frame'leri `Constants.SPRITES` üzerinden değil, `SpriteFrames` resource üzerinden yönetilir

---

## Versiyon

**v1.0** — Haziran 2026. İzometrik 2.5D kararı, Kenney geçiş stratejisi, flat UI kararı.
