---
name: jira-bug
description: Hızlı Jira bug kaydı. Bug bilgisini toplar, JIRA_STANDARDS şablonuna göre formatlar, onay sonrası Jira'ya kaydeder. "bug kaydet", "bug aç", "jira bug" dediğinde kullan.
when_to_use: Kullanıcı bir bug bildirdiğinde veya Jira'ya hata kaydı açmak istediğinde.
disable-model-invocation: true
allowed-tools: Read
---

## Bug Bilgisini Topla

Kullanıcının mesajından çıkar: ne kırık, nerede, nasıl tekrar üretilir, beklenen vs gerçek.

Eksikse **en fazla 2 soru** sor — hız öncelikli.

## Severity Belirle

- **P1** — Core loop kırık (sipariş durmuş, crash, açılmıyor)
- **P2** — Önemli özellik çalışmıyor (upgrade, coin)
- **P3** — Yanlış davranış ama oynanabilir
- **P4** — Visual/UX

## Hazırla ve Göster (Jira'ya yazmadan önce)

```
SUMMARY: [Sistem]: [ne kırık]

ENVIRONMENT:
- Level: [belirtilmişse]
- Tekrar eden: [Her seferinde / Bazen / Bir kere]

STEPS TO REPRODUCE:
1. ...
2. ...

EXPECTED: ...
ACTUAL: ...

ROOT CAUSE: [varsa — hangi dosya/state?]

SEVERITY: P[1/2/3/4]
RELATED: [dosya:satır varsa]
EPIC: LI-QA
SP: [1/2/3]

Jira'ya kaydedeyim mi?
```

## Jira'ya Kaydet (onay sonrası)

Type: Bug | Epic: LI-QA | Priority: P1→Highest, P2→High, P3→Medium, P4→Low | Backlog'a ekle.

Kayıt sonrası ID ver.

P1 görünce ekle: "Bu sprint önceliğini değiştirmek ister misin?"
