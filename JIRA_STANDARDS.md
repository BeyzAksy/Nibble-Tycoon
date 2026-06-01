# JIRA_STANDARDS.md — Lezzet İmparatorluğu PM Standartları

> Her Jira issue bu dosyadaki şablona uygun yazılır.
> Hem Claude Code hem Cursor bu dosyayı okur. Tutarlılık buradan gelir.

---

## 1. Proje Bilgisi

| Alan | Değer |
|------|-------|
| Jira Project Key | `LI` |
| Project Type | Scrum |
| Sprint Uzunluğu | 2 hafta (varsayılan) |
| Velocity Hedefi | ~30 SP / sprint (solo geliştirici) |
| Aktif Aşama | Büfe (Level 1–5) |

---

## 2. Epic Kataloğu

Yeni epic açılmadan önce buradan kontrol et — mevcut epic'e bağla.

| Epic Key | Epic Adı | Kapsam | Durum |
|----------|----------|--------|-------|
| `LI-CORE-LOOP` | Sipariş Döngüsü | spawn → queue → seat → cook → serve → pay → done | Aktif |
| `LI-CUSTOMER` | Müşteri Sistemi | Customer types, patience timers, emotion states | Aktif |
| `LI-CHEF` | Şef & Mutfak | Otonom pişirme, cooking slots, hız hesabı | Aktif |
| `LI-UPGRADE` | Upgrade Ağacı | KIT/CNT/CHF/IDL/MNU upgrade'leri, UI | Aktif |
| `LI-ECONOMY` | Ekonomi Sistemi | Coin/gem kazanma/harcama, formüller, HUD | Aktif |
| `LI-OFFLINE` | Offline Kazanç | Close/open hesabı, hourly_rate, WelcomeModal | Aktif |
| `LI-MENU` | Menü & Ürünler | Menu items, unlock flow, Günün Özelliği | Aktif |
| `LI-UI` | UI & Animasyonlar | HUDBar, panels, transitions, coin float | Aktif |
| `LI-SAVE` | Save Sistemi | JSON serialize/deserialize, versiyonlama, migration | Aktif |
| `LI-ACHIEVEMENT` | Achievement Sistemi | ACH_01–10, ödüller, kalıcı bonuslar | Beklemede |
| `LI-PROGRESSION` | Level & İlerleme | XP, level eşikleri, Kafe geçiş koşulu | Aktif |
| `LI-ADS` | Reklam Mekanikleri | 2× offline, hız bostu, coin paketi, acele pişir | Beklemede |
| `LI-QA` | Bug & Polish | Regression fixler, visual polish, performance | Sürekli |

---

## 3. Issue Tipleri ve Story Point Kılavuzu

| Tip | Ne Zaman | SP Aralığı |
|-----|----------|------------|
| **Epic** | Büyük özellik ailesi | — |
| **Story** | Oyuncu değeri yaratan özellik | 3–13 SP |
| **Task** | Teknik iş, refactor, setup | 1–8 SP |
| **Bug** | Mevcut davranışın kırılması | 1–5 SP |
| **Spike** | Araştırma, belirsizliği kaldırma | 2–4 SP |

**SP Referansı:**
- 1 SP = ~1–2 saat net iş
- 3 SP = ~4–6 saat (yarım gün)
- 5 SP = ~1 tam gün
- 8 SP = ~2 gün
- 13 SP = ~3–4 gün (bölün)

> 13 SP'yi geçen issue bölünür. Tek sprint'te bitmeyecek iş sprint'e girmez.

---

## 4. Story/Task Yazım Şablonu

Her Story ve Task şu yapıya uyar. Hiçbir alan atlanamaz.

```
## Context
[Oyuncu/sistem perspektifinden 2–3 cümle. Bu iş neden yapılıyor, hangi problemi çözüyor?
Teknik detay değil — oyun deneyimi veya sistem ihtiyacı odaklı.]

## Business Rules
[Değişmez kurallar. Her madde test edilebilir, ölçülebilir.
Belirsizlik yoktur — "yaklaşık", "genellikle" gibi kelimeler kullanılmaz.]

- BR-01: [kural]
- BR-02: [kural]
- BR-03: [kural]

## Flow
[Happy path — adım adım ne olur?]

1. [tetikleyici / ön koşul]
2. [sistem ne yapar]
3. [kullanıcıya / sisteme ne görünür]
4. [sonuç durumu]

**Edge Cases:**
- [edge case 1] → [beklenen davranış]
- [edge case 2] → [beklenen davranış]

## Acceptance Criteria
[Bu issue "Done" sayılmadan önce tüm kriterler geçmeli.]

- [ ] AC-01: [ölçülebilir kriter]
- [ ] AC-02: [ölçülebilir kriter]
- [ ] AC-03: GUT testi yazıldı ve geçiyor
- [ ] AC-04: Linter hatasız

## Technical Notes
[Sadece non-obvious kısıtlar, mimari kararlar, dikkat edilmesi gereken bağımlılıklar.
"Nasıl yapılır" değil, "nelere dikkat et".]

- [not]

## Out of Scope
[Bu issue'da yapılmayacaklar. Scope creep önleme.]

- [kapsam dışı item]

## Dependencies
[Bu issue başlamadan önce tamamlanması gereken diğer issue'lar.]

- LI-XXX: [bağımlı issue]

## Epic Link
[LI-EPIC-ADI]
```

---

## 5. Bug Yazım Şablonu

```
## Summary
[Tek satır: Ne kırık, nerede, ne olması gerekiyor?]
Örn: "CustomerSystem: Aceleci müşteri sıra sabrı bitmeden ayrılıyor"

## Environment
- Godot Version: [4.x.x]
- Platform: [Android / iOS / Desktop]
- Level: [hangi levelde?]
- Tekrar eden mi?: [Her seferinde / Bazen / Bir kere]

## Steps to Reproduce
1. [adım]
2. [adım]
3. [adım]

## Expected Behavior
[Ne olması gerekiyor?]

## Actual Behavior
[Ne oluyor?]

## Root Cause Hypothesis
[Varsa: hangi dosya/fonksiyon, hangi state sorunu?]

## Severity
- [ ] **P1 — Critical**: Oyun açılmıyor / core loop kırık
- [ ] **P2 — High**: Önemli özellik çalışmıyor, workaround yok
- [ ] **P3 — Medium**: Özellik çalışıyor ama hatalı davranış
- [ ] **P4 — Low**: Visual/UX sorunu, oynanabilirliği etkilemiyor

## Related Files
- [dosya:satır veya sistem adı]

## Epic Link
LI-QA
```

---

## 6. Sprint Planlama Kriterleri

### Öncelik Sıralaması (MoSCoW)

| Öncelik | Tanım | Sprint'e Girer mi? |
|---------|-------|-------------------|
| **Must Have** | Core loop çalışmıyor bu olmadan | Her zaman |
| **Should Have** | Önemli ama workaround var | Kapasite varsa |
| **Could Have** | İyi olur ama ertelenebilir | Backlog |
| **Won't Have** | Bu sprintte yapılmayacak | Backlog (gelecek) |

### Sprint'e Alınma Koşulları

Issue sprint'e girmeden önce:
- [ ] Şablon tam dolu (Context, BR, Flow, AC, Out of Scope)
- [ ] Epic'e bağlı
- [ ] SP tahmin edilmiş
- [ ] Bağımlılıklar çözülmüş veya aynı sprint'te

### Bağımlılık Sırası (Büfe Aşaması)

```
Constants.gd (sabitler) 
  → EventBus.gd (sinyaller)
    → OrderManager (state machine)
      → CustomerSystem (spawn + patience)
      → ChefSystem (cooking)
      → EconomySystem (coin/gem)
        → UpgradeSystem (upgrade effects)
        → OfflineSystem (offline earnings)
          → SaveSystem (persist)
            → UI bileşenleri (HUD, panels)
              → WelcomeModal (offline flow)
                → AchievementSystem
                → AdSystem
```

Üstteki tamamlanmadan alttaki sprint'e alınamaz.

---

## 7. Definition of Done (DoD)

Bir issue "Done" sayılmadan önce tüm maddeler geçmeli:

- [ ] Tüm AC'ler karşılandı
- [ ] GUT testi yazıldı (public fonksiyonlar için)
- [ ] Linter hatasız (`gdlint` veya Godot parser)
- [ ] Magic number yok, her sayı `Constants.gd`'de
- [ ] Direkt sistem çağrısı yok (EventBus kullanıldı)
- [ ] Docstring var (tüm public fonksiyonlar)
- [ ] Türkçe identifier/comment yok (§8 CLAUDE.md)
- [ ] Yeni sabit varsa `Constants.gd`'ye eklendi
- [ ] Yeni sinyal varsa `EventBus.gd`'ye eklendi
- [ ] Commit mesajı formatına uygun (`feat(system): ...`)
- [ ] Jira issue "Done" durumuna taşındı

---

## 8. Commit ↔ Jira Bağlantı Kuralı

Her commit mesajında Jira issue ID'si bulunur:

```
feat(customer): LI-12 impatient customer patience timer implementation

fix(chef): LI-18 cooking slot not clearing after CANCELLED_ANGRY

test(economy): LI-23 tip formula edge case for patience_ratio=0
```

Format: `<type>(<scope>): LI-XX <açıklama>`

Jira'nın GitHub entegrasyonu açıkken commit otomatik olarak ticket'a bağlanır.

---

## 9. Jira Board Akışı

```
Backlog → Sprint Backlog → In Progress → In Review → Done
```

| Kolon | Anlam |
|-------|-------|
| **Backlog** | Yazılmış ama sprint'e alınmamış |
| **Sprint Backlog** | Sprint'e seçildi, başlanmadı |
| **In Progress** | Aktif geliştirme |
| **In Review** | Kod yazıldı, kendi review'u yapılıyor |
| **Done** | DoD geçti |

> Solo geliştirici olduğu için "In Review" kısa tutulur. Bug fix veya kritik logic değişikliğinde zorunlu, feature'da isteğe bağlı.
