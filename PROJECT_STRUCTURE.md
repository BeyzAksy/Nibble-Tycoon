# PROJECT_STRUCTURE.md — Dosya Ağacı

> Mevcut yapı + hedef yapı. Her dosyanın nereye gittiğini buradan öğren.
> Yeni dosya eklemeden önce bu belgeyi güncelle.

---

## Mevcut Yapı (Büfe Aşaması, Aktif)

```
restourant-idle-ui/
├── CLAUDE.md                        ← bu projenin AI rehberi
├── CONVENTIONS.md                   ← GDScript kod standartları
├── ARCHITECTURE.md                  ← mimari kararlar
├── PROJECT_STRUCTURE.md             ← bu dosya
│
├── project.godot                    ← Godot proje tanımı
│
├── autoload/                        ← CLAUDE.md var
│   ├── Constants.gd                 ← tüm oyun sabitleri (tek kaynak)
│   └── EventBus.gd                  ← global sinyal merkezi
│
├── scripts/
│   ├── systems/                     ← CLAUDE.md var
│   │   ├── ChefSystem.gd            ← otonom pişirme motoru
│   │   ├── CustomerSystem.gd        ← müşteri spawn + sabır
│   │   ├── EconomySystem.gd         ← coin/gem management
│   │   ├── OfflineSystem.gd         ← offline kazanç
│   │   ├── OrderManager.gd          ← sipariş state machine
│   │   ├── SaveSystem.gd            ← JSON kayıt/yükleme
│   │   └── UpgradeSystem.gd         ← upgrade ağacı
│   └── ui/                          ← CLAUDE.md var
│       ├── AchievementPanel.gd      ← achievement listesi (UI)
│       ├── BottomNav.gd             ← alt navigasyon bar
│       ├── CoinFloat.gd             ← para animasyonu
│       ├── HUDBar.gd                ← üst durum çubuğu
│       ├── MenuPanel.gd             ← menü unlock paneli
│       ├── ToastManager.gd          ← geçici bildirim
│       ├── UpgradePanel.gd          ← upgrade satın alma UI
│       └── WelcomeModal.gd          ← offline kazanç modal
│
├── scenes/
│   ├── BufeScene.tscn               ← ana büfe sahnesi
│   ├── BufeScene.gd                 ← büfe orkestrasyon script'i
│   ├── CustomerNode.tscn            ← müşteri prefab
│   ├── CustomerNode.gd              ← müşteri yaşam döngüsü
│   ├── StoveSlot.tscn               ← stove slot component (TODO: move to scene)
│   ├── StoveSlot.gd                 ← stove slot logic
│   ├── SplashScreen.tscn            ← giriş ekranı
│   ├── SplashScreen.gd              ← giriş script'i
│   ├── systems/                     ← (boş — sistemler scripts/'ta)
│   └── ui/
│       ├── BottomNav.tscn
│       ├── HUDBar.tscn
│       └── WelcomeModal.tscn
│
├── assets/
│   ├── fonts/
│   │   ├── Fredoka-SemiBold.ttf
│   │   └── Nunito-*.ttf
│   └── sprites/
│       └── ui/
│           └── icon.svg
│
├── theme/                           ← Godot theme resource'ları
│
├── tests/
│   ├── README_TESTS.md              ← GUT kurulum kılavuzu
│   ├── unit/
│   │   ├── test_constants.gd
│   │   ├── test_economy_system.gd
│   │   ├── test_upgrade_system.gd
│   │   ├── test_order_manager.gd
│   │   ├── test_chef_system.gd
│   │   ├── test_offline_system.gd
│   │   └── test_save_system.gd
│   └── integration/
│       └── test_bufe_loop.gd
│
└── docs/
    ├── bufe_asama_gdd.md            ← Büfe GDD (aktif)
    └── lezzet_prototype_v3.html     ← UI prototype referans
```

---

## Hedef Yapı (Çok Aşamalı, İleride)

Büfe tamamlandığında ve Kafe aşaması başladığında yapı şöyle genişleyecek:

```
restourant-idle-ui/
│
├── autoload/                        ← sadece global sistemler
│   ├── Constants.gd                 ← tüm stage sabitleri (BUFE_, KAFE_, BISTRO_)
│   ├── EventBus.gd                  ← global sinyal merkezi (büyüyecek)
│   ├── SaveSystem.gd                ← JSON + versiyon migration
│   └── ProgressionSystem.gd        ← level/XP/achievement (ayrı sistem)
│
├── scripts/
│   ├── shared/                      ← stage'ler arası paylaşılan utility
│   │   ├── CustomerConfig.gd        ← CUSTOMER_TYPES data (Constants'tan ayrı)
│   │   ├── MenuConfig.gd            ← MENU_ITEMS data (büyüyünce ayrı)
│   │   └── AchievementSystem.gd    ← GDD §11 implementasyonu
│   │
│   ├── bufe/                        ← büfe'ye özel sistemler
│   │   ├── systems/                 ← mevcut systems/ buraya taşınır
│   │   │   ├── ChefSystem.gd
│   │   │   ├── CustomerSystem.gd
│   │   │   ├── EconomySystem.gd
│   │   │   ├── OfflineSystem.gd
│   │   │   ├── OrderManager.gd
│   │   │   └── UpgradeSystem.gd
│   │   └── ui/
│   │       └── (büfe UI bileşenleri)
│   │
│   └── kafe/                        ← kafe'ye özel sistemler
│       ├── systems/
│       │   ├── TableSystem.gd       ← masa yönetimi
│       │   ├── WaiterSystem.gd      ← garson otomasyon
│       │   └── ReservationSystem.gd ← rezervasyon
│       └── ui/
│           └── (kafe UI bileşenleri)
│
├── scenes/
│   ├── splash/
│   │   └── SplashScreen.tscn
│   ├── bufe/                        ← tüm büfe sahneleri
│   │   ├── BufeScene.tscn
│   │   ├── CustomerNode.tscn
│   │   ├── StoveSlot.tscn
│   │   └── ui/
│   │       ├── HUDBar.tscn
│   │       ├── UpgradePanel.tscn
│   │       ├── WelcomeModal.tscn
│   │       ├── MenuPanel.tscn
│   │       └── BottomNav.tscn
│   └── kafe/                        ← kafe sahneleri (ileride)
│       └── KafeScene.tscn
│
├── tests/
│   ├── unit/
│   │   ├── bufe/
│   │   │   └── (mevcut testler)
│   │   └── shared/
│   │       └── test_achievement_system.gd
│   └── integration/
│       ├── test_bufe_loop.gd
│       └── test_kafe_loop.gd        ← ileride
│
└── docs/
    ├── bufe_asama_gdd.md            ← aktif
    ├── kafe_asama_gdd.md            ← ileride
    └── bistro_asama_gdd.md          ← ileride
```

---

## Nereye Ne Gider? (Hızlı Referans)

| Durum | Nereye |
|-------|--------|
| Yeni oyun sabiti | `autoload/Constants.gd` |
| Yeni global sinyal | `autoload/EventBus.gd` |
| Yeni büfe sistemi | `scripts/systems/` (şimdi), `scripts/bufe/systems/` (ileride) |
| Yeni UI bileşeni | `scripts/ui/` + `scenes/ui/` (tscn) |
| Yeni müşteri prefab davranışı | `CustomerNode.gd` |
| Yeni ocak/counter davranışı | `StoveSlot.gd` |
| Yeni upgrade efekti | `UpgradeSystem._apply_effect()` |
| Yeni upgrade tanımı | `UpgradeSystem.UPGRADE_DEFS` dict |
| Yeni menü item | `Constants.MENU_ITEMS` dict |
| Yeni müşteri tipi | `Constants.CUSTOMER_TYPES` dict (planlandı) |
| Yeni achievement | `Constants.ACHIEVEMENTS` dict (planlandı) |
| Yeni save field | `SaveSystem` + versiyon++ + migration fonksiyonu |
| Unit test | `tests/unit/test_[sistem].gd` |
| Integration test | `tests/integration/test_[flow].gd` |
| GDD dokümanı | `docs/[aşama]_gdd.md` |

---

## Bekleyen Taşımalar (Refactor Queue)

| Mevcut | Hedef | Öncelik |
|--------|-------|---------|
| `scenes/StoveSlot.gd` | `scripts/systems/` veya scene altı | Orta |
| Sahne/script birlikte `scenes/` kökünde | `scenes/bufe/` altına | Kafe öncesi |
| Inline XP/level logic (OrderManager) | `ProgressionSystem.gd` | Orta |
| Müşteri tipi string'leri | `Constants.CUSTOMER_TYPES` dict | Yüksek |
| `SatisfactionSystem` eksik | Yeni sistem oluştur | Yüksek |
| `AchievementSystem` eksik | Yeni sistem oluştur | Orta |
