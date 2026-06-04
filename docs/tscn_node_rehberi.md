# .tscn Node Rehberi

Godot 4'te `.tscn` dosyalarında kullanılan node tiplerinin ve parametrelerinin açıklaması.
BufeScene.tscn referans alınarak yazılmıştır.

---

## Node Tanım Satırı

```
[node name="F_1_1" type="Sprite2D" parent="GameWorld/FloorContainer"]
```

| Alan | Anlamı |
|------|--------|
| `name` | Godot editörde görünen node adı |
| `type` | Node tipi — Sprite2D, Node2D, Camera2D, CanvasLayer vb. |
| `parent` | Hiyerarşide kimin altında olduğu. `.` = sahne kökü |
| `unique_id` | `%NodeAdi` sözdizimi ile koddan erişmek için benzersiz ID |
| `instance=ExtResource(...)` | Başka bir `.tscn` dosyasından instance alınmış node (prefab gibi) |

---

## Transform Parametreleri

```gdscript
position = Vector2(540, 484)   // dünya koordinatı
scale    = Vector2(0.7, 0.7)   // boyut çarpanı
rotation = 1.5708              // radyan cinsinden dönüş
```

| Parametre | Anlamı |
|-----------|--------|
| `position` | Node'un koordinatı (px). Parent'ın local space'inde |
| `scale` | Boyut çarpanı. `(0.7, 0.7)` = orijinalin %70'i |
| `rotation` | Radyan cinsinden dönüş açısı. `1.5708` rad = 90° |
| `z_index` | Çizim katmanı. Büyük değer = öne gelir. `-20` = her şeyin arkasında |

---

## Sprite2D Parametreleri

```gdscript
y_sort_enabled = true
flip_h         = true
offset         = Vector2(0, -64)
visible        = false
```

| Parametre | Anlamı |
|-----------|--------|
| `y_sort_enabled` | `true` = Y pozisyonuna göre derinlik sıralaması. Önde olan (büyük Y) üste çizilir. İzometrik derinlik için zorunlu |
| `flip_h` | Texture'ı yatay olarak aynalar. Sağ duvarları `wall_side.png`'den türetmek için kullanılır |
| `flip_v` | Texture'ı dikey olarak aynalar |
| `offset` | Texture merkezinin pivot noktasından kayması (local space, px). Zemin hizalaması için kullanılır: `offset.y = -(taban_y - 128)` |
| `visible` | `false` = başlangıçta gizli. Kod ile `node.visible = true` yapılana kadar görünmez |
| `texture` | Hangi `.png` yüklü. Editörde atanmışsa burada görünür, kod ile yükleniyorsa satır olmaz |

### offset Neden Gerekli?

Sprite2D varsayılan olarak texture'ın **merkezini** node pozisyonuna koyar. İzometrik
sprite'larda zemin temas noktası merkezde değil, altlarındadır. `offset.y` negatif
yapılarak texture yukarı kaydırılır ve temas noktası node pozisyonuna hizalanır.

```
offset.y = -(taban_y_in_texture - texture_height / 2)

Örnek — 256×512 sprite (sözleşme), zemin temas y=351:
offset.y = -(351 - 256) = -95
```

> Sözleşmeye (256×512) uygun render'da tüm environment asset'lerinde temas noktası
> aynı pikselde (y=351) olur → offset her asset'te sabit -95. Detay:
> `docs/sprite_render_sozlesmesi.md`.

Projedeki sabitler: `Constants.SPRITE_OFFSET_WALL`, `SPRITE_OFFSET_FLOOR` vb.

---

## Camera2D Parametreleri

```gdscript
position                   = Vector2(412, 560)
zoom                       = Vector2(1.3, 1.3)
position_smoothing_enabled = false
```

| Parametre | Anlamı |
|-----------|--------|
| `position` | Kameranın baktığı dünya noktası. Sahne ortasına hizalanır |
| `zoom` | `1.0` = normal. `1.3` = %30 yakınlaştırılmış (nesneler büyük görünür). `0.85` = uzaklaştırılmış |
| `position_smoothing_enabled` | `false` = anında hareket. `true` = kamera yavaşça takip eder |
| `drag_*_enabled` | Kameranın oyuncu ile sürüklenmesi. Büfe sahnesi statik, ikisi de `false` |

Büfe sahnesi kamera zoom seviyeleri Constants'ta:
```gdscript
CAMERA_ZOOM_START = Vector2(1.3, 1.3)   // başlangıç
CAMERA_ZOOM_MID   = Vector2(1.1, 1.1)   // CNT_02 veya KIT_03 sonrası
CAMERA_ZOOM_MAX   = Vector2(0.9, 0.9)   // Level 5
```

---

## CanvasLayer Parametreleri

```gdscript
layer = 10
```

| Parametre | Anlamı |
|-----------|--------|
| `layer` | Render katmanı numarası. Oyun dünyası = 0, UI = 10. Büyük katman her zaman üste çizilir. **Kameradan etkilenmez** — ekrana sabitlenir |

---

## Control / UI Parametreleri

```gdscript
layout_mode    = 3
anchors_preset = 12
anchor_top     = 1.0
anchor_right   = 1.0
anchor_bottom  = 1.0
offset_top     = -120.0
```

| Parametre | Anlamı |
|-----------|--------|
| `layout_mode = 3` | Anchor tabanlı layout kullan |
| `anchors_preset` | Hazır anchor şablonu (aşağıdaki tabloya bakın) |
| `anchor_left/top/right/bottom` | Kenarın ekrana göre konumu. `0.0` = sol/üst kenar, `1.0` = sağ/alt kenar |
| `offset_left/top/right/bottom` | Anchor noktasından px cinsinden kaydırma (pozitif = içeri, negatif = dışarı) |
| `grow_horizontal/vertical` | Boyut artışının hangi yöne doğru olacağı |

### Sık Kullanılan anchors_preset Değerleri

| Değer | Anlamı | Kullanım Yeri |
|-------|--------|---------------|
| `15` | Tam ekran | UpgradePanel, MenuPanel |
| `12` | Üst — tam genişlik | HUDBar |
| `14` | Alt — tam genişlik | BottomNav (offset_top=-120 ile yükseklik belirlenir) |
| `6`  | Sağ — dikey orta | RightSidePanel |

### Örnek: BottomNav

```
anchor_top    = 1.0   → alt kenara yapış
anchor_bottom = 1.0   → alt kenara yapış
anchor_right  = 1.0   → tam genişlik
offset_top    = -120  → alt kenardan 120px yukarıda başla
```

---

## Node İçi Script / Resource

```gdscript
script   = ExtResource("4_cust")
instance = ExtResource("14_bottom_nav")
```

| Parametre | Anlamı |
|-----------|--------|
| `script` | Bu node'a bağlı `.gd` dosyası. Node davranışını tanımlar |
| `instance` | Başka bir `.tscn` dosyasından kopyalanmış sahne (prefab). HUDBar, BottomNav, WelcomeModal böyle |

---

## Node Tipleri — Kısa Referans

| Tip | Ne İşe Yarar |
|-----|-------------|
| `Node2D` | Temel 2D container. Çocukları organize etmek için kullanılır |
| `Sprite2D` | Tek bir texture (PNG) gösterir |
| `AnimatedSprite2D` | SpriteFrames resource ile animasyonlu sprite |
| `Camera2D` | Oyun kamerası. `zoom` ve `position` ile sahneyi çerçeveler |
| `CanvasLayer` | UI katmanı. Kameradan bağımsız, ekrana sabit |
| `ColorRect` | Düz renkli dikdörtgen. SkyRect arka plan için kullanılır |
| `StaticBody2D` | Fizik çarpışması olan sabit nesne. Counter'da var |
| `CollisionShape2D` | StaticBody2D'ye şekil verir |
| `Marker2D` | Görünmez işaret noktası. QSlot ve StoolSlot waypoint'leri için |
| `VBoxContainer` | Çocukları dikey olarak sıralar. RightSidePanel, ToastContainer |
| `Node` | En temel tip, 2D/3D koordinatı yok. Systems container'ı için ideal |

---

*Referans: BufeScene.tscn — Haziran 2026*
