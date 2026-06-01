# Jira MCP Kurulum Kılavuzu

> Claude Code ve Cursor'ın Jira'ya doğrudan yazabilmesi için MCP kurulumu.
> Bu kurulum bir kez yapılır.

---

## 1. Jira API Token Al

1. https://id.atlassian.com/manage-profile/security/api-tokens adresine git
2. "Create API token" → token adı: `lezzet-imparatorlugu-mcp`
3. Token'ı kopyala, güvenli bir yere kaydet (bir daha gösterilmez)

---

## 2. Jira MCP Sunucusu: `mcp-atlassian`

Kullanacağımız sunucu: **`sooperset/mcp-atlassian`** (community, en stabil)

```bash
# Global kurulum
npm install -g mcp-atlassian
```

Ya da npx ile kurmadan kullanmak için (önerilen):
```bash
# Test et
npx mcp-atlassian --version
```

---

## 3. Claude Code Yapılandırması

`.claude/settings.json` dosyasını oluştur veya güncelle:

```json
{
  "mcpServers": {
    "jira": {
      "command": "npx",
      "args": ["mcp-atlassian"],
      "env": {
        "JIRA_URL": "https://YOUR_WORKSPACE.atlassian.net",
        "JIRA_EMAIL": "beyzaaksoy@gmail.com",
        "JIRA_API_TOKEN": "YOUR_API_TOKEN_HERE"
      }
    }
  }
}
```

**`YOUR_WORKSPACE`** → Jira'daki workspace adın (örn. `lezzet-imparatorlugu`)
**`YOUR_API_TOKEN_HERE`** → 1. adımda aldığın token

> Güvenlik: API token'ı `.claude/settings.json`'a yazma — sadece `settings.local.json`'a yaz.
> `settings.local.json` git'e commit edilmez (zaten `.gitignore`'da olmalı).

`.claude/settings.local.json` güncelle:
```json
{
  "permissions": {
    "allow": [
      "Bash(open /Users/beyzaaksoy/Downloads/lezzet_prototype_v2.html)"
    ]
  },
  "mcpServers": {
    "jira": {
      "command": "npx",
      "args": ["mcp-atlassian"],
      "env": {
        "JIRA_URL": "https://YOUR_WORKSPACE.atlassian.net",
        "JIRA_EMAIL": "beyzaaksoy@gmail.com",
        "JIRA_API_TOKEN": "YOUR_API_TOKEN_HERE"
      }
    }
  }
}
```

---

## 4. Cursor Yapılandırması

`.cursor/mcp.json` dosyasını oluştur:

```json
{
  "mcpServers": {
    "jira": {
      "command": "npx",
      "args": ["mcp-atlassian"],
      "env": {
        "JIRA_URL": "https://YOUR_WORKSPACE.atlassian.net",
        "JIRA_EMAIL": "beyzaaksoy@gmail.com",
        "JIRA_API_TOKEN": "YOUR_API_TOKEN_HERE"
      }
    }
  }
}
```

Cursor'u yeniden başlat. Settings → MCP'de "jira" yeşil görünmeli.

---

## 5. Jira Proje Yapılandırması

### Proje Oluştur

1. Jira'ya gir → Projects → Create Project
2. **Scrum** tipi seç
3. Project name: `Lezzet İmparatorluğu`
4. Project key: `LI`

### Epic'leri Oluştur

`JIRA_STANDARDS.md §2 Epic Kataloğu`ndaki tüm epic'leri sırayla oluştur:

| Epic Adı | Key |
|----------|-----|
| Sipariş Döngüsü | LI-CORE-LOOP |
| Müşteri Sistemi | LI-CUSTOMER |
| Şef & Mutfak | LI-CHEF |
| Upgrade Ağacı | LI-UPGRADE |
| Ekonomi Sistemi | LI-ECONOMY |
| Offline Kazanç | LI-OFFLINE |
| Menü & Ürünler | LI-MENU |
| UI & Animasyonlar | LI-UI |
| Save Sistemi | LI-SAVE |
| Achievement Sistemi | LI-ACHIEVEMENT |
| Level & İlerleme | LI-PROGRESSION |
| Reklam Mekanikleri | LI-ADS |
| Bug & Polish | LI-QA |

### GitHub Entegrasyonu (commit bağlantısı için)

1. Jira → Project Settings → Integrations → GitHub
2. Repository'yi bağla
3. Bundan sonra `LI-42:` içeren her commit ticket'ta görünür

---

## 6. Kurulumu Test Et

Claude Code'da dene:
```
Jira'da LI projesinin backlog'unu listele
```

Cursor'da dene:
```
Jira LI-QA epic'ine bağlı issue'ları getir
```

Her iki araçta da Jira verileri görünüyorsa kurulum tamamdır.

---

## 7. .gitignore Güncelle

API token'ların git'e gitmemesi için:

```gitignore
# Jira/MCP credentials
.claude/settings.local.json
.cursor/mcp.json
```

> `settings.local.json` zaten hassas verileri burada tut.
> `mcp.json`'ı da git'ten dışla.
