# SplashScreen — Godot Editör Kurulum Notları

## 1. Fontu import et
```
assets/fonts/ klasörüne koy:
  - Fredoka-SemiBold.ttf   → Google Fonts'tan indir
  - Nunito-Regular.ttf
  - Nunito-Bold.ttf

Sonra TitleLabel'ın theme_override_fonts/font alanına ata.
```

## 2. AnimationPlayer animasyonlarını ekle

**fade_in** (0.5 sn):
- Track: SplashScreen / modulate
- Anahtar 0.0sn → Color(1,1,1,0)  [şeffaf]
- Anahtar 0.5sn → Color(1,1,1,1)  [opak]
- Easing: ease_out

**fade_out** (0.4 sn):
- Track: SplashScreen / modulate
- Anahtar 0.0sn → Color(1,1,1,1)
- Anahtar 0.4sn → Color(1,1,1,0)
- Easing: ease_in

## 3. LoadBarFill gradient (opsiyonel)
ColorRect yerine TextureRect + gradient texture kullanırsan
coral → coral_deep gradyanı daha güzel görünür.

## 4. Dekoratif daireler (opsiyonel)
ColorRect yerine VisualShader ile circle clip mask
veya Sprite2D + yuvarlak texture kullan.

## 5. MainGame sahnesini oluşturduktan sonra
SplashScreen.gd içindeki NEXT_SCENE sabitini güncelle:
```gdscript
const NEXT_SCENE := "res://scenes/MainGame.tscn"
```

## 6. Test
- Godot editöründe F6 ile SplashScreen.tscn'i çalıştır
- 2.5 saniye bekle → sahne geçişi dene
- Debug build'de SPACE tuşu ile anında atlayabilirsin
