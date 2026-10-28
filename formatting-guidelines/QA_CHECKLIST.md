# Release checklist

Use this checklist for every new user-facing page, flow, campaign, or major component. Record exceptions in the pull request or design review rather than silently diverging.

## 1. Intent and hierarchy

- [ ] The surface has one clear primary job.
- [ ] The most important message or action is visually dominant.
- [ ] Brand expression supports the task instead of competing with it.
- [ ] Dense workflows use the utilitarian mode; expressive layouts are reserved for focused moments.
- [ ] The page communicates a concrete user outcome, not only a feature or slogan.

## 2. Color

- [ ] Every brand color uses the exact named token from `VISUAL_SYSTEM.md`.
- [ ] The composition stays within one hero scheme unless it is deliberately neutral.
- [ ] Every colored background uses an approved text pairing.
- [ ] Hot Pink, Neon Green, Purple, and Hot Red are not used as backgrounds.
- [ ] Kelly Green is treated as an accent unless a separate review approves the pairing.
- [ ] Normal typography is black or white, not a scheme color.
- [ ] Digital text/color pairings reach an absolute APCA value of at least 60.
- [ ] Semantic states are not communicated by color alone.
- [ ] The design does not invent palette tints, shades, gradients, or new named schemes.
- [ ] Information-heavy surfaces are neutral enough for sustained use.

## 3. Typography

- [ ] Figma Sans is primary on brand-led surfaces when licensed and available; connected UI3 controls retain their component-provided Inter styles.
- [ ] Automatic optical sizing is enabled when the platform supports it.
- [ ] Default width is 100 and normal weight is 400.
- [ ] Headings and UI strings use sentence case.
- [ ] Large headlines are short and tightly set.
- [ ] Hierarchy comes mainly from size and spacing, not many weights or colored text.
- [ ] Body text has a readable measure and at least the defined line height.
- [ ] No essential app copy is smaller than 12px; UI3's 11/16px compact control style is used only through the connected semantic text style and has been tested in context.
- [ ] Figma Mono is limited to code, metadata, eyebrows, tags, or badges.
- [ ] Figma Hand is not used for body copy or general UI.

## 4. Layout and interaction

- [ ] Spacing follows the project scale consistently.
- [ ] Similar components share the same radii, padding, and state behavior.
- [ ] There is one primary action per region.
- [ ] Decorative color, motion, or illustration does not interrupt scanning or task completion.
- [ ] Controls use familiar patterns and include hover, active, focus, disabled, loading, error, and success states where relevant.
- [ ] Primary touch targets are at least 44×44 CSS pixels where possible.
- [ ] Keyboard order, visible focus, and focus return have been tested.
- [ ] Zoom, reflow, long content, localization, and narrow viewports do not break the layout.
- [ ] Reduced-motion preferences are honored.

## 5. Component library

- [ ] An existing ready component was used before a new component was created.
- [ ] The implementation reuses the Code Connected component at the mapped node when one exists.
- [ ] UI3 components retain their semantic token and typography bindings rather than being overwritten with brand-layer values.
- [ ] Variant, size, semantic meaning, and interaction state are modeled separately.
- [ ] Default, hover, active or pressed, focus, disabled, and loading states are implemented where relevant.
- [ ] Checked, selected, mixed, expanded, read-only, and validation states expose the correct platform and assistive-technology semantics.
- [ ] Compact 24px or 32px controls have an appropriate hit target for the input context.
- [ ] Functional icons come from the authorized UI icon system and icon-only actions have accessible names.
- [ ] Beta, future, WIP, legacy, or deprecated components have a documented exception.
- [ ] No exported component screenshot is being shipped as a substitute for a real control.

## 6. Identity assets

Skip this section when the app is not authorized Figma-branded work.

- [ ] The official current asset file is used without reconstruction.
- [ ] The wordmark is black or white.
- [ ] The full-color icon appears only on white or black.
- [ ] Color surfaces use the mono-outline icon.
- [ ] Clear space around the mark is at least the mark's height.
- [ ] The mark sits on an outer edge with even margins.
- [ ] Partner identities match in type and visual weight: wordmark with wordmark, icon with icon.
- [ ] No mark has been recolored, stretched, rearranged, outlined, grayscaled, or combined into a new lockup.
- [ ] Product-brand icons are not used as functional UI icons.
- [ ] The mark and background pass the required contrast check.

## 7. Illustration, media, and product imagery

- [ ] An existing approved illustration was considered before making a new asset.
- [ ] Illustration communicates ideation, design, building, modality, craft, or collaboration.
- [ ] Complexity matches the available space.
- [ ] Illustration does not mix realistic UI, cursors, old styles, new primitives, solid outlines, or white-filled primitives.
- [ ] Photography and video are globally representative, editorial, contemporary, and confidently composed.
- [ ] Product examples use realistic content, correct proportions, and accurate UI behavior.
- [ ] Demo content contains no accidental lorem ipsum, private information, misleading results, or implausible data.
- [ ] Collaboration examples use globally diverse names rather than reducing people to roles.
- [ ] Focused UI crops preserve enough context to remain truthful.

## 8. Voice and content

- [ ] The writing sounds conversational and down-to-earth.
- [ ] Clever or nerdy touches improve the message rather than obscure it.
- [ ] Copy uses common words, contractions, active voice, and short paragraphs.
- [ ] The user's task or benefit comes before product praise.
- [ ] Claims are specific, supportable, and free of grandiose promises.
- [ ] Exclamation marks, semicolons, and parentheses are used sparingly.
- [ ] Buttons begin with a specific verb and accurately describe the result.
- [ ] Field labels persist; placeholders are not acting as labels.
- [ ] Errors explain what happened, what remains true, and what to do next.
- [ ] Destructive messages name the object, consequence, and recoverability.
- [ ] Empty states provide one useful next action.
- [ ] The copy has been checked for inclusive language and unnecessary jargon.

## 9. AI experiences

- [ ] The UI names the concrete AI operation.
- [ ] The user knows what can be reviewed, edited, retried, or undone.
- [ ] The copy does not suggest AI replaces human craft or judgment.
- [ ] Limitations and uncertainty are communicated where they affect decisions.
- [ ] Data use and consequential actions are transparent.
- [ ] The interface does not promise perfect, magical, or fully autonomous results.

## 10. Accessibility and resilience

- [ ] Automated contrast checks have been supplemented with manual review.
- [ ] Text alternatives exist for meaningful images and illustrations.
- [ ] Captions or transcripts exist for meaningful video and audio.
- [ ] Headings form a logical hierarchy.
- [ ] Instructions do not rely only on color, position, sound, or motion.
- [ ] Errors are announced and associated with the relevant controls.
- [ ] The flow works with keyboard-only navigation and a screen reader smoke test.
- [ ] Loading, empty, error, offline, permission, and partial-data states have been designed.
- [ ] Names, dates, numbers, and text expansion have been tested with representative international formats.

## 11. Definition of done

A surface is ready when:

- visual tokens and type roles are consistent;
- approved contrast and interaction states are verified;
- content is specific, human, and appropriate to the stakes;
- responsive, keyboard, assistive-technology, and failure states work;
- any exception is documented with its reason and owner.

Passing this checklist does not replace review for external Figma-branded work, licensed fonts, identity assets, or legal claims.
