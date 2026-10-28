# Visual system

## 1. Design character

The system balances two modes:

- **Utilitarian:** calm, neutral, legible, and information-first. Use it for sustained product work.
- **Expressive:** bold type, oversized graphic forms, vibrant pairings, and focused moments of delight. Use it when the message is short and the surface can support more visual energy.

Craft is visible in proportion, type spacing, alignment, realistic content, and considered details—not in extra decoration.

## 2. Color palette

Use the values below exactly. Do not invent tints, shades, gradients, or additional scheme colors and present them as part of the brand palette.

### Scheme colors

| Token | Name | Hex | Default background use | Text on that background |
|---|---|---:|---|---|
| `blue` | Blue | `#4D49FC` | Approved | White |
| `cyan` | Cyan | `#00B6FF` | Approved | Black |
| `dark-green` | Dark Green | `#0A5C35` | Approved | White |
| `kelly-green` | Kelly Green | `#24CB71` | Accent only by default | — |
| `neon-green` | Neon Green | `#67FF7F` | Never | — |
| `lime` | Lime | `#E4FF97` | Approved | Black |
| `mint` | Mint | `#F3FFE3` | Approved | Black |
| `gold` | Gold | `#B98E01` | Approved | Black |
| `purple` | Purple | `#874FFF` | Never | — |
| `dusty-violet` | Dusty Violet | `#CB9FD2` | Approved | Black |
| `periwinkle` | Periwinkle | `#C4BAFF` | Approved | Black |
| `maroon` | Maroon | `#721C1C` | Approved | White |
| `hot-red` | Hot Red | `#FF3737` | Never | — |
| `orange` | Orange | `#FF7237` | Approved | Black |
| `hot-pink` | Hot Pink | `#FF01E5` | Never | — |
| `peach` | Peach | `#FFC9C1` | Approved | Black |
| `brown` | Brown | `#877A7A` | Approved | White |

### Neutrals

| Token | Name | Hex | Default background use | Text on that background |
|---|---|---:|---|---|
| `white` | White | `#FFFFFF` | Approved | Black |
| `light-gray` | Light Gray | `#E2E2E2` | Approved | Black |
| `medium-gray` | Medium Gray | `#6D6E6D` | Approved | White |
| `black` | Black | `#000000` | Approved | White |

The deck identifies the pairings in these tables as the approved accessible background/text combinations. Treat Kelly Green as an accent unless a separate accessibility review approves a specific use. Hot Pink, Neon Green, Purple, and Hot Red must not be used as backgrounds.

### Hero schemes

Choose one scheme for a composition. Pairs, trios, or a larger palette may be drawn from that scheme, but do not combine schemes casually.

| Scheme | Colors |
|---|---|
| Core | Blue, Dark Green, Hot Red, Maroon, Lime, Dusty Violet, White, Black |
| Warm | Hot Pink, Orange, Blue, Kelly Green, Periwinkle, Peach, White, Black |
| Cool | Purple, Gold, Neon Green, Mint, Cyan, Brown, White, Black |

Preferred tonal background pairs are Dark Green + Lime, Maroon + Dusty Violet, Blue + Peach, Orange + Periwinkle, Gold + Cyan, and Brown + Mint. Black may act as a focal color inside illustrations.

### Color behavior

**Brand rules**

- Aim for vibrant, electric relationships, but balance them with tonal or low-contrast pairings.
- Use a bright color as a focused pop, not as noise across every element.
- Do not use monochrome brand palettes.
- Do not match a foreground illustration color to its background.
- Do not create new schemes or add colors to a named scheme.
- Use only black or white typography on color.
- Target an absolute APCA value of at least 60 for digital type and color.
- Use neutral backgrounds for information-heavy contexts.

**App translation**

- Keep the application shell neutral. Use one scheme per route, campaign, or feature story rather than per component.
- Prefer color in surfaces, fills, imagery, and illustration. Keep text neutral.
- Do not use brand colors alone to communicate success, warning, error, selection, or focus. Pair semantic states with text, icons, shape, and accessible project-specific tokens.
- Avoid maximal palettes in tables, editors, forms, analytics, billing, and settings.
- For dark mode, use Black as the canvas, White as primary text, and validate every secondary text value separately. The brand palette does not define a complete dark-mode ramp.

## 3. Implementation tokens

Start with these raw brand tokens for a portable, brand-inspired app. Semantic component tokens should alias them rather than repeat hex values.

These are not UI3 product tokens. When a project consumes actual UI3 components, keep their bindings to `🎨 UI3 Tokens` and do not override them with this palette, type stack, spacing, or radius scale. See `COMPONENT_LIBRARY.md` for the product-system layer.

```css
:root {
  --figma-blue: #4d49fc;
  --figma-cyan: #00b6ff;
  --figma-dark-green: #0a5c35;
  --figma-kelly-green: #24cb71;
  --figma-neon-green: #67ff7f;
  --figma-lime: #e4ff97;
  --figma-mint: #f3ffe3;
  --figma-gold: #b98e01;
  --figma-purple: #874fff;
  --figma-dusty-violet: #cb9fd2;
  --figma-periwinkle: #c4baff;
  --figma-maroon: #721c1c;
  --figma-hot-red: #ff3737;
  --figma-orange: #ff7237;
  --figma-hot-pink: #ff01e5;
  --figma-peach: #ffc9c1;
  --figma-brown: #877a7a;

  --figma-white: #ffffff;
  --figma-light-gray: #e2e2e2;
  --figma-medium-gray: #6d6e6d;
  --figma-black: #000000;

  --surface-canvas: var(--figma-white);
  --surface-subtle: var(--figma-light-gray);
  --text-primary: var(--figma-black);
  --text-on-dark: var(--figma-white);

  --font-sans: "Figma Sans", Inter, ui-sans-serif, system-ui, sans-serif;
  --font-mono: "Figma Mono", ui-monospace, SFMono-Regular, Consolas, monospace;

  /* App-translation spacing scale; the source deck does not define one. */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-8: 2rem;
  --space-12: 3rem;
  --space-16: 4rem;
  --space-24: 6rem;

  /* App-translation radii; keep these consistent across the product. */
  --radius-control: 0.5rem;
  --radius-card: 0.75rem;
  --radius-panel: 1rem;
  --radius-pill: 999px;
}

[data-theme="dark"] {
  --surface-canvas: var(--figma-black);
  --surface-subtle: var(--figma-medium-gray);
  --text-primary: var(--figma-white);
}
```

Suggested semantic aliases for an approved colored surface:

```css
.surface-blue { background: var(--figma-blue); color: var(--figma-white); }
.surface-cyan { background: var(--figma-cyan); color: var(--figma-black); }
.surface-dark-green { background: var(--figma-dark-green); color: var(--figma-white); }
.surface-lime { background: var(--figma-lime); color: var(--figma-black); }
.surface-mint { background: var(--figma-mint); color: var(--figma-black); }
.surface-gold { background: var(--figma-gold); color: var(--figma-black); }
.surface-dusty-violet { background: var(--figma-dusty-violet); color: var(--figma-black); }
.surface-periwinkle { background: var(--figma-periwinkle); color: var(--figma-black); }
.surface-maroon { background: var(--figma-maroon); color: var(--figma-white); }
.surface-orange { background: var(--figma-orange); color: var(--figma-black); }
.surface-peach { background: var(--figma-peach); color: var(--figma-black); }
.surface-brown { background: var(--figma-brown); color: var(--figma-white); }
```

## 4. Typography

### Family roles

| Family | Role | Do not use for |
|---|---|---|
| Figma Sans | All primary headings, UI labels, and body copy | — |
| Figma Mono | Code, metadata, eyebrows, tags, and badges | Primary headings, long body copy, or Dev Mode sub-branding |
| Figma Hand | Occasional FigJam-specific headlines or marginalia | Body copy or general application UI |
| Figma Sans Condensed | Shortcut editorial surface only | General apps |

When Figma Sans is used, enable automatic optical sizing. Default to width 100 and weight 400. A medium weight around 480–500 may emphasize the opening sentence of a body block. Use bold and oblique only when the meaning requires emphasis, not as decoration.

If the licensed Figma fonts are unavailable, the fallback stack in the token example preserves function but is not an exact brand reproduction.

### UI3 product exception

Actual UI3 controls use component-provided Inter styles rather than the brand family. The inspected library uses `body.medium` at 11/16px and `body.large` at 13/22px, both with a variable weight of 450. Preserve those semantic styles when using UI3. Do not restyle a connected UI3 control to Figma Sans merely to make it look more branded.

### Non-Latin typography

The source brand book names these script-specific alternatives:

- Zen Kaku Gothic New for Japanese;
- Noto Sans Korean for Korean;
- Noto Sans Devanagari for Devanagari-script content;
- Noto Sans Thai for Thai;
- Noto Sans Balinese when Balinese script is required.

Choose fonts by language and script rather than applying a single fallback to every locale. Test the real translated interface for line wrapping, vertical metrics, weight availability, and mixed-script rendering. Do not force Latin letter-spacing values onto scripts where they reduce readability.

### Type scale

The source system provides this reference scale:

| Size | Line height | Letter spacing | Typical app role |
|---:|---:|---:|---|
| 120px | 100% | -3% | Campaign display only |
| 80px | 105% | -2% | Large landing hero |
| 60px | 120% | -0.5% | Page hero |
| 48px | 120% | 0 | Display heading |
| 32px | 130% | 0 | Page heading |
| 24px | 140% | 0 | Section heading |
| 18px | 140% | 0 | Lead body or compact heading |
| 16px | 140% | 0 | Default body and controls |
| 12px | 140% | 0 | Metadata only |

Use the variable font when possible. If static files are required, use the Display cut for sizes above 36px and the Text cut at 24px and below. Treat the 32px step as an intermediate variable-font role.

### Composition rules

- Use sentence case everywhere.
- Make headlines short and punchy. As size grows, word count should fall.
- Set very large headlines tightly, near 100% line height.
- Create hierarchy primarily with size and space, not many weights or colored text.
- Never mix Figma Mono into a Figma Sans headline.
- Never use Figma Hand for body copy.
- Keep paragraph measure roughly 45–75 characters where the layout permits.
- Outside an actual UI3 component's `body.medium` style, do not shrink below 12px to make content fit. Rewrite or restructure instead.

## 5. Layout and component application

### Brand rules

- Give identity marks abundant clear space.
- Place marks on an outer edge with even surrounding margins.
- Let complex illustrations occupy more room; complexity must match available surface area.
- Oversized forms may crop beyond a frame when a low-contrast tonal pairing keeps the composition controlled.
- Use bold, focused hierarchy rather than many equally loud elements.

### App translation

- Use the 4px spacing scale from the token example. Prefer `8 / 12 / 16 / 24 / 32 / 48 / 64 / 96` for visible layout decisions.
- Keep one primary action per region. Make secondary actions quieter through outline, text, or placement.
- Use neutral cards and panels inside expressive page backgrounds; do not stack many competing colored surfaces.
- Keep control radii consistent. Use pills for tags, statuses, or compact filters—not as the default shape for every control.
- Use borders, spacing, and typographic hierarchy before adding shadows. Shadows should communicate elevation or interaction, not decoration.
- Use familiar control patterns. Brand expression should not reduce predictability, hit-area size, keyboard support, or state clarity.
- Preserve at least 44×44 CSS pixels for primary touch targets where possible.
- UI3's 24px `md` and 32px `lg` measurements are compact visual control heights. On touch or mixed-input surfaces, enlarge the interactive hit area without distorting the component.

## 6. Identity marks

These rules apply only when the project is authorized to use Figma identity assets.

- Prefer the Figma wordmark. It must be black or white.
- Use the full-color icon only on white or black.
- Use the mono-outline icon on color.
- Use the icon when space is too limited for the wordmark.
- Maintain clear space around a mark equal to the mark's height.
- Place a mark on a layout's outer edge with even margins.
- Pair wordmarks with wordmarks and icons with icons. Keep partner marks visually balanced.
- Use provided lockups and app icons as-is.
- Do not recolor, stretch, rearrange, outline, grayscale, rebuild, or combine marks.
- Do not use the icon as the letter “F” in a word.
- Do not place marks on low-contrast backgrounds.
- Do not use branded product icons as substitutes for UI-library icons.

## 7. Illustration

Illustration should communicate making rather than merely decorate a screen.

### Themes and motifs

- **Ideate:** freeform, collage-like combinations of hand-drawn lines, vector forms, patterns, and mixed fidelity.
- **Design:** formal transformation—objects morph, evolve, or change across a composition.
- **Build:** visible systems and construction—pixels, measurements, nodes, annotations, and underlying structure.
- **Modality:** multiple ways of making represented together.
- **Craft:** attention to atomic details and playful composition.
- **Collaboration:** forms touch, overlap, respond, adapt, and build on one another.

### Style rules

- Start with the approved illustration library before creating anything new.
- Use bold, graphic primitives, line, frames and nodes, activation patterns, and imperfect grids.
- Match complexity to placement: a spot illustration supports a component; a hero illustration needs room to dominate.
- Let illustration respond to the frame and content rather than float as unrelated decoration.
- Do not create new primitives.
- Do not use cursors in brand illustrations.
- Do not mix realistic UI with brand illustration.
- Do not mix old and current illustration styles.
- Do not use dashed lines as layout borders.
- Do not give primitives a solid outline or white fill.

## 8. Photography and video

- Represent a global audience across race, ethnicity, gender, age, ability, role, and geography.
- Use artful, editorial composition with clean, considered lighting.
- Keep styling contemporary, gender-neutral, creative, and relaxed.
- Favor direct, confident, empowering poses.
- Avoid generic corporate staging, fluorescent-office aesthetics, dramatic zooms, and drone-footage cliches.
- Apply the same bold, vibrant, graphic standard used elsewhere in the visual system.

## 9. Product imagery and demos

- Show a compelling, plausible use case—not an empty or obviously fabricated canvas.
- Use accurate UI, exact scale, or realistic proportional relationships.
- Write all visible sample content intentionally. Do not leave lorem ipsum unless the story is specifically about placeholder text.
- Use globally diverse personal names in cursors and collaboration examples; do not label cursors only by job role.
- For a full-product view, preserve the complete UI context.
- For feature storytelling, isolate, enlarge, or crop UI only when it improves clarity without misrepresenting behavior.
- Keep product visuals at the center; brand color, type, image, and video should support the product story.
- Use demo brands or fictional data that feel coherent enough to be real.

## 10. Motion

The brand character is dynamic. Motion may show transformation, iteration, collaboration, construction, or shifts between modes of making.

**App translation**

- Animate state change and spatial relationships, not decoration for its own sake.
- Keep routine UI transitions fast and quiet; reserve expressive motion for onboarding, launches, and storytelling.
- Honor reduced-motion preferences.
- Never make essential content depend on animation completing.
- Avoid motion that suggests an AI feature completed work the user still needs to review.
