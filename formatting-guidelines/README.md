# Figma-inspired app guidelines

Portable standards for apps that should feel aligned with Figma's 2026 brand system and, where authorized, its compact UI3 product language: bold, crafted, collaborative, clear, and human.

These guidelines were distilled from the **Figma Brand Book 2026**, last updated August 2026, and supplemented with UI3 component-library guidance. Both sources were reviewed through the Figma MCP on September 18, 2026.

Sources:

- [Figma Brand Book 2026](https://www.figma.com/slides/Gy2jvBc041Wqz9S4cV5CvW/Figma-Brand-Book-2026?node-id=1-39)
- [UI3 Library — Badges page](https://staging.figma.com/design/N0izGT6Y7WwEOJABqPXBCv/%F0%9F%93%96-UI3-Library?node-id=12559-260871&p=f&m=dev)

## What's in this kit

- [VISUAL_SYSTEM.md](./VISUAL_SYSTEM.md): palette, color pairings, typography, layout, identity, illustration, photography, product imagery, and implementation tokens.
- [COMPONENT_LIBRARY.md](./COMPONENT_LIBRARY.md): UI3 foundations, component selection, states, badge usage, implementation workflow, and asset policy.
- [VOICE_AND_CONTENT.md](./VOICE_AND_CONTENT.md): voice, tone, UI writing, AI language, vocabulary, and content patterns.
- [QA_CHECKLIST.md](./QA_CHECKLIST.md): a practical design, content, and accessibility review before release.

Copy this directory into another project and link to these files from that project's contributor or agent instructions.

## How to interpret the rules

Three kinds of guidance appear in this kit:

- **Brand rule**: directly reflects the source brand book. Treat it as required when making Figma-branded work.
- **UI3 product-system reference**: reflects the inspected internal component library. Use it when the project is authorized to consume UI3 or when translating its interaction patterns into a local system.
- **App translation**: a recommended way to apply the brand direction to interface design where the source book does not specify component-level behavior.

The Brand Book is not a complete product UI design system. UI3 fills many component-level gaps, but it is a dense internal product system and is not automatically available or appropriate for every app. Project-specific interaction, platform, licensing, and accessibility requirements still apply.

## Brand and product layers

Keep the two visual layers distinct:

- use the Brand Book for expressive palette, identity, imagery, voice, and brand-led typography;
- use UI3 semantic tokens and component-provided typography for actual UI3 product controls;
- do not overwrite a UI3 component with brand colors, Figma Sans, or the portable app-translation radii;
- do not use compact UI3 measurements as universal touch-target guidance.

## North star

Build products that make it easier for people to turn ideas into real work together. The experience should feel:

- approachable enough for a first-time user;
- precise enough for a professional;
- expressive without obscuring the task;
- clever without becoming cryptic;
- technically credible without drowning people in jargon.

## Non-negotiables

1. Use sentence case for headings, labels, buttons, and navigation.
2. Set normal typography in black or white; choose only an approved background/text pairing and target an absolute APCA contrast value of at least 60.
3. Use neutral surfaces for dense workflows. Reserve maximal color for focused moments such as onboarding, empty states, launches, interstitials, and campaign surfaces.
4. Use Figma Sans as the primary family on brand-led and local non-UI3 surfaces when it is licensed and available. Preserve the component-provided Inter styles in actual UI3 controls. Use Figma Mono only for code, metadata, eyebrows, tags, or badges.
5. Write conversationally, clearly, and with honest specificity. Prefer short sentences, contractions, active voice, and common words.
6. Do not frame AI as replacing the user's skill, judgment, or craft. Show what it does, why it helps, and where the user stays in control.
7. Keep product demonstrations realistic: real content, plausible data, correct proportions, and accurate UI states.
8. Use official Figma marks only in authorized Figma contexts. Never treat the Figma logo or product marks as generic decoration for an unrelated app.
9. Reuse a ready component and its semantic variables before creating a local substitute. Preserve its state model and Code Connect mapping when available.
10. Do not ship exported component screenshots as interface assets. Use real controls, authorized icons, and accessible interaction behavior.

## Surface strategy

| Surface | Visual mode | Content tone |
|---|---|---|
| Dense editor, dashboard, settings | Neutral canvas, restrained accents, strong hierarchy | Clear and empathetic |
| Onboarding, empty state, lightweight prompt | One approved color pairing, simple illustration | Encouraging with a small amount of wit |
| Feature education or release note | Focused product crop plus expressive brand support | Conversational, specific, lightly nerdy |
| Marketing landing page or product launch | Bold type, larger illustration, broader palette | Aspirational and imaginative, still concrete |
| Error, permission, billing, destructive action | Minimal decoration, direct recovery path | Calm, transparent, never cheeky |

## Suggested project policy

Add this statement to a project's contributor documentation:

> Follow the files in `figma-app-guidelines/` for visual, component, and content decisions. Use only named tokens, approved background/text pairs, defined type roles, and ready components. Preserve Code Connect mappings and the source component state model when available. Run the release checklist for every new user-facing flow. If a necessary UI pattern is not covered, extend the local product system without changing the source brand palette or voice rules.

## Brand and legal boundary

These notes are a working translation of the referenced sources, not a replacement for Figma's official assets, internal library access, font licenses, legal requirements, or brand review. An app can borrow the systems' principles without implying that Figma created, sponsors, or endorses it. Internal UI3 components, packages, icons, and variables are references unless the project is authorized to consume them. For external Figma-branded work, use approved asset files and the current review process.
