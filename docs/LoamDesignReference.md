# Loam-inspired direction for CycleWrench

Reviewed October 27, 2026. This brief covers **the app UI and feature hierarchy**,
not just App Store artwork. It uses the official current listing, six actual store
screenshots, and three actual screenshots linked from Loam's product page. No app
was installed and no personal data was accessed. The reference images are
proprietary; they were inspected privately, not added as CycleWrench assets.

## The useful principle

Loam turns service tracking into a readable instrument panel: **which bike, what
needs attention, what reading matters, and what action follows**. Borrow that
hierarchy and restraint. CycleWrench's distinct expression should be warmer,
quieter and centered on fast manual logging and personal interval estimates.

## What is visible versus claimed

| Evidence inspected | Visible design pattern | What it does not establish |
| --- | --- | --- |
| [Official garage image](https://loamlog.com/press/screens/real-garage.webp) | Black canvas, matte rounded cards, bike photograph fading into a status area, one prominent upcoming job, compact mileage/hours, small per-component dials, neutral unknown state. | Actual interaction speed, whether every displayed health number represents measurement, or how card ordering works. |
| [Official component image](https://loamlog.com/press/screens/component.webp) | One leading status/readout card; secondary interval/history rows; highly visible primary service action; other actions below it. | Whether the service action needs additional confirmation or how unknown starting history is handled internally. The actual pictured part is a fork, despite the product-page alternative text describing a chain. |
| [Official workshop image](https://loamlog.com/press/screens/workshop.webp) | Repeatable rows with icon, part name, secondary compatibility text, quantity and small cost badge. Limited accent colors express state. | Inventory algorithms or the need for a workshop feature in CycleWrench. |
| [Current App Store gallery](https://apps.apple.com/us/app/loam-mountain-bike-service/id6781034553) | Six coordinated panels: a short numbered category, oversized benefit headline, a single ochre emphasis, and a large cropped real UI screen. Screens progress through overview, bike, component, sources, stock and kit. | That integrations or inventory deserve equal prominence in our app; these are Loam's product priorities. |

The [official product page](https://loamlog.com/mtb/) additionally describes
independent service clocks, optional manual/connected data sources and neutral
unknown history. Those are documented behavior claims rather than hands-on
verification. Its service demonstration keeps lower-leg servicing separate from
full suspension overhauls; that separation is a useful domain lesson.

## Apply now

### 1. Give the selected bike a compact identity and a clear odometer

Use the bike name as the primary heading, followed by subtle setup chips only
when configured. Make the **current odometer** the strongest numeric element and
make that entire row an obvious edit target. A small pencil or chevron resolves
ambiguity. Avoid a second odometer-only mode or duplicating the same total in
several cards.

A photograph is optional, not a prerequisite. A compact original bicycle symbol
or quiet color block is an adequate fallback. Do not add a tall photo header that
pushes the user's logging task below the fold.

### 2. One nearest-attention panel, not a synthetic health score

Show a component name, a readable distance remaining, and a short source line:
for example, **Chain · about 240 mi left**, with **Based on 3 completed intervals**.
Use a small status badge. When data is insufficient, show a neutral learning
state and the next useful action; do not render it as fresh, overdue, or 0% wear.

A per-component ring or progress bar may describe distance toward a historical
average, but it must not pretend to measure physical wear. CycleWrench should not
copy Loam's aggregate percentage as an overall bike-health score. The useful
information for this user is the next part and approximate remaining miles.

### 3. Keep logging the dominant interaction

Retain the compact component dropdown, front/rear modifier, per-component default
action and optional notes. Keep **Save in the toolbar**, consistent with the user's
existing preference. Use card rhythm and typography to clarify the action hierarchy;
do not add a competing full-width save action merely because Loam has one.

Components and History should remain secondary destinations. On iPad and wide
layouts, a sidebar plus constrained readable detail is better than stretching
phone cards across the entire canvas. Keep the same conceptual destinations in
compact and expanded layouts.

### 4. Make component status rows readable at a glance

A consistent row can contain an original/SF component symbol, component name,
small last-work context, status badge and prominent remaining distance. Align
numbers with monospaced digits. Use color as reinforcement, never as the only
status signal. Preserve front/rear distinctions and freeform custom names.

A detail screen should lead with the current estimate and next action, then
explain the calculation, sample count and history. The first completed interval
is an early estimate, not confidence that the part will last exactly that distance.

## An original material and type system

These are **proposed CycleWrench tokens**, not sampled Loam colors:

| Role | Dark direction | Light counterpart / behavior |
| --- | --- | --- |
| Canvas | Deep forest `#0D1713` | Warm off-white `#F4F2E9` |
| Raised surface | Pine charcoal `#17251E` | Pale natural white `#FAFBF7` |
| Primary text | Soft ivory `#F2F4EA` | Deep green `#193227` |
| Calm accent | Sage `#B7C8AD` | Darker forest for readable foregrounds |
| Approaching average | Ochre `#D5AC52` | Pair with a text label; choose a darker foreground in light mode |
| Past average / attention | Terracotta `#C8876C` | Use a stronger dark terra foreground where required for contrast |

Use flat matte surfaces, generous spacing, one subtle border and little or no
shadow. A restrained top gradient may connect the app to the textured multicolor
icon direction, but texture should not sit behind small text. Verify contrast
rather than assuming every proposed accent works as body text in both schemes.

Use native Dynamic Type. A slightly rounded bold system title/large numeral can
give CycleWrench its own character; ordinary system body text stays legible.
Loam's condensed all-caps display face is effective in marketing, but copying it
throughout the app would reduce readability and make the resemblance too literal.
Section overlines can be quiet and short. Large text layouts must grow or stack.

## Useful feature inspiration, ranked

| Priority | Opportunity | Scope boundary |
| --- | --- | --- |
| Now | Status + reading + next action in one place | Use existing personal estimates; do not invent new wear data. |
| Now | Distinct unknown state and component-specific default actions | Current manual flow remains usable without a completed setup. |
| Next | Component detail with its own history and calculation explanation | No additional dashboard required. |
| Next | Repeat a previous service, correction/backfill and undo | Prefill component/action, never copy an old odometer as today's reading. |
| Next | Optional distance/calendar/ride-hour reminders and separate service tiers | Keep personal lifespan and manufacturer service limits visibly different. |
| Later | User bike photos and a small configurable component-summary strip | Optional, compact, no mandatory image or branding catalog. |
| Later | Widget/Shortcut for next attention or quick logging | No full ride-recording or training product. |
| Defer | Workshop stock, kit bag, trip packing, shop lookup and broad integrations | These are Loam's breadth, not CycleWrench's current core. |

## App Store storytelling

Borrow the **one benefit + one real screen** discipline, not the headlines,
photographs, exact layout or branded glyphs. A distinct CycleWrench sequence could
show: quick logging; the next part needing attention; understandable personal
lifespans; complete service history; private restore/sync; custom components.
Use synthetic test-bike records only, and make the media truthful to shipping
functionality. Do not advertise cloud recovery or an integration before acceptance
testing proves it.

Keep captions large, screenshots readable, spacing consistent, and the warmer
forest/sage/terra/ochre palette continuous with the icon and app. Avoid squeezing
multiple tiny phone screens into each panel. Store media can be expressive while
the app itself remains calm and task-focused.

## Exact store asset references inspected

These URLs are the current public assets extracted from Apple's listing, and may
change when the developer updates its gallery:

- [Overview panel](https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/1c/f6/b9/1cf6b990-956c-8a0a-eff9-af46cdc4bbe2/01-garage.png/600x1300bb.webp)
- [Bike panel](https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/aa/98/44/aa9844c4-a500-0142-6c5e-53fd7b784990/02-bike.png/600x1300bb.webp)
- [Component panel](https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/44/77/8f/44778f9e-a197-8148-1add-c0ca6ee14ea6/03-component.png/600x1300bb.webp)
- [Connections panel](https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/ea/da/de/eadadeb3-359e-f7f2-bf1e-0301c53946a9/04-connect.png/600x1300bb.webp)
- [Workshop panel](https://is1-ssl.mzstatic.com/image/thumb/PurpleSource211/v4/87/73/ad/8773addd-ece1-a73b-24b5-aec945828fb1/05-workshop.png/600x1300bb.webp)
- [Kit panel](https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/e6/49/69/e649693d-3e7a-630d-bc38-befb9bad7e31/06-kit.png/600x1300bb.webp)
