# Lezzet İmparatorluğu — Character Art Prompts

## Usage Context

These prompts are for generating **2D character art** that will be:

1. Generated via AI image tool (Midjourney / DALL·E / Stable Diffusion)
2. Converted to 3D models via **image-to-3D AI** (e.g. Meshy, Tripo3D, Wonder3D)
3. Rendered from an **isometric camera angle** inside Godot 4 (tile size 128×64 px)
4. Used as animated sprites at approximately **128×192 px** in-game

Sprites appear on top of isometric tiles. Characters must read clearly from a **top-down 45° isometric viewpoint**.

---

## Character Roster


| ID                   | Character  | Species   | Game Role          | Patience        |
| -------------------- | ---------- | --------- | ------------------ | --------------- |
| `chef`               | Chef Kirpi | Hedgehog  | Cooks all orders   | —               |
| `customer_regular`   | Kedi       | Tabby Cat | Regular customer   | High (40s)      |
| `customer_impatient` | Tavşan     | Rabbit    | Impatient customer | Low (18s)       |
| `customer_tourist`   | Penguen    | Penguin   | Tourist customer   | Very High (65s) |


---

## Global Style Rules (apply to every prompt)

Apply these rules to **all** characters without exception:

- **Art style:** chibi cartoon, cel-shaded, flat colors with minimal gradients
- **Proportions:** large round head (≈ 55% of total height), short chunky limbs, no neck
- **Eyes:** large, glossy, circular — expressive anime-style eyes
- **Outline:** thick dark outline (#3E3238 warm dark brown), consistent weight
- **Lighting:** flat lighting only — no shading, no shadows of any kind
- **Background:** pure white (#FFFFFF) ONLY — absolutely no dark, black, grey or colored backgrounds, no vignette, no gradient — **white background is mandatory for img-to-3D conversion**
- **No shadows:** no cast shadow under character, no drop shadow, no self-shadow on body, no ambient occlusion — **flat colors only, shadows confuse img-to-3D depth detection**
- **Pose:** strict T-pose — both arms fully extended outward at 45° angle, NO arm touching or overlapping the torso, clear air gap between arms and body — **required for img-to-3D conversion**
- **Symmetry:** left and right arms mirrored, both equally separated from body
- **View:** straight-on front view, perfectly centered, slight 3/4 tilt (5–10°) to hint at volume
- **Shadow:** no cast shadow on background
- **Line of sight:** character looks slightly upward toward viewer (isometric camera compensation)

### Color Palette Reference

```
Coral    #FF8A6B / #F2714F   warm salmon-orange
Mint     #A8E6CF / #5CC39A   soft sage green
Butter   #FFE08A / #F2B705   warm pastel yellow
Sky      #A5D8F3 / #4FA8DF   light powder blue
Lavender #CBB6E8 / #9B6FC4   soft purple
Cream    #F5EEE6              off-white base
Ink      #3E3238              outline & shadows
```

All clothing and props must use only these colors (no additional hues).

---

## img-to-3D Technical Requirements

Add these instructions to **every prompt** when submitting to img-to-3D tools:

> "Single character on white background. T-pose, front-facing, symmetrical where possible.
> Cel-shaded flat colors, thick outlines. No background. No cast shadows.
> Designed for isometric game rendering at small scale."

For best results generate a **3-view character sheet** (front / side / back) in one image.
Use this layout prompt addition: *"character turnaround sheet, three views side by side: front view, side view, back view, same scale, white background"*

---

## CHARACTER PROMPTS

---

### 1. CHEF KIRPI (Hedgehog Chef)

**Role:** The restaurant's cook. Energetic, round, always busy.  
**Color coding:** Coral apron, cream body, butter-yellow highlights  
**Personality cue:** Wide happy grin, rosy cheeks, slightly hunched forward with enthusiasm

```
Cute chibi hedgehog chef character, anthropomorphic, strict T-pose.
Both arms extended outward at 45 degrees away from body, both arms
fully visible with clear air gap between arms and torso, no limb touching body.
Round plump body covered in soft brown spines, cream-colored face and belly.
Wearing a tall white chef hat with a small coral (#FF8A6B) stripe, and a coral-colored
apron over a cream shirt. Small stubby arms, tiny round feet in brown shoes.
Both eyes fully open, large glossy circular eyes (warm amber), rosy circular cheeks,
wide cheerful smile showing small teeth — no winking, no closed eyes.
Butter-yellow (#FFE08A) star badge pinned to apron.
Thick warm dark outline (#3E3238). Cel-shaded flat colors, no gradients.
Pastel palette, cartoon style, chibi proportions (head 55% of height).
Pure white (#FFFFFF) background only, no dark background, no vignette.
No cast shadow, no drop shadow, no self-shadow, no shading on body, flat colors only.
Front view, perfectly centered, slight 3/4 tilt, symmetrical pose.
Game character sprite for isometric restaurant idle game.
```

---

### 2. CUSTOMER — KEDI (Regular Tabby Cat)

**Role:** Everyday regular customer. Relaxed, patient, friendly.  
**Color coding:** Mint green outfit — calm and positive  
**Personality cue:** Soft half-lidded eyes, gentle smile, relaxed posture

```
Cute chibi tabby cat character, anthropomorphic, strict T-pose.
Both arms extended outward at 45 degrees away from body, both arms
fully visible with clear air gap between arms and torso, no limb touching body.
Round fluffy head with orange-cream tabby stripes, small pink triangle nose,
tiny whiskers (3 per side). Soft rounded ears with pale pink inner ear.
Wearing a mint-green (#A8E6CF) casual hoodie with cream drawstrings and
mint-green (#5CC39A) sneakers. Short fluffy tail curled gently to one side.
Both eyes fully open, large glossy eyes (soft green), friendly relaxed expression,
gentle small smile, soft rosy cheeks — no winking, no angry brows, no frown.
Upright natural standing posture, no lean.
Thick warm dark outline (#3E3238). Cel-shaded flat colors, chibi proportions.
Pastel palette, cartoon style, round chubby limbs.
Pure white (#FFFFFF) background only, no dark background, no vignette.
No cast shadow, no drop shadow, no self-shadow, no shading on body, flat colors only.
Front view, perfectly centered, slight 3/4 tilt, symmetrical pose.
Game character sprite for isometric restaurant idle game.
```

---

### 3. CUSTOMER — TAVŞAN (Impatient Rabbit)

**Role:** Always in a hurry. Low patience, quick to leave.  
**Color coding:** Butter yellow outfit — coin-colored, energetic  
**Personality cue:** Wide alert eyes, brow slightly furrowed, one foot lifted as if tapping

```
Cute chibi rabbit character, anthropomorphic, strict T-pose.
Both arms extended outward at 45 degrees away from body, both arms
fully visible with clear air gap between arms and torso, no limb touching body.
Round head with long upright ears (cream inside, light grey outside), small pink nose,
tiny buck teeth visible in a tense smile. Compact fluffy body with short stubby tail.
Wearing a butter-yellow (#FFE08A) zip-up jacket with a tiny gold clock icon
embroidered on the chest pocket, and butter-yellow cargo pants with cream sneakers.
Both eyes fully open, large glossy eyes (bright orange-amber), wide open anxious expression,
eyebrows angled inward (worried/impatient) — no winking, no closed eyes.
One ear slightly tilted forward.
Thick warm dark outline (#3E3238). Cel-shaded flat colors, chibi proportions.
Pastel palette, cartoon style, energetic silhouette.
Pure white (#FFFFFF) background only, no dark background, no vignette.
No cast shadow, no drop shadow, no self-shadow, no shading on body, flat colors only.
Front view, perfectly centered, slight 3/4 tilt, symmetrical pose.
Game character sprite for isometric restaurant idle game.
```

---

### 4. CUSTOMER — PENGUEN (Tourist Penguin)

**Role:** Tourist visitor. Very patient, high spender, relaxed pace.  
**Color coding:** Sky blue & lavender outfit — premium, calm  
**Personality cue:** Wide curious eyes, content smile, small camera around neck

```
Cute chibi penguin character, anthropomorphic, strict T-pose.
Both arms (wings) extended outward at 45 degrees away from body, both arms
fully visible with clear air gap between arms and torso, no limb touching body.
Round egg-shaped body, classic black-and-white penguin coloring with a cream-yellow
belly patch. Tiny round wings as arms, stubby orange feet.
Wearing a sky-blue (#A5D8F3) tourist vest with many small pockets, a lavender
(#CBB6E8) scarf loosely around the neck, and a tiny vintage camera
(butter-yellow #FFE08A body, sky-blue strap) hanging at chest height.
Small sky-blue backpack visible slightly behind the left shoulder.
Both eyes fully open, large glossy eyes (sky blue), wide open delighted expression,
soft content smile — no winking, no closed eyes.
Thick warm dark outline (#3E3238). Cel-shaded flat colors, chibi proportions.
Pastel palette, cartoon style, rounded waddle silhouette.
Pure white (#FFFFFF) background only, no dark background, no vignette.
No cast shadow, no drop shadow, no self-shadow, no shading on body, flat colors only.
Front view, perfectly centered, slight 3/4 tilt, symmetrical pose.
Game character sprite for isometric restaurant idle game.
```

---

## Bonus: Emotion Variants

For each character, generate the following **expression sheet** (same pose, face close-up):

```
[CHARACTER BASE PROMPT] — expression sheet showing 3 face close-ups side by side
on white background, same character, three emotions:
Left: happy 😊 (wide smile, shining eyes) — patience above 65%
Center: neutral 😐 (flat mouth, normal eyes) — patience 35–65%
Right: angry 😠 (frown, narrowed eyes, steam puff) — patience below 35%
No body visible, just head and shoulders. Labeled: HAPPY / NEUTRAL / ANGRY.
```

---

## Generation Tips


| Setting                 | Recommendation                                                                       |
| ----------------------- | ------------------------------------------------------------------------------------ |
| Aspect ratio            | 1:1 for single character, 3:1 for turnaround sheet                                   |
| Style keywords to add   | `pastel colors, thick outlines, flat shading, chibi, kawaii, cartoon, clean lineart` |
| Style keywords to avoid | `realistic, photorealistic, 3D render, shadows, texture, detailed background`        |
| Negative prompt         | `background, shadow, realistic, adult, dark colors, gradient, blur`                  |
| Seed                    | Lock seed after first good result, regenerate only expressions                       |


### Recommended generation order

1. Chef Kirpi — establishes the style baseline
2. Kedi — closest to neutral, easy second
3. Tavşan — most expressive, do after style is locked
4. Penguen — most distinctive silhouette, save for last
5. Emotion sheets for all 4 after base designs approved

# "Single character on white background. T-pose, front-facing, cel-shaded flat colors, thick outlines. No background. Isometric game character."

# --no shadow, drop shadow, cast shadow, shading, gradient, dark background, black background, vignette

