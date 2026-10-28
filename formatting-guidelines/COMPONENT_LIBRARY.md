# UI3 component library

Use this file when an app should align with Figma's UI3 product language, not only its brand expression.

Source: [UI3 Library — Badges page](https://staging.figma.com/design/N0izGT6Y7WwEOJABqPXBCv/%F0%9F%93%96-UI3-Library?node-id=12559-260871&p=f&m=dev)

The source was inspected through the staging Figma MCP on September 18, 2026. The linked badge documentation displays `Updated 03.5.2025`; other pages and components may have different maturity or update dates.

## 1. Scope and source hierarchy

The UI3 file describes Figma's compact product interface. It is distinct from the Figma Brand Book:

- **Brand system:** palette, identity, expressive typography, imagery, and voice. Use it for brand and marketing expression.
- **UI3 product system:** semantic variables, compact controls, interaction states, component composition, and code-connected implementation.
- **App translation:** portable recommendations in this kit for projects that cannot consume Figma's internal libraries directly.

When rules overlap, use this order:

1. Accessibility, platform conventions, and the app's real interaction requirements.
2. Existing project components and their Figma Code Connect mappings.
3. UI3 component APIs and semantic variables when the project has authorized access to them.
4. The brand rules in `VISUAL_SYSTEM.md` for the surrounding expression.
5. Local app-translation tokens for gaps that the source systems do not cover.

Do not copy an internal component's appearance into bespoke markup when the corresponding code component is available. Do not make a brand surface look like a dense editor merely because both sources are from Figma.

## 2. Library structure

The inspected file is connected to these libraries:

- `📖 UI3 Library`: product components and documented variants;
- `😀 UI3 Icons`: functional interface icons;
- `🧩 UI3 Templates`: larger reusable compositions;
- `🎨 UI3 Tokens`: semantic variables and modes;
- `UI3 Docs`: documentation primitives;
- `Thumbnail Mocks`: supporting product-demo content.

The overview describes UI3 components as a “golden” set shared one-to-one between design and code. Preserve that relationship:

- start from the Figma component instance;
- use the Code Connect result at the mapped node;
- keep the component's public properties and state model;
- bind styling to semantic variables rather than sampled hex values;
- use official UI3 icons for functional controls;
- compose primitives before proposing a new component.

Treat page and component status as source-of-truth. Prefer ready, green component pages. Treat pages marked beta as beta. Avoid future, red, WIP, legacy, and deprecated assets unless the project has a documented exception.

## 3. Product foundations

### Compact density

UI3 is a dense desktop product system. The inspected controls establish two common visual heights:

| Size | Visual height | Typical use |
|---|---:|---|
| `md` | 24px | Dense editor chrome, menus, property panels, compact actions |
| `lg` | 32px | Forms, prominent actions, and roomier product surfaces |

Badges use a smaller scale: `md` is 16px high and `lg` is 20px high.

These are component heights, not universal hit-target guidance. On touch or mixed-input surfaces, provide an appropriately larger interactive target without visually stretching the component. The portable default remains a 44×44 CSS-pixel target where the platform and layout permit it.

### Semantic tokens

Consume variables from `🎨 UI3 Tokens`; do not freeze the reference values into new components. The inspected Button, Input, and Badge components use these roles:

| Group | Observed semantic roles |
|---|---|
| Surface | `color-bg`, `color-bg-secondary`, `color-bg-inverse`, transparent hover and pressed surfaces |
| Text | default, secondary, disabled, on-brand, on-danger, on-success, on-inverse |
| Border | default, translucent, selected, disabled, brand, danger, warning, success |
| Icon | default and on-color roles corresponding to the text roles |
| Feedback | brand, danger, warning, success, component, inverse, disabled |
| Spacing | 4, 8, 12, 16, 24, and 32px steps |
| Shape | a 5px medium radius in the inspected compact controls |

The brand palette in `VISUAL_SYSTEM.md` is not a replacement for these semantic product roles. For example, UI3's selected and brand-control tokens use product blue, while the Brand Book's `blue` is intended for brand composition. Keep the namespaces separate.

### Product typography

The inspected UI3 components use semantic Inter styles:

| Style | Size / line height | Weight | Use |
|---|---|---:|---|
| `body.medium` | 11 / 16px | 450 | Compact controls and metadata |
| `body.large` | 13 / 22px | 450 | Larger labels and readable product copy |

Consume the text style rather than reproducing its font declarations. The source styles include optical details such as letter spacing. Do not apply Figma Sans over an actual UI3 component; reserve the brand typography rules for surrounding brand-led surfaces.

### Modes and state

- Use token modes for light and dark contexts; do not invert colors manually.
- Keep interaction state separate from semantic variant. `Danger` is a meaning; `Hover` is an interaction state.
- Implement default, hover, active or pressed, focus, and disabled states wherever the component exposes them.
- Keep checked, selected, mixed, expanded, loading, validation, and read-only as explicit state—not ad hoc color changes.
- A focus appearance is required even if pointer-focused screenshots are the most visible examples in the source.
- Color never carries a semantic state alone. Preserve text, icon, shape, and accessible-name cues.

## 4. Component selection

### Actions

Use `Button` for labeled actions, `IconButton` for a familiar single-icon action, `ToggleButton` for an action with a persistent on/off state, and `ButtonGroup` for related actions with a shared boundary.

The ready Button set exposes:

- variants: `primary`, `secondary`, `destructive`, `destructiveSecondary`, `signup`, `inverse`, `ghost`, `link`, and `destructiveLink`;
- sizes: `md`, `lg`, `md-wide`, and `lg-wide`;
- states: default, hover, active, focus, disabled, and loading;
- optional icon, shortcut, dropdown, loading label, and trailing content properties.

Guidance:

- Use one primary action per region.
- Use destructive variants only for destructive outcomes; do not use red merely for emphasis.
- Use `signup` only in its intended acquisition context.
- Preserve the label during loading when space permits, and prevent duplicate activation.
- Give every icon-only button an accessible name and a discoverable tooltip when the action is not universally obvious.
- A wide variant is a component API, not permission to make every action full width.

### Fields and forms

Use `Input`, `FormattedInput`, `NumberInput`, `PasswordInput`, `ColorInput`, `SearchInput`, `SplitInput`, `Select`, and `Textarea` for their named data types. Build labeled rows with `FormRow` when the beta Form system is approved for the project.

The base Input set exposes:

- sizes `md` and `lg` at 24 and 32px visual heights;
- default, hover, and focus interaction states;
- none, success, warning, and invalid validation states;
- independent disabled and read-only properties.

Guidance:

- Keep a persistent visible label. The 160px width in the component sheet is a specimen width, not a layout rule.
- Treat read-only and disabled differently: read-only content remains readable and selectable; disabled controls are unavailable.
- Show validation with a message near the field, not border color alone.
- Preserve entered content after validation fails.
- Use formatted inputs only when prefix, suffix, chip, swatch, stepper, or icon content has a defined input relationship.
- Use `Select` for choosing from a menu, not for navigation or an action list.

### Choice and selection

- Use `Checkbox` for independent or multi-select choices. Support checked, unchecked, and mixed states.
- Use `Radio` for one choice from a visible mutually exclusive set.
- Use `Switch` for an immediately applied on/off setting; do not use it as a submit action.
- Use `SegmentedControl` for a small set of peer views or modes, not a long option list.
- Use `Tabs` to switch between sibling panels while preserving the surrounding context.
- Use `Chip` for compact selected values, filters, tokens, or removable entities. Do not substitute chips for ordinary buttons.

The library models checked, selected, mixed, focus, and disabled explicitly. Preserve the corresponding platform semantics such as `aria-checked`, `aria-selected`, and `aria-expanded`.

### Navigation and disclosure

- Use `Menu` for transient actions or selection lists. Keep destructive items visually and spatially clear.
- Use `Collapse` for in-place disclosure whose content remains in the page hierarchy.
- Use `TreeGrid` only for hierarchical, interactive data that genuinely needs selection, expansion, rename, indentation, and keyboard navigation.
- Use a standard list or table when hierarchy and grid interaction are not both required.

### Overlays and containers

- Use `Popover` for contextual content anchored to a control.
- Use `Modal` for focused work that temporarily blocks the underlying flow.
- Use `Window` for a persistent floating product surface when the platform supports that model.
- Use `Tooltip` for short, supplemental explanation. The source page is beta; essential instructions must remain visible outside a tooltip.
- Move focus into a blocking overlay, trap it when appropriate, close with Escape where safe, and return focus to the trigger.

### Feedback and messaging

- Use `Banner.FullWidth` for page- or system-level messages.
- Use `Banner.Inset` within a modal or bounded section.
- Use `Banner.Inline` near the affected content.
- Use `Toast` for brief, non-blocking confirmation or failure that does not require a decision.
- Use `Notifications` for richer or persistent updates.
- Use `LoadingSpinner` only when progress cannot be represented more informatively. Keep a text status available to assistive technology.

Choose default, brand, danger, warning, or success from the message meaning. Do not select a variant merely to make the surface more colorful.

## 5. Badge rules

The linked component is Code Connected as `Badge` from `@fpl/components`. It supports `md` and `lg`, optional leading content, editable label text, and filled or outline variants where defined.

| Variant family | Use |
|---|---|
| Default | Generic classification with background contrast, such as “Admin” or “Guest” |
| Brand | New or beta features inside a distinct product experience |
| Inverse | High emphasis when a brand-filled badge would draw too much attention |
| Component | Component-related features or entities |
| Danger | Destructive actions, errors, or something needing urgent attention |
| Warning | A potential issue or condition that warrants caution |
| Success | Confirmation, approval, or completed work |
| Inactive | Inactive states such as “Archived” |
| On fill | A badge placed over a bold brand-colored surface that must inherit suitable base contrast |

Use filled for stronger emphasis and outline for quieter labeling. Keep labels short, specific, and sentence case. Do not use a badge as a button, and do not rely on its color without readable text.

## 6. Ready component inventory

The inspected ready pages include these public families:

| Need | Preferred UI3 components |
|---|---|
| Actions | Button, IconButton, ToggleButton, ButtonGroup |
| Form structure | Form (beta), FormRow, helper content |
| Text entry | Input, FormattedInput, NumberInput, PasswordInput, ColorInput, SearchInput, SplitInput, Textarea |
| Choice | Checkbox, Radio, Switch, Select, SegmentedControl |
| Compact entities | Badge, Chip |
| Navigation and hierarchy | Tabs, Collapse, Menu, TreeGrid |
| Overlays | Popover, Modal, Window, Tooltip (beta), ToggleTip |
| Feedback | Banner, Toast, Notifications, LoadingSpinner |
| Specialized input | Slider, MultiSlider |
| Product-specific compositions | Comments, Curator feature callout |

Product-specific compositions should not become generic app defaults. Reuse them only when the app has the same job, content model, and interaction contract.

## 7. Implementation workflow

For work with access to the UI3 libraries:

1. Find the matching ready component in the Figma file.
2. Inspect its current properties, token bindings, and documentation frame.
3. Check Code Connect at the exact node.
4. Reuse the connected code component and its public API.
5. Bind layout and styling to project semantic tokens; do not paste generated utility classes into production.
6. Add real content and implement keyboard, focus, loading, empty, validation, error, and disabled behavior.
7. Compare the implementation with both light and dark source contexts where the component supports them.
8. Document any exception and its owner.

For projects without internal library access, translate the behavior and state model into the project's own design system. Do not publish internal package names, copied icons, screenshots, or token dumps as if they were portable public assets.

## 8. Asset policy

No component screenshots or exported UI3 icons are bundled with this kit. They are implementation references, not application assets.

- Use the authorized `😀 UI3 Icons` library or the project's existing functional icon set.
- Do not export a component screenshot and ship it in place of a real interface.
- Do not download every icon preemptively; include only assets used by a real flow.
- Keep product imagery, illustrations, and identity marks under the rules in `VISUAL_SYSTEM.md`.
- If an approved Figma asset is required, export the original node in the intended format and record its source node, license or authorization, and usage location.

## 9. Component review checklist

- [ ] An existing ready component was used or a documented gap explains why not.
- [ ] The code component matches the Figma node through Code Connect when available.
- [ ] Variant, size, semantic meaning, and interaction state are separate concerns.
- [ ] Default, hover, active or pressed, focus, disabled, and loading states are complete where relevant.
- [ ] Checked, selected, mixed, expanded, read-only, and validation semantics are exposed to assistive technology.
- [ ] Styling uses semantic tokens and supports the required color modes.
- [ ] Compact visual height does not create an undersized touch target.
- [ ] Icons come from the authorized functional icon system and icon-only actions have accessible names.
- [ ] The implementation uses real controls and text, not exported component screenshots.
- [ ] Beta, future, WIP, legacy, or deprecated dependencies are called out explicitly.
