# Lezzet İmparatorluğu — Büfe Aşaması GDD
**Versiyon:** 1.0 | **Motor:** Godot 4.x | **Aşama:** Level 1–5

---

## 1. Genel Bakış

Büfe, oyunun başlangıç aşamasıdır (Level 1–5). Counter-service modeli: masa yok, counter önünde bar tabureleri var. Müşteri gelir → sıraya girer → tabureye oturur → şef pişirir → counter'da teslim → müşteri yer → öder → ayrılır.

**Temel özellikler:**
- Şef Level 1'den itibaren tamamen otonom çalışır (idle mechanic)
- Oyuncunun aktif rolü: upgrade kararları, reklam izleme
- Offline kazanç Level 1'den itibaren aktif (Manager karakteri olmadan)
- Büfe max kapasitesi: 4 tabure, 7 kişi sıra, 2 ocak slotu

---

## 2. Müşteri Tipleri

### 2.1 Genel Tanımlar

| Tip | Unlock | Spawn aralığı | Sıra sabrı | Yemek sabrı | Para etkisi | Sipariş kısıtı |
|---|---|---|---|---|---|---|
| Regular | Level 1 (başlangıç) | 25 sn | 40 sn | 30 sn | Standart | Menüden her şey |
| Aceleci | Level 2 | 30 sn | 18 sn | 15 sn | +%20 coin | Çay, Poğaça, Tost (hızlı items) |
| Turist | Level 3 | 35 sn | 65 sn | 55 sn | +%30 bahşiş | Çay ve Sosisli Sandviç tercih eder |

> **Not:** VIP ve Eleştirmen Büfe aşamasına dahil değildir. VIP → Kafe, Eleştirmen → Bistro.

### 2.2 Sabır Mekaniği

Her müşterinin **iki bağımsız sabır sayacı** vardır:

**Sıra Sabrı**
- Tabure boşalana kadar sırada bekleme toleransı
- Biter → müşteri geri döner, coin kaybı yoktur (fırsat kaybı)
- `patience_timer_queue` → `0` → `CANCELLED_QUEUE`

**Yemek Sabrı**
- Tabureye oturup sipariş verdikten sonra yemek bekleme toleransı
- Biter → öfkeyle ayrılır, ödeme yapmaz, memnuniyet −10 puan
- `patience_timer_food` → `0` → `CANCELLED_ANGRY`

### 2.3 Duygu Durumları

3 durum (5 değil). Duygu ikonları bahşiş ekonomisini temsil eder:

| Durum | Sabır eşiği | Görsel | Bahşiş çarpanı |
|---|---|---|---|
| Mutlu | > %65 | Yeşil bar, gülümseyen ikon | 1.0× |
| Nötr | %35 – %65 | Sarı bar, düz yüz | 0.6× |
| Sinirli | < %35 | Kırmızı bar + titreme animasyonu | 0.2× |
| İptal | %0 | Kalkar, gider | 0 coin |

---

## 3. Menü

### 3.1 Ürün Listesi

| Item | Fiyat (₺) | Pişirme süresi | Unlock | Kim ısmarlar |
|---|---|---|---|---|
| Çay | 25 | 8 sn | Level 1 — başlangıç | Herkes |
| Poğaça | 40 | 12 sn | Level 1 — başlangıç | Herkes |
| Tost | 65 | 15 sn | Level 2 — 600₺ ödeyerek açılır | Regular, Aceleci |
| Sosisli Sandviç | 75 | 14 sn | Level 3 — 2.000₺ ödeyerek açılır | Regular, Aceleci, Turist |
| Günün Özelliği | mevcut item × 1.3 | aynı item süresi | Level 5 — otomatik açılır | Herkes |

### 3.2 Günün Özelliği

- Her gün (cihaz saatine göre 00:00 sıfırlanır) mevcut menüden rastgele bir item seçilir
- Seçilen item o gün %30 yüksek fiyatla sunulur
- Oyuncuya bildirim gönderilir (daily retention mekanizması)
- Level 5'te otomatik açılır, ek unlock maliyeti yoktur

---

## 4. Mekan Yerleşimi

```
[KAPISI]  ← müşteriler soldan girer
[ SİRA ]  → sağa uzanır (max 7 kişi)
[TEZGAH / COUNTER]
[ŞEF] [OCAK 1] [OCAK 2]  ← counter arkasında
```

- **Counter önü:** 2–4 bar taburesi (upgrade ile artar, max 4)
- **Sıra:** Counter'ın solunda dışarıya uzanır (max 7 kişi)
- **Görünüm:** Top-down view, sokak büfesi tarzı
- **Zemin:** Kirpi desenli seramik, bej/beyaz TileMap 32px
- **Dekor:** Saksı bitki, duvarda çerçeveli tablo, tabela

---

## 5. Para Sistemi

### 5.1 Para Birimleri

**Coin (₺) — ana para birimi**

| Giriş (IN) | Çıkış (OUT) |
|---|---|
| Sipariş bedeli | Upgrade satın alma |
| Bahşiş | Menü unlock |
| Offline kazanç | Sıra genişletme |
| Reklam ödülleri | — |
| Achievement ödülleri | — |

**Gem (💎) — premium para**

| Giriş (IN) | Çıkış (OUT) |
|---|---|
| Milestone achievement'lar (1–5 💎) | Hız Bostu 5dk → 5💎 veya reklam izle |
| IAP: $0.99 = 50💎 | Tek item skip → 2💎 veya reklam izle |
| IAP: $4.99 = 300💎 | Ekstra offline saat → 10💎 veya 2 reklam |
| Nadir premium reklam (3 izle = 1💎) | İptal eden müşteriyi geri getir → 5💎 veya reklam |

### 5.2 Ekonomi Formülleri

```
order_value    = base_price × (1 + chef_quality × 0.04)
tip            = base_price × patience_ratio × 0.15 + chef_quality × 0.04
patience_ratio = kalan_sabir / max_sabir   # 0.0 → 1.0
```

### 5.3 Level Bazında Ekonomi (tüm upgrade'lar aktifken)

| Level | Aktif (₺/dk) | Offline/saat | Max offline | Offline toplam | 2× reklam ile |
|---|---|---|---|---|---|
| 1 | 75 | 1.350 | 4 saat | 5.400₺ | 10.800₺ |
| 2 | 130 | 2.574 | 6 saat | 15.444₺ | 30.888₺ |
| 3 | 210 | 4.788 | 8 saat | 38.304₺ | 76.608₺ |
| 4 | 300 | 7.560 | 10 saat | 75.600₺ | 151.200₺ |
| 5 | 415 | 11.205 | 12 saat | 134.460₺ | 268.920₺ |

---

## 6. Sipariş Durum Makinası

```
QUEUED (sırada bekliyor)
    ├─ tabure boşaldı              → SEATED
    └─ sıra sabrı bitti            → CANCELLED_QUEUE   # kayıp yok

SEATED (oturdu, sipariş otomatik gönderildi)
    ├─ şef slotu müsait            → COOKING
    └─ yemek sabrı bitti           → CANCELLED_ANGRY   # ödeme yok, −10 memnuniyet

COOKING (şef pişiriyor)
    └─ timer tamamlandı            → READY             # counter'a konuldu

READY (counter'da hazır)
    └─ müşteri alır (2–3 sn, otomatik) → EATING

EATING (yiyor, tabure meşgul)
    └─ yeme timer bitti            → DONE + coin + tip kazanılır

DONE → müşteri ayrılır, tabure serbest kalır, spawn döngüsü devam eder
```

**Signal listesi (Godot için):**
- `order_queued(customer_id)`
- `order_seated(customer_id)`
- `order_cooking(customer_id, item_id)`
- `order_ready(customer_id, item_id)`
- `order_served(customer_id)`
- `order_cancelled(customer_id, reason)` — reason: `"queue"` | `"angry"`

---

## 7. Şef (Büfeci) Sistemi

### 7.1 Görev Tanımı

Şef Level 1'den itibaren tamamen otonom çalışır. Oyuncu tap etmez.

**Sorumluluklar:**
1. Sıradaki siparişi almak (FIFO)
2. Pişirme timerını çalıştırmak
3. Hazır yemeği counter'a koymak
4. İkinci slot açıksa iki siparişi paralel işlemek

### 7.2 Aksiyon Döngüsü (GDScript pseudocode)

```gdscript
func _process(delta):
    check_timer += delta
    if check_timer >= 0.5:
        check_timer = 0.0
        _try_take_order()

func _try_take_order():
    for slot in cooking_slots:
        if slot.is_empty() and order_queue.size() > 0:
            var order = _get_next_order()   # FIFO veya priority bump
            slot.start_cooking(order)

func _get_next_order():
    # Şef Deneyimi 4 unlock'u ile Aceleci priority bump
    if chef_level >= 4:
        for i in order_queue.size():
            var o = order_queue[i]
            if o.customer_type == "Aceleci" and o.food_patience_ratio < 0.25:
                return order_queue.pop_at(i)
    return order_queue.pop_front()   # default FIFO

func _on_cooking_complete(slot, order):
    counter.place_item(order)
    emit_signal("order_ready", order.customer_id, order.item_id)
    slot.clear()
    _try_take_order()
```

### 7.3 Pişirme Hızı Hesabı

```
effective_cook_time = base_cook_time / speed_multiplier
```

| Upgrade durumu | speed_multiplier |
|---|---|
| Başlangıç (no upgrade) | 1.00 |
| Ocak Hızı 1 | 1.15 |
| Ocak Hızı 1 + 2 | 1.30 |
| + Şef Deneyimi 1 | +%10 |
| + Şef Deneyimi 2 | +%10 |
| + Şef Deneyimi 3 | +%10 |
| Şef Ustalaşma (Lv5) | +%20 ek (büfe itemlarına özel) |

### 7.4 Şef Kalite Değeri

`chef_quality` upgrade'lerle artar ve hem `order_value` hem `tip` formüllerini etkiler.

| Upgrade | chef_quality değişimi |
|---|---|
| Başlangıç | 1 |
| Şef Deneyimi 1 | +1 → 2 |
| Şef Deneyimi 2 | +1 → 3 |
| Şef Deneyimi 3 | +1 → 4 |
| Şef Deneyimi 4 | +2 → 6 |
| Şef Ustalaşma | +2 → 8 |

---

## 8. Upgrade Ağacı

### 8.1 Mutfak

| ID | Upgrade Adı | Maliyet | Unlock Koşulu | Etki |
|---|---|---|---|---|
| KIT_01 | Ocak Hızı 1 | 300₺ | Level 1 | pişirme süresi −15% (speed_mult +0.15) |
| KIT_02 | Ocak Hızı 2 | 1.200₺ | Level 2 | pişirme süresi −15% daha |
| KIT_03 | İkinci Ocak Slotu | 3.500₺ | Level 3 | 2 item paralel pişirme |
| KIT_04 | Malzeme Kalitesi 1 | 8.000₺ | Level 4 | tip çarpanı +%8 |
| KIT_05 | Özel Tarif | 20.000₺ | Level 5 | tüm item base_price +%15 |

### 8.2 Tezgah / Kapasite

| ID | Upgrade Adı | Maliyet | Unlock Koşulu | Etki |
|---|---|---|---|---|
| CNT_01 | 2. Tabure | 250₺ | Level 1 | max_stools: 2 → 3 |
| CNT_02 | 3. Tabure | 900₺ | Level 2 | max_stools: 3 → 4 (Büfe max) |
| CNT_03 | Sıra Genişletme 1 | 700₺ | Level 2 | max_queue: 3 → 5 |
| CNT_04 | Sıra Genişletme 2 | 4.000₺ | Level 4 | max_queue: 5 → 7 |

### 8.3 Şef

| ID | Upgrade Adı | Maliyet | Unlock Koşulu | Etki |
|---|---|---|---|---|
| CHF_01 | Şef Deneyimi 1 | 400₺ | Level 1 | hız +10%, chef_quality +1 |
| CHF_02 | Şef Deneyimi 2 | 1.500₺ | Level 2 | hız +10%, chef_quality +1 |
| CHF_03 | Şef Deneyimi 3 | 4.000₺ | Level 3 | hız +10%, chef_quality +1 |
| CHF_04 | Şef Deneyimi 4 | 10.000₺ | Level 4 | chef_quality +2, Aceleci priority bump aktif |
| CHF_05 | Şef Ustalaşma | 25.000₺ | Level 5 | büfe items −%20 süre, chef_quality +2 |

### 8.4 Offline / Idle

| ID | Upgrade Adı | Maliyet | Unlock Koşulu | Etki |
|---|---|---|---|---|
| IDL_01 | Offline Paketi 1 | 500₺ | Level 2 | max_offline_hours: 4 → 6 |
| IDL_02 | Offline Paketi 2 | 2.000₺ | Level 3 | max_offline_hours: 6 → 8, verim +4% |
| IDL_03 | Offline Verim Artışı 1 | 3.000₺ | Level 3 | offline_efficiency +5% |
| IDL_04 | Offline Paketi 3 | 7.000₺ | Level 4 | max_offline_hours: 8 → 10 |
| IDL_05 | Offline Paketi 4 | 15.000₺ | Level 5 | max_offline_hours: 10 → 12, verim +3% |
| IDL_06 | Offline Verim Artışı 2 | 12.000₺ | Level 5 | offline_efficiency +5% (büfe max: %45) |

### 8.5 Menü Unlock

| ID | Item | Maliyet | Unlock Koşulu |
|---|---|---|---|
| MNU_01 | Tost | 600₺ | Level 2 tamamlandıktan sonra |
| MNU_02 | Sosisli Sandviç | 2.000₺ | Level 3 tamamlandıktan sonra |

---

## 9. Reklam Mekanikleri

Tüm reklamlar **rewarded (gönüllü)** — hiçbiri zorla gösterilmez.

### 9.1 2× Offline Bonus (en yüksek değer)
- **Tetikleyici:** Hoş Geldin ekranında offline kazancı toplarken
- **Etki:** Hesaplanan offline_earnings × 2
- **Frekans:** Her offline toplamada 1 kez
- **Gem alternatifi:** Yok (sadece reklam)

### 9.2 Hız Bostu
- **Tetikleyici:** Şefin yanındaki "Boost" butonu
- **Etki:** Tüm pişirme süreleri −%50, süre: 5 dakika
- **Cooldown:** 15 dakika
- **Gem alternatifi:** 5💎

### 9.3 Coin Paketi
- **Tetikleyici:** Coin sayacının yanındaki "+" butonu
- **Etki:** Anlık saatlik kazancın %10'u kadar coin
- **Frekans:** Günde 3 kez, her arasında 30dk cooldown
- **Gem alternatifi:** Yok (sadece reklam)

### 9.4 Acele Pişir
- **Tetikleyici:** Pişmekte olan item'a uzun basma
- **Etki:** O item'ın kalan pişirme süresi sıfırlanır
- **Frekans:** Session'da 3 kez
- **Gem alternatifi:** 2💎

### 9.5 Interstitial Kuralları
- Yalnızca **Büfe → Kafe aşama geçişinde** gösterilir
- Oyun içinde, aşama ortasında **asla** gösterilmez
- Minimum session süresi: 3 dakika geçmeden gösterilmez

---

## 10. Offline Ekonomi Sistemi

### 10.1 Temel Ayrım

| Kavram | Ne zaman çalışır | Karakter gereksinimi |
|---|---|---|
| **Idle** | Oyun AÇIKKEN | Yok — şef zaten otonom |
| **Offline** | Oyun KAPALI iken | Yok — Büfe'de Manager karakteri yok |

> Manager karakteri Bistro aşamasında kiralanan ilk idle karakterdir.
> Büfe'de temel offline formül çalışır, Manager bonusu yoktur.

### 10.2 Kayıt Sistemi

**Oyun kapanırken:**
```gdscript
func _on_game_close():
    save_data.close_timestamp = Time.get_unix_time_from_system()
    save_data.hourly_rate = _calculate_hourly_rate()
    save_data.offline_efficiency = _get_current_offline_efficiency()
    save_data.max_offline_hours = _get_max_offline_hours()
    SaveSystem.save(save_data)
```

**Oyun açılırken:**
```gdscript
func _on_game_open():
    var elapsed_seconds = Time.get_unix_time_from_system() - save_data.close_timestamp
    var elapsed_hours = elapsed_seconds / 3600.0
    var offline_hours = min(elapsed_hours, save_data.max_offline_hours)
    var earnings = save_data.hourly_rate * offline_hours * save_data.offline_efficiency
    WelcomeScreen.show(earnings)   # 2× reklam teklif eder
```

### 10.3 Saatlik Kazanç Formülü

```
hourly_rate = (3600 / spawn_interval)
            × avg_order_value
            × (1 + chef_quality × 0.04)
            × stool_utilization      # sabit: 0.75
            × food_cost_factor       # sabit: 0.70
```

### 10.4 Offline Verim Tablosu

| Level | offline_efficiency | max_offline_hours | Upgrade'ler aktifken toplam |
|---|---|---|---|
| 1 | 0.30 | 4 saat | 5.400₺ |
| 2 | 0.33 | 6 saat | 15.444₺ |
| 3 | 0.38 | 8 saat | 38.304₺ |
| 4 | 0.42 | 10 saat | 75.600₺ |
| 5 | 0.45 | 12 saat | 134.460₺ |

### 10.5 Örnek Hesaplama (Level 3)

```
spawn_interval    = 20 sn → 180 müşteri/saat
avg_order_value   = 59₺ (kalite çarpanı dahil)
hourly_gross      = 180 × 59 = 10.620₺
× food_cost       = 10.620 × 0.70 = 7.434₺
× stool_util      = 7.434 × 0.75 = 5.576₺/saat
× offline_eff     = 5.576 × 0.38 = 2.119₺/saat

8 saat offline    → 16.950₺
2× reklam ile     → 33.900₺
```

---

## 11. Achievement Sistemi

| ID | Başarım Adı | Koşul | Ödül | Gizli? | Level Penceresi |
|---|---|---|---|---|---|
| ACH_01 | İlk Sipariş | 1 sipariş tamamla | 100₺ + rozet | Hayır | Lv1 |
| ACH_02 | İlk Yükseltme | İlk upgrade'i satın al | 200₺ + 2💎 | Hayır | Lv1 |
| ACH_03 | Hızlı Aşçı | 5 siparişi 3 dakika içinde servis et | 300₺ | Hayır | Lv1–2 |
| ACH_04 | Sıfır İptal | 20 siparişi arka arkaya iptal olmadan tamamla | 500₺ + dekor item | Hayır | Lv2–3 |
| ACH_05 | İlk Uyku | 2 saat offline bekle | 1💎 + offline kalıcı +%5 | Hayır | Lv2 |
| ACH_06 | Çay Ustası | 50 çay servis et | 300₺ + çay pişirme −%10 kalıcı | Hayır | Lv2–3 |
| ACH_07 | Tam Dolu | Tüm tabure + sıra aynı anda dolu | 500₺ | Hayır | Lv3–4 |
| ACH_08 | Menü Tamamlandı | 4 menü itemının tümünü aç | 1.000₺ + 5💎 | Hayır | Lv3 |
| ACH_09 | Büfe Emektarı | 500 sipariş tamamla | 2.000₺ + "Büfe Ustası" unvanı | Hayır | Lv5 |
| ACH_10 | Gece Kuşu | Gece 00:00–02:00 arası 20 sipariş tamamla | Gizli şef kostümü | **Evet** | Herhangi |

**Kalıcı bonuslar not:** ACH_05 ve ACH_06'nın ödülleri kalıcıdır — save dosyasına `permanent_bonus` olarak kaydedilmeli, prestige sıfırlamasından etkilenmemeli.

---

## 12. Level İlerleme Sistemi

### 12.1 XP ve Level Eşikleri

| Level | Gerekli sipariş (toplam) | Bu levelde açılan |
|---|---|---|
| 1 | 0 (başlangıç) | Regular müşteri, Çay, Poğaça |
| 2 | 30 | Aceleci müşteri, Tost unlock mevcut |
| 3 | 100 | Turist müşteri, Sosisli Sandviç unlock mevcut |
| 4 | 250 | Gelişmiş upgrade'ler açılır |
| 5 | 500 | Tüm Büfe upgrade'leri, Günün Özelliği, Kafe geçişi |

> **XP kaynağı:** Her tamamlanan sipariş (DONE durumuna ulaşan) +1 XP verir.
> İptal olan siparişler XP vermez.

### 12.2 Kafe'ye Geçiş Koşulu

```
level == 5
AND total_orders_completed >= 500
AND coins >= 5000   # geçiş ücreti
```

Geçiş sırasında 1 interstitial reklam gösterilir.

---

## 13. Sistem Bağımlılık Haritası (Godot Autoload)

```
CustomerSystem
    → OrderManager           (yeni sipariş sinyal: order_queued)

OrderManager
    → ChefSystem             (sipariş iletilir: start_cooking)
    → EconomySystem          (order_served signal: coin + tip)
    → SatisfactionSystem     (order_cancelled signal: score down)

ChefSystem
    → OrderManager           (order_ready signal)
    ← UpgradeSystem          (speed_multiplier, chef_quality, slot_count)

UpgradeSystem
    → EconomySystem          (spend_coins call)
    → ChefSystem             (stat update)
    → CustomerSystem         (spawn_interval update)
    → OfflineSystem          (offline_efficiency update)

OfflineSystem
    → EconomySystem          (offline earnings added)
    ← SaveSystem             (close_timestamp, hourly_rate read)

AdSystem
    → EconomySystem          (bonus coins added)
    → OfflineSystem          (2× multiplier triggered)

SaveSystem
    ↔ Tüm sistemler          (serialize / deserialize)
```

---

## 14. Önemli Sabitler

```gdscript
# Buffet capacities
const BUFFET_MAX_STOOLS       = 4
const BUFFET_MAX_QUEUE        = 7
const BUFFET_MAX_COOKING_SLOTS = 2

# Offline sistem
const STOOL_UTILIZATION     = 0.75
const FOOD_COST_FACTOR      = 0.70
const MIN_OFFLINE_EFFICIENCY = 0.30
const MAX_OFFLINE_EFFICIENCY = 0.45  # Buffet max

# Tip calculation
const TIP_PATIENCE_MULT     = 0.15
const TIP_QUALITY_MULT      = 0.04
const ORDER_QUALITY_MULT    = 0.04

# Eating duration (same for all items)
const EATING_DURATION_SEC   = 15.0

# Auto-pickup delay for customer (READY → EATING)
const PICKUP_DELAY_SEC      = 2.5
```

---

*Lezzet İmparatorluğu GDD — Büfe Aşaması v1.0*
*Bu belge Claude ile birlikte hazırlanmıştır.*
