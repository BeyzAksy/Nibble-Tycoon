---
name: start-task
description: Jira task başlatma workflow'u. Verilen LI-XX ID ile task detaylarını okur, implementation planı sunar, onay sonrası kodlar. "LI-XX başlat", "LI-XX yap" veya "/start-task LI-42" dediğinde kullan.
when_to_use: Kullanıcı belirli bir Jira task ID'si (LI-XX formatında) ile bir iş başlatmak istediğinde.
argument-hint: [LI-XX]
disable-model-invocation: true
allowed-tools: Read Edit Write Bash
---

Task ID: $ARGUMENTS

## Bağlamı Yükle

1. Jira MCP ile `$ARGUMENTS` issue'sunu çek — Business Rules, Flow, AC, Out of Scope, Dependencies
2. `JIRA_STANDARDS.md` — DoD
3. `CLAUDE.md` — sistem haritası, yasak davranışlar
4. `CONVENTIONS.md` — GDScript kuralları
5. `ARCHITECTURE.md` — ilgili mimari karar (EventBus, Constants, upgrade pattern)
6. Epic'e bağlı kaynak dosyaları

## Bağımlılıkları Kontrol Et

Linked issue'lar tamamlandı mı? Tamamlanmamışsa dur ve kullanıcıya bildir.

## Implementation Planı (onay öncesi göster)

```
TASK: $ARGUMENTS — [Başlık]
Epic: [epic adı]

ANLAYIŞ:
- [BR-01 ne demek, kendi cümlelerinle]
- [BR-02 ...]
- [Belirsiz BR varsa burada sor]

YAPILACAKLAR:
1. Constants.gd: [yeni sabitler]
2. EventBus.gd: [yeni sinyaller]
3. [dosya]: [ne değişecek]
4. Tests: [senaryolar]

EDGE CASES:
- [edge case] → [davranış]

AC KARŞILAMA:
- AC-01: [nasıl]
- AC-02: [nasıl]

Başlayalım mı?
```

## Kodlama (onay sonrası)

Sıra: Constants.gd → EventBus.gd → core sistem → handler'lar → test dosyası

Her dosyada:
- `CONVENTIONS.md` — type hints, docstring, sinyal pattern
- `CLAUDE.md §Yasak` — magic number, print(), direkt çağrı yok

## DoD Kontrolü (bitirmeden önce)

- [ ] Tüm AC'ler karşılandı
- [ ] GUT testi geçiyor
- [ ] Linter hatasız
- [ ] Magic number yok, direkt çağrı yok
- [ ] Docstring var, Türkçe identifier yok
- [ ] Commit: `feat/fix(scope): $ARGUMENTS açıklama`

## Docs Güncelle (Jira'dan önce — zorunlu)

Kod bittikten sonra, bu taskın neleri değiştirdiğine göre ilgili CLAUDE.md dosyalarını güncelle. Her trigger bağımsız kontrol edilir.

### autoload/CLAUDE.md
Şu durumlardan biri varsa oku ve güncelle:
- `EventBus.gd`'e yeni sinyal eklendi → "Planlanan Yeni Sinyaller" tablosundan o satırı çıkar
- `Constants.gd`'e yeni dict/yapı eklendi (CUSTOMER_TYPES, ACHIEVEMENTS vb.) → "Planlanan Genişlemeler" tablosundan o satırı çıkar
- `project.godot`'a yeni autoload kaydedildi → "Mevcut autoload'lar" listesine ekle

### scripts/systems/CLAUDE.md
Şu durumlardan biri varsa oku ve güncelle:
- `scripts/systems/` altına yeni `.gd` dosyası oluşturuldu → modül kataloğuna yeni bölüm ekle: sorumluluk, temel metodlar, extension noktaları
- Mevcut bir sistemin API'si değiştiyse → ilgili bölümü güncelle

### scripts/ui/CLAUDE.md
Şu durumlardan biri varsa oku ve güncelle:
- `scripts/ui/` altına yeni `.gd` dosyası oluşturuldu → bileşen kataloğuna ekle: sorumluluk, inject edilenler, dinlediği sinyaller
- `**tscn yok (todo)**` olan bir `.tscn` dosyası bu taskta oluşturuldu → o notu kaldır

### CLAUDE.md (root)
"Açık Kararlar" tablosundaki bir konu bu taskta implement edildiyse → o satırı sil.

### Güncelleme Kuralları
- Dosyayı önce oku, sonra hedefli edit yap — tüm dosyayı yeniden yazma
- Güncelleme yoksa dosyaya dokunma
- Yaptığın değişiklikleri bitişte kısaca listele: `Docs: autoload/CLAUDE.md → X satırı kaldırıldı`

## Jira Güncelle

Docs güncellemesi bittikten sonra: status → "In Review", kısa comment.
Kullanıcı "done" deyince: status → "Done".

## Kurallar

- Business Rules belirsizse dur ve sor — varsayım yapma
- GDD'de olmayan şey istenirse belirt
- Plan onaylanmadan tek satır kod yazma
