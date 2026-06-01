---
name: plan-sprint
description: Sprint planlama workflow'u. Proje belgelerini analiz edip Jira'da sprint oluşturur. "yeni sprint planla", "sprint planla", "sprint oluştur" dediğinde kullan.
when_to_use: Kullanıcı yeni bir sprint başlatmak istediğinde, backlog önceliklendirmek istediğinde veya Jira'da sprint oluşturmak istediğinde.
disable-model-invocation: true
allowed-tools: Read Bash
---

## Bağlamı Yükle (bu sırayla)

1. `JIRA_STANDARDS.md` — epic kataloğu, öncelik kriterleri, bağımlılık sırası, SP rehberi
2. `CLAUDE.md` — aktif aşama, sistem haritası, açık kararlar
3. `docs/bufe_asama_gdd.md` — henüz implement edilmemiş GDD kısımları
4. `ARCHITECTURE.md` §Açık Mimari Soruları
5. `PROJECT_STRUCTURE.md` §Bekleyen Taşımalar

## Analiz Et

- `scripts/systems/` — eksik veya yarım sistemler
- GDD'de var, kodda yok olanlar (AchievementSystem, SatisfactionSystem, vb.)
- `CLAUDE.md §Açık Kararlar` — çözülmemiş belirsizlikler

## Öneri Hazırla (Jira'ya yazmadan önce kullanıcıya göster)

```
SPRINT X — [tarih aralığı]
Hedef: [tek cümle — bu sprint sonunda ne çalışıyor?]
Toplam: ~X SP

MUST HAVE
─────────
[ ] LI-EPIC: Başlık — X SP — Story/Task
    Bağımlılık: LI-YY ✓ / ►
    Gerekçe: ...

SHOULD HAVE
───────────
[ ] ...

BACKLOG (ertelendi)
───────────────────
- LI-EPIC: Başlık — neden: ...
```

Sonra sor:
> Onaylıyor musun? Eklemek/çıkarmak istediğin issue var mı? Sprint tarihi (varsayılan: bugün + 2 hafta)?

## Jira'ya Yaz (sadece onay sonrası)

1. Sprint oluştur
2. Her issue'yu `JIRA_STANDARDS.md §4 Şablonu`na göre yaz — Context, Business Rules, Flow, AC, Out of Scope, Dependencies, Epic Link
3. Issue'ları sprint'e ekle, URL'i ver

## Kurallar

- Onay olmadan Jira'ya yazma
- 13 SP'yi geçen iş bölünür
- `JIRA_STANDARDS.md §6 Bağımlılık Sırası` ihlal edilemez
