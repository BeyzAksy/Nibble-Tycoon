# Büfe Sahnesi Tasarım Belgesi

**Referans:** GDD §4 (Mekan Yerleşimi), §8 (Upgrade Ağacı)
**Aşama:** Büfe Level 1–5

---

## Vizyon

Küçük bir sokak büfesi, izometrik 2.5D bakış açısından tam ekran görüntüleniyor.
Kamera güney yönünden, yukarıdan bakıyor. Kuzey duvarı (mutfak) ve yan duvarlar
(batı, doğu) görünür; güney cephe kapı çerçevesi dışında açık.
Müşteriler kaldırımdan kapıya yürüyerek içeri giriyor.

Mekan küçük ve samimi: 4×8 tile alan, upgrade ile görsel doluluk kazanıyor
(tabure, ocak ekleniyor). Kamera da buna göre yavaş çekiliyor.

---

## Yön Sözlüğü

Tüm dokümanlarda bu compass kullanılır:

```
           KUZEY (K) — mutfak, arka duvar
               △
              /|\
             / | \
   BATI (B) /  |  \ DOĞU (D)
   sol      \  |  /  sağ
             \ | /
              \|/
               ▽
           GÜNEY (G) — kamera, açık cephe

Ekranda: K=üst  G=alt  B=sol  D=sağ
col+ ekseni = Doğu (sağ-aşağı)
row+ ekseni = Batı→Güney (sol-aşağı)
```

Mevcut izometrik projeksiyon 4×8 (4 col × 8 row) olduğu için
diamond **hafif batı yönüne** eğimlidir — bu kasıtlı, olduğu gibi kalır.

---

## Ekran Düzeni

**Yönlendirme:** Portrait (dikey), 1080×1920  
**Oyun dünyası:** Tam ekran (UI overlay)

İzometrik oda küçük bir diamond olarak portrenin ortasında yer alır.
Odanın üstünde gökyüzü/arka plan, altında sokak alanı görünür.

```
┌────────────────────┐  1080px
│ 💰3.7K  Lv.1    ⚙️│  ← HUDBar (80px)
│                    │
│   ~~ gökyüzü ~~    │
│                    │
│      /▔▔▔▔▔\       │
│     /mutfak  \     │
│    /[◼][şef][◼]\   │  [🏠] ← RightSidePanel
│   /──tezgah────\   │  [🍽️]   (ekranın sağına
│   \[●][●][·][·]/   │  [⬆️]    yapışık, dikey
│    \  iç alan /    │  [🏆]    ortalanmış)
│    [KAPI]\────/     │  ← kapı güney duvarının batı ucunda
│  · ○ · ○ ○ · ·     │  ← dışarıda dağınık bekleyen müşteriler
│   .....sokak.....  │
│                    │
└────────────────────┘  1920px
```

İzometrik oda, ekranın yaklaşık %45–55 dikey alanını kaplar.
Kamera zoom=0.75 ile çekilmiş, oda tüm sahneyi gösterir.
Sağ panel ikonları game world'ün üstüne overlay olarak gelir.

### RightSidePanel Özellikleri
- Genişlik: 96px, ekranın sağ kenarına yapışık
- 4 ikon buton: Restoran, Menü, Upgrade, Başarım
- Her ikon: 80×80px, yuvarlak köşe, yarı şeffaf koyu arka plan
- Aktif sekme: `Constants.CORAL` arka plan rengi
- Dikey hizalama: ekran yüksekliğinin %30–%70'i arası

---

## Mekan Grid Tasarımı

**Tile boyutu:** 128×64 izometrik  
**İç mekan:** 4 sütun × 8 satır (az geniş, çok derin → portrait'e uygun)  
**Koordinat:** `(col, row)` — bu bir kat planı şemasıdır, izometrik görünüş değil

### Kat Planı (Yukarıdan Bakış — Şema)

```
        col0   col1   col2   col3
row 0:  [BW]  [STW1]  [BW]   [BW]   ← Mutfak arka duvarı + 1 ocak (başlangıç)
row 1:  [KF]  [KF]   [ŞEF]  [KF]   ← Mutfak zemini
row 2:  [KF]  [CNT]  [CNT]  [CNT]   ← Tezgah/Counter
row 3:  [ST1] [ST2]  [ST3]  [ST4]   ← Tabureler (ST1+2 başta, ST3/4 upgrade ile)
row 4:  [DF]  [DF]   [DF]   [DF]    ← İç geçiş zemini (müşteriler tabureye buradan geçer)
row 5:  [KAPI] [EXT] [EXT]  [EXT]   ← Giriş kapısı (güney duvarının batı ucu = col 0)
row 6:  [EXT] [EXT]  [EXT]  [EXT]   ← Kaldırım — dağınık bekleme alanı
row 7:  [EXT] [EXT]  [EXT]  [EXT]   ← Kaldırım — spawn / çıkış hattı

> Başlangıç durumu: STW1 görünür, col2/col3 boş duvar.
> KIT_03 (Level 3) ile col2'ye STW2 eklenir (visible=true).
> Sıra içeride değil — müşteriler dışarıda, kapı önünde bekler.
```

### Ekranda İzometrik Projeksiyon Olarak

Az geniş (4 col), çok derin (8 row) oda — izometrik projeksiyonda diamond
yukarı-aşağı uzar, yatay yayılmaz. Portrait ekranda doğal görünür.

```
        ← ~640px ekran genişliği →
            /▔▔▔▔▔▔▔\
           /   STW ·  \      ← row 0  (kuzey/arka duvar, 1 ocak)
          /   KF  ŞEF  \     ← row 1  (mutfak)
         /───CNT CNT───\     ← row 2  (tezgah)
         \  ST1 ST2    /     ← row 3  (tabureler)
          \  iç alan  /      ← row 4  (iç geçiş)
      [KAPI]\────────/       ← row 5  (güney duvarı batı ucu = col 0)
     ○ · ○ · ○ · · ·         ← row 6  (kaldırım, dağınık bekleme)
      · · · · · · ·           ← row 7  (spawn / çıkış hattı)
```

**Semboller:**
| Sembol | Açıklama |
|--------|----------|
| BW | Back Wall — görünür arka duvar |
| STW_1/2 | Stove Wall — ocak olan duvar nişi |
| KF | Kitchen Floor — mutfak zemini |
| ŞEF | Chef spawn/home pozisyonu |
| CNT | Counter piece — tezgah parçası |
| DF | Dining Floor — müşteri alanı zemini |
| ST_1..4 | Stool — tabure (1-2 başta görünür, 3-4 upgrade ile) |
| Q_1..7 | Queue waypoint — kapı önü kaldırımda dağınık bekleme pozisyonları |
| EXT | Exterior — kaldırım/dış alan |
| KAPI | Door — giriş kapısı |

### Dollhouse Etkisi
Kamera önden-sola bakıyor. Görünmeyen duvarlar:
- Sol yan duvar (col -1) → **yok** (dollhouse cut)
- Sağ yan duvar (col 5) → **yok** (dollhouse cut)
- Ön yüz (row 8+) → **yok** (açık alan)
- Arka duvar (row 0) → **görünür** (mutfak duvarı, ocak burada)
- Sol arka köşe, sağ arka köşe → **kısmen görünür**

---

## Müşteri Yolu

```
[Spawn] ekran dışı alt (kaldırımın altı)
    ↓ kaldırımda yürüme
    ├─ [Tüm Q_slot'lar dolu] → kapıya bakmadan düz yürür, ekran dışı  ← BYPASSED
    └─ [Boş Q_slot var] → slot seçer, kapı önünde durur
        ├─ [Sabır dolar] → döner, kapıya yürür, ekran dışı  ← CANCELLED_QUEUE
        └─ [Tabure boşalır]
            ↓ kapıdan içeri girer
[Tabure] ST_1 → ST_2 → ST_3* → ST_4*   (*upgrade ile açılır)
    ↓ sipariş otomatik verilir, şef pişirir
[Counter] yemek teslim alınır
    ↓ eating timer
[Çıkış] tabureden kalkar, kapıya yürür, ekran dışı
```

### BYPASSED Davranışı

Sıra doluysa müşteri **hiç durmaz** — kaldırımdan geçip gider.
Coin kaybı yok (fırsat kaybı), `order_cancelled` sinyali **yayılmaz**.
Bu görsel baskı oyuncuyu CNT_03 / CNT_04 almaya iter.

### Dağınık Bekleme Sistemi

Müşteriler kapı önünde **sıra oluşturmaz** — boş bir Q_slot'a rastgele yerleşir.
Q_slot'lar `QueueArea` altında önceden yerleştirilmiş `Marker2D` node'larıdır;
row 6–7 kaldırım alanına elle saçılmış pozisyonlar.

```
KAPI
 · Q3 · Q1 · Q5 ·
Q7 · Q2 · Q4 · Q6
 · · · · · · · ·    ← kaldırım
```

Başlangıç kapasitesi = 3 slot aktif (Constants.BUFFET_MAX_QUEUE = 3).
CNT_03 ve CNT_04 upgrade'leri bu sabiti 5 ve 7'ye çıkarır; yeni slotlar aktif olur.

### CANCELLED_QUEUE Davranışı

```gdscript
## Sabır bitti: müşteri kapıya yönelir, sonra spawn noktasına çıkar
CANCELLED_QUEUE:
    _release_queue_slot()
    move_to(door_position)
    move_to(spawn_exit_position)
    queue_free()
```

---

## Node Hiyerarşisi

```
BufeScene (Node2D)                    [BufeScene.gd]
├── Camera2D                          [statik, zoom=0.75]
├── GameWorld (Node2D, y_sort=true)
│   ├── Background (Node2D)
│   │   ├── SkyRect (ColorRect)       [arka plan rengi, z=-20]
│   │   └── StreetContainer (Node2D) [kaldırım tile'ları, row 6-7]
│   ├── FloorContainer (Node2D, y_sort=true)
│   │   └── F_{col}_{row} (Sprite2D × 35)  [iç zemin tile'ları]
│   ├── WallContainer (Node2D, y_sort=true)
│   │   ├── BackWall_{0..4} (Sprite2D × 5)   [arka duvar]
│   │   ├── StoveWall_1 (Sprite2D)            [ocak 1 nişi]
│   │   ├── StoveWall_2 (Sprite2D)            [ocak 2 nişi, visible=false]
│   │   ├── LeftWall_Top (Sprite2D × 2)       [sol köşe, kısmen]
│   │   └── RightWall_Top (Sprite2D × 2)      [sağ köşe, kısmen]
│   ├── FurnitureContainer (Node2D, y_sort=true)
│   │   ├── CounterRow (Node2D)
│   │   │   ├── Counter_L (Sprite2D)           [sol uç]
│   │   │   ├── Counter_M (Sprite2D)           [orta]
│   │   │   └── Counter_R (Sprite2D)           [sağ uç]
│   │   ├── OcakContainer (Node2D) %OcakContainer
│   │   │   ├── OcakSlot1 (Node2D) %OcakSlot1  [visible=true]
│   │   │   └── OcakSlot2 (Node2D) %OcakSlot2  [visible=false → KIT_03]
│   │   └── StoolContainer (Node2D, y_sort=true) %StoolContainer
│   │       ├── Stool1 (Sprite2D) %Stool1       [visible=true]
│   │       ├── Stool2 (Sprite2D) %Stool2       [visible=true]
│   │       ├── Stool3 (Sprite2D) %Stool3       [visible=false → CNT_01]
│   │       └── Stool4 (Sprite2D) %Stool4       [visible=false → CNT_02]
│   ├── DoorArea (Node2D)
│   │   └── Door (Sprite2D)
│   ├── QueueArea (Node2D) %QueueArea            [kaldırımda, kapı önü]
│   │   ├── QSlot_1..3 (Marker2D × 3)          [başlangıç — dağınık pozisyonlar]
│   │   ├── QSlot_4..5 (Marker2D × 2)          [CNT_03 ile aktif]
│   │   ├── QSlot_6..7 (Marker2D × 2)          [CNT_04 ile aktif]
│   │   └── StoolSlot_1..4 (Marker2D × 4)      [tabure waypoint'leri]
│   ├── ChefSprite (AnimatedSprite2D) %ChefSprite
│   └── CustomerContainer (Node2D, y_sort=true) %CustomerContainer
├── UILayer (CanvasLayer, layer=10)
│   ├── HUDBar (instanced)
│   ├── RightSidePanel (VBoxContainer)
│   │   ├── Btn_Restaurant (TextureButton)
│   │   ├── Btn_Menu (TextureButton)
│   │   ├── Btn_Upgrade (TextureButton)
│   │   └── Btn_Achievement (TextureButton)
│   ├── ToastContainer (VBoxContainer)
│   ├── CoinFloatLayer (Node2D)
│   ├── UpgradePanel (Control, visible=false)
│   ├── MenuPanel (Control, visible=false)
│   ├── AchievementPanel (Control, visible=false)
│   └── WelcomeModal (instanced, visible=false)
└── Systems (Node)
    ├── CustomerSystem, OrderManager, ChefSystem
    ├── EconomySystem, UpgradeSystem, OfflineSystem
    ├── SaveSystem, ProgressionSystem
    ├── AchievementSystem, SatisfactionSystem
```

---

## Kamera Ayarları

```gdscript
## BufeScene._ready() veya Camera2D inspector ayarları
camera.zoom = Vector2(0.85, 0.85)   ## başlangıç — yakın, mekan küçük görünür
camera.position_smoothing_enabled = false
camera.drag_horizontal_enabled = false
camera.drag_vertical_enabled = false
```

Kamera statik, scroll veya follow yok.

### Dinamik Zoom (upgrade ile)

Mekan büyüdükçe kamera yavaş çekilir (`Tween`, ~0.5 sn):

| Tetikleyici | Zoom |
|-------------|------|
| Başlangıç (2 tabure, 1 ocak) | 0.85 |
| CNT_02 VEYA KIT_03 açıldıktan sonra | 0.75 |
| Level 5 (tüm upgrade'ler) | 0.65 |

`upgrade_purchased` sinyalinde `BufeScene.gd` mevcut upgrade sayısını kontrol eder,
eşik aşıldıysa zoom Tween ile değiştirilir.

---

## Asset Hizalama — Büfe Sahnesine Özgü Notlar

> Genel kurallar: `.claude/rules/visual.md` — Asset Hizalama Kuralları

### Zemin Referansı

Büfe sahnesindeki tüm objeler aynı "zemin düzlemi"nden başlar.
Referans: zemin tile'ının üst yüzeyinin ön merkezi.

```
zemin tile (col, row):
     /▔▔▔\
    /  ·  \   ← bu nokta = iso_to_screen(col, row)
    \     /       tüm objelerin pivot'u buraya hizalanır
     \▄▄▄/
```

### Duvar Sürekliliği

Kuzey duvarı 5 parça (col 0–4), her biri ardışık grid pozisyonunda.
Aynı `WALL_HEIGHT_PX` değeri, aynı offset, aynı scale — aralarında boşluk yok.

```
col: 0      1      2      3      4
    [BW]──[STW]──[BW]──[BW]──[BW]   ← bitişik, boşluksuz
```

Batı ve doğu duvarları da aynı kural: her tile `row+1` pozisyonunda.

### Tezgah (Counter) Sürekliliği

3 parça (col 1–3), birleşik görünüm:

```
col: 1      2      3
    [CNT_L][CNT_M][CNT_R]   ← aynı row, ardışık col, boşluk yok
```

`CNT_L`, `CNT_M`, `CNT_R` farklı sprite olabilir (köşe/orta görünümü için)
ama **aynı yükseklik, aynı offset, aynı scale**.

### Tabure Hizalaması

4 tabure (col 0–3, row 3), hepsi counter'ın hemen önünde:

```
counter → row 2
stools  → row 3 (tam bir tile farkı, pivot noktası aynı)
```

Taburenin üst yüzeyi counter'ın üst yüzeyinden **alçak** olmalı — görsel mantık.

---

## Constants.SPRITES Gereksinimleri

Bu sahne için `Constants.SPRITES` dict'inde bulunması gereken key'ler:

```gdscript
"floor":         "res://assets/sprites/environment/floor.png"
"wall":          "res://assets/sprites/environment/wall.png"
"wall_doorway":  "res://assets/sprites/environment/wall_doorway.png"
"door":          "res://assets/sprites/environment/door_b.png"
"counter":       "res://assets/sprites/environment/counter.png"
"stove":         "res://assets/sprites/environment/stove.png"
"stool":         "res://assets/sprites/environment/chair_stool.png"
"plate":         "res://assets/sprites/environment/plate.png"
```

Tüm sprite yüklemeleri bu key'ler üzerinden yapılır — `res://` path'i script içine yazılmaz.

---

## Upgrade → Görsel Değişim Tablosu

| Upgrade ID | Görsel Değişiklik | Node |
|------------|------------------|------|
| CNT_01 (2. Tabure) | Stool3 visible=true | `%Stool3` |
| CNT_02 (3. Tabure) | Stool4 visible=true | `%Stool4` |
| CNT_03 (Sıra Genişletme 1) | QSlot_4 + QSlot_5 aktif (kaldırımda 2 yeni bekleme noktası) | `%QueueArea/QSlot_4`, `QSlot_5` |
| CNT_04 (Sıra Genişletme 2) | QSlot_6 + QSlot_7 aktif | `%QueueArea/QSlot_6`, `QSlot_7` |
| KIT_03 (İkinci Ocak) | OcakSlot2 visible=true, StoveWall_2 visible=true | `%OcakSlot2` |

Görsel güncellemeler `BufeScene.gd` içinde `EventBus.upgrade_purchased` sinyali
dinlenerek uygulanır. Upgrade sistemi bu node'ları doğrudan çağırmaz.

---

## Atmosfer Notları

- **Arka plan:** Basit sky gradient (CREAM rengi üstü) + kaldırım tile'ları
- **Renk paleti:** `Constants.CREAM` zemin, `Constants.CORAL` aktif UI elemanları
- **Küçük mekan hissi:** Tile sayısı az tutulur; müşteri ve şef animasyonları
  (Sprint 9+) mekanı dolu gösterecek
- **Sokak canlılığı:** Müşteri spawn bölgesi ekran dışında, her gelen karakter
  kaldırımdan yürüyerek giriyor hissi verir

---

*Büfe Sahnesi Tasarım Belgesi v1.0 — Haziran 2026*
*Referans: `docs/bufe_asama_gdd.md` §4, §8 | Kodlama kuralları: `.claude/rules/visual.md`*
