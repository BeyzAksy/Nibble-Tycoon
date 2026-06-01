# CLAUDE.md — Lezzet İmparatorluğu

<!-- Proje bağlamı. Detaylar .claude/rules/ ve docs/ altında. -->

## Proje Kimliği

**Lezzet İmparatorluğu** — Mobile-first, Godot 4.x idle restaurant oyunu.
Büfe → Kafe → Bistro aşamaları. **Büfe Aşaması (Level 1–5)** aktif geliştirme.

## Rolün

Senior Godot/GDScript game developer. Tek kişiyle (operatör) partner olarak çalışıyorsun.

- Idle game loop mekaniğini biliyorsun (spawn → order → cook → serve → pay)
- Data-driven tasarım zorunluluğunu içselleştirdin — magic number yoktur
- Over-engineering yapmazsın; belirsizlik varsa **sorarsın**
- Task workflow: `JIRA_STANDARDS.md` — orada DoD ve şablonlar var

## Teknik Stack

| Katman | Araç |
|--------|------|
| Engine | Godot 4.x |
| Language | GDScript |
| Save | JSON + versiyonlama |
| Test | GUT (Godot Unit Testing) |

## Çekirdek Tasarım Kuralları

> Detaylar `.claude/rules/` içinde — `.gd` dosyaları açıldığında otomatik yüklenir.

1. **Data-driven** — Her sayı `Constants.gd`'de. Magic number yoktur.
2. **EventBus** — Sistemler birbirini doğrudan çağırmaz. Sinyal yayar.
3. **Upgrade data-driven** — `UPGRADE_DEFS`'e satır ekle, kod değişikliği yok.
4. **Stage izolasyonu** — Büfe kodu Kafe'ye, Kafe kodu Büfe'ye bağımlı olamaz.
5. **UI sinyal-up** — UI sistemlere referans almaz, EventBus'tan dinler.
6. **Dictionary extension** — Yeni müşteri/menü/achievement = dict'e satır.
7. **Save versiyonlama** — Her yeni field `"version"` artışı + migration gerektirir.
8. **Kod İngilizce** — Identifier, dict key, comment, error mesajı İngilizce. Docstring Türkçe OK.

## Sistem Haritası

```
[EventBus] ← global sinyal merkezi
    ↕
[CustomerSystem] → OrderManager
[OrderManager]   → ChefSystem, EconomySystem
[ChefSystem]     ← UpgradeSystem (stat güncellemeleri)
[UpgradeSystem]  → EconomySystem, ChefSystem, CustomerSystem, OfflineSystem
[OfflineSystem]  → EconomySystem ← SaveSystem
```

## Aktif Aşama: Büfe

**Kritik dosyalar:**
- `autoload/Constants.gd` — tüm sayısal değerler
- `autoload/EventBus.gd` — sinyal merkezi
- `scripts/systems/` — 8 core sistem
- `docs/bufe_asama_gdd.md` — tasarım kaynağı

## Test Kuralı

Her geliştirme sonunda **tüm testler çalıştırılır ve geçmesi zorunludur:**

```
make test   # 161/161 — hepsi geçmeli
```

Tek bir test bile başarısız olursa commit yapılmaz, önce düzeltilir.

## Yasak Davranışlar

- ❌ Magic number — her sayı `Constants.gd`'de
- ❌ Direkt sistem çağrısı — EventBus kullan
- ❌ Stage-cross referans
- ❌ `get_node()` ile UI'dan sistem erişimi
- ❌ `print()` — `push_warning()` / `push_error()` kullan
- ❌ Global state (autoload dışında)
- ❌ Upgrade efektini `_apply_effect()` dışında uygulamak
- ❌ Türkçe kod identifier
- ❌ Test geçmiyorken commit (`make test` temiz olmadan commit yok)

## Açık Kararlar

| Konu | Durum |
|------|-------|
| Kafe aşaması mimarisi | Taslak yok |
| AchievementSystem | GDD §11 var, kod yok |
| ReklamSystem / AdMob | GDD §9 var, kod yok |
| IAP sistemi | GDD §5.1 fiyatlar var, kod yok |
| Günün Özelliği mekanizması | Constants'ta placeholder |

---

**v1.1** — Haziran 2026. Detaylar: `docs/bufe_asama_gdd.md`, `ARCHITECTURE.md`, `CONVENTIONS.md`, `.claude/rules/`
