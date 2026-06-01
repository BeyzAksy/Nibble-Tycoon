# autoload/ — Global Sistemler Rehberi

> Autoload dosyaları oyunun her yerinden `Constants.X` veya `EventBus.signal` ile erişilir.
> Bu klasöre minimal şeyler girer — stage-specific logic buraya taşınmaz.

---

## Autoload'a Girmeli mi? Karar Ağacı

```
Her aşamada kullanılır mı?
├── EVET → autoload'a ekle
└── HAYIR → scripts/[stage]/systems/'e ekle

Tüm sistemler bu veriyi paylaşır mı?
├── EVET → Constants.gd (config/sabit) veya EventBus.gd (sinyal)
└── HAYIR → ilgili sistemin içinde tut
```

---

## Constants.gd

### Amaç
Oyunun tek sayısal sabit kaynağı. GDD'nin kod yansımasıdır.

### Ekleme Kuralları

1. **Hiçbir zaman hardcoded değer** script içine yazılmaz
2. **Stage prefix zorunlu:** Büfe sabitleri `BUFFET_`, Kafe `CAFE_`, paylaşılan prefix'siz
3. **Yorum zorunlu:** GDD referans numarası (§X.X) ile
4. **Formül fonksiyonları `static func`** — başka hiçbir dosyaya `static` yazma

```gdscript
## Yeni sabit eklerken:
## GDD §7.3 — Pişirme hızı boost çarpanı
const BOOST_MULTIPLIER := 0.5   ## cooking time ×0.5 (halved)

## Yeni dict entry:
## GDD §2.1 — Müşteri tipleri
"vip": {
    "patience_queue": 20.0,
    "patience_food":  15.0,
    "coin_mult":      2.0,
    ...
}
```

### Planlanan Genişlemeler

| Yapı | Açıklama | Öncelik |
|------|---------|---------|
| `CUSTOMER_TYPES` dict | Tüm müşteri tipleri (şu an inline Constants sabitleri) | Yüksek |
| `ACHIEVEMENTS` dict | Achievement tanımları (GDD §11) | Orta |
| `STAGE_TRANSITIONS` dict | Geçiş koşulları her aşama için | Kafe öncesi |

### Düzenleme Yasağı

- **`MENU_ITEMS` key'leri silinmez** — save dosyasında bu key'ler saklanır, kaldırılırsa eski save bozulur
- **`LEVEL_THRESHOLDS` değerleri azaltılmaz** — mevcut oyuncuların level'ı sıfırlanır
- **Formül fonksiyonları (`calc_*`)** signature değiştirilmez — tüm testler kırılır

---

## EventBus.gd

### Amaç
Sistemler arası gevşek bağlı iletişim merkezi. Hiçbir iş mantığı içermez.

### Sinyal Ekleme Kuralları

1. **İsim:** `event_happened` formatı (geçmiş zaman, ne olduğunu anlat)
2. **Parametre isimleri zorunlu:** `signal order_queued(customer_id: int)` — isimsiz değil
3. **Tip zorunlu:** her parametreye tip yazılır
4. **Yorum:** ne zaman yayıldığı ve kim dinler

```gdscript
## Yeni sinyal eklerken:

## Yayıldığı zaman: Her achievement kilidi açıldığında
## Dinleyenler: AchievementPanel (UI), SaveSystem (kayıt)
signal achievement_unlocked(achievement_id: String)
```

### Var Olan Sinyallerin Değiştirilmesi

Mevcut sinyal silinirse tüm bağlı sistemler patlar. **Hiçbir sinyali silme.**

Parametre değişikliği kırılma değişikliğidir:
- `signal balance_changed(coins: float, gems: int)` → `signal balance_changed(coins: float)` **YASAK**

Geriye uyumlu değişiklik:
- Yeni opsiyonel sinyal ekle (`signal balance_changed_v2(...)`)
- Eski sinyali deprecated olarak işaretle, bir süre ikisini yay

### Sinyal Gruplaması

Sinyaller konularına göre gruplandırılmış yorum blokları ile ayrılır:

```gdscript
# ── SİPARİŞ SİNYALLERİ ───
signal order_queued(customer_id: int)
...

# ── EKONOMİ SİNYALLERİ ───
signal coin_earned(amount: float, source: String)
...

# ── [YENİ KATEGORİ] ───────
signal achievement_unlocked(achievement_id: String)
```

### Planlanan Yeni Sinyaller

| Sinyal | Açıklama | Eklenme zamanı |
|--------|---------|----------------|
| `achievement_unlocked(id)` | Achievement sistemi implementasyonunda | AchievementSystem |
| `satisfaction_changed(score, delta)` | SatisfactionSystem kurulumunda | SatisfactionSystem |
| `stage_transition_ready(from, to)` | Kafe geçişi implementasyonunda | Kafe öncesi |
| `ad_reward_granted(reward_type, value)` | ReklamSystem kurulumunda | Büfe sonu |
| `daily_special_changed(item_id)` | Günün Özelliği Level 5 | Level 5 |

---

## Autoload Kaydı (project.godot)

Autoload sisteme eklenmesi için `project.godot` düzenlenir veya Godot Editor → Project Settings → Autoload:

```ini
[autoload]
Constants="*res://autoload/Constants.gd"
EventBus="*res://autoload/EventBus.gd"
```

Yeni autoload eklenecekse:
1. `autoload/` klasörüne dosyayı ekle
2. `project.godot [autoload]` bölümüne satır ekle
3. Bu dosyayı güncelle (yeni entry için)

**Mevcut autoload'lar:**
- `Constants` — oyun sabitleri
- `EventBus` — sinyal merkezi

**Planlanan autoload'lar:**
- `SaveSystem` — şu an `scripts/systems/` içinde; global erişim için autoload'a taşınabilir
- `ProgressionSystem` — XP/Level yönetimi (OrderManager'dan ayrılacak)
