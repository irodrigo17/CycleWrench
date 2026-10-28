# CycleWrench competitive research

Research date: October 27, 2026. US App Store prices are in USD and can change.
This study compares eight bicycle-maintenance apps across free and paid offerings.
It uses 24 primary-source pages: eight App Store listings and sixteen official
product, help, release-note or privacy pages, linked where used below.

No apps were installed, no account was created, no developer was contacted, and
no rider data was accessed. Exact tap counts, performance, sync reliability and
actual paywall behavior require a later hands-on study using a test bike only.
A listed capability below means the developer documents it, not that we verified
it works. “Unknown” means the inspected sources do not establish the answer.
App Store privacy labels are developer disclosures, not independent audits.

## Recommendation in brief

Keep CycleWrench centered on **a quick manual service log that learns from your
own component history**. The market already has capable genuinely free apps, so
“free bicycle maintenance tracker” is insufficient positioning. The stronger
combination is minimal entry, trustworthy personal estimates, transparent unknowns,
portable records, private sync and inspectable open-source code.

Prioritize correcting/backfilling records, easy custom components, reliable
restore/export, and calendar/hour-based reminders before broad ride integrations.
Make costs, receipts, bike specifications and integrations optional detail layers.
Do not copy a competitor's full garage, training, weather, shopping or social hub.

## Pricing and monetization

| App | Current documented US price | Free scope and paywall qualification |
| --- | --- | --- |
| **velohaus** | Free; optional tips $0.99/$2.99/$4.99. | Unlimited bikes and iCloud; official site says no subscription. Tips are explicitly optional. [Store](https://apps.apple.com/us/app/velohaus/id6775131677), [developer](https://velo.haus/). |
| **Velo Garage** | Free. | Official support says no subscriptions, IAPs, ads or paid tier. [Store](https://apps.apple.com/us/app/velo-garage-service-tracker/id6760527480), [support](https://velogarage.app/support). |
| **Loam MTB** | Free. | Developer explicitly says free, no ads and no separate app account. Do not confuse it with the paid Loam Moto product. [Store](https://apps.apple.com/us/app/loam-mountain-bike-service/id6781034553), [developer](https://loamlog.com/mtb/). |
| **ProBikeGarage** | $3.99 upfront; optional Premium $2.99/month or $24.99/year. | Baseline tracking is described as free on its site, but the iOS download itself is paid. Premium includes attachments and additional sync/tools. [Store](https://apps.apple.com/us/app/probikegarage-bicycle-tracker/id1422489202), [pricing](https://www.probikegarage.com/). |
| **Cogbook** | Free download; Pro $3.99/month, $19.99/year, or $39.99 lifetime. | Core log/garage advertised as unpaywalled. Advanced wear database, full e-bike support, family sharing and CSV/PDF export are Pro. Exact free feature boundaries need testing. [Store](https://apps.apple.com/us/app/cogbook-bike-maintenance/id6782335042?platform=ipad). |
| **PedalCare** | Free download; Pro $2.99/month or $29.99/year. | Two bikes/core tracking free. Full history, part/cost insights, unlimited bikes and other advanced functions are Pro; free-history retention limit is unspecified. [Store](https://apps.apple.com/us/app/pedalcare-bike-maintenance/id6755446215), [developer](https://pedalcare.io/). |
| **mainTrack** | Free download; IAPs Coffee $1.99, Snack $3.99, Lunch $7.99, Dinner $13.99. | No subscription tier or feature gating described in the inspected listing; food-named purchases alone do not prove every function is unrestricted. [Store](https://apps.apple.com/us/app/maintrack/id1447308380). |
| **Hubtiger** | Free download; no IAP listed. | Rider app includes component/service and shop functions. Shop services can cost money; no documented rider feature limit found. The listing's latest version is dated September 2022, so current support needs checking. [Store](https://apps.apple.com/us/app/hubtiger-bike-management/id1370993581). |

## Workflow and capability comparison

| App | Entry and mileage model | Component/reminder model | Sync and portability |
| --- | --- | --- | --- |
| velohaus | Manual mileage/service logging; e-bike odometer explicitly supported. | Multiple bikes, component history, mileage/date reminders and custom reminder tasks. Arbitrary custom component definitions not established. | iCloud and optional two-person CloudKit sharing; machine-readable export unknown. |
| Velo Garage | Bike-first service ledger; manual use works without connections. Optional ride imports and assignment. | Distance, date and ride-hour reminders; product defaults and per-bike setup. | iCloud, backup/restore and service-history PDF. Backup exclusions matter; see below. |
| Loam MTB | Manual odometer or optional Strava/Health/file/Bosch sources. | Independent part clocks against published service schedules; fork/shock ride hours separate from motor-on time. | Local-first, optional encrypted recovery-code backup. Live iCloud sync not established. |
| ProBikeGarage | Strava-centered bikes/rides; exact standalone absolute-odometer workflow unknown. | User-defined parts, installation periods, ride-type setups, component grouping, multiple reminder metrics. | Service backend and device/web sync; Premium smart-sync/attachment features. File-export details unknown. |
| Cogbook | Explicit manual mileage alternative to Health import. | Per-bike service records, brand catalog, distance/hour/calendar thresholds, e-bike battery cycles/motor service. | iCloud; CSV/PDF export is Pro. |
| PedalCare | Baseline service questionnaire, bike types/specs, optional ride-source connection. | Service windows, notes/costs/receipts, e-bike inactivity reminder. Wear-profile questionnaire is described as groundwork for future smarter estimates. | Hosted integrations documented; iCloud/complete portable backup not established. |
| mainTrack | Strava or manually recorded activities; absolute odometer entry unknown. | Create components, share/move them between bikes, installation periods; time/usage/ride-count schedules. | Multiple-device synchronization advertised; iCloud mechanism and export unknown. |
| Hubtiger | Strava-centered tracking plus opening mileage balance and DIY service records. | Component history, invoices/attachments and shop-booking workflow; bike-type-based component suggestions. | Account/shop-oriented service; iCloud, complete export and arbitrary custom components unknown. |

The table summarizes the app-specific evidence below. Unknowns are deliberate;
we should not infer a missing feature from a sparse store description.

### velohaus: a strong minimalist/privacy reference

Its official site separates garage, bike details, timeline and reminders. Optional
purchase/serial/insurance fields add depth without defining the main value. It
explicitly stores records locally/in the user's iCloud, schedules notifications
locally, and says it has no analytics or third-party SDKs. Partner sharing is
CloudKit sharing between two accounts. Its store description specifically mentions
manual e-bike odometer history. These are close to CycleWrench's preferences;
custom reminders do not establish custom component definitions or learned means.
[Product/privacy](https://velo.haus/), [listing](https://apps.apple.com/us/app/velohaus/id6775131677).

**Lesson:** keep login out of onboarding, surface service timelines one level
below the bike, and make household sharing a later extension rather than a
prerequisite. The feature existence is documented; ease of use is still untested.

### Velo Garage: useful depth, significant scope to resist

The documented loop is due work → selected service/product → completed record.
Connections are optional. Its breadth includes fit, pressure, recovery, security,
shop requests and receipt scanning. Official release notes describe backdated
services using historical odometers, editable duplicate ride handling, and
manufacturer-sourced product intervals that do not overwrite user values.
[Product](https://velogarage.app/), [updates](https://velogarage.app/updates/).

Support explicitly says imported rides/health are excluded from backups, despite
broader backup claims. That distinction matters for restore promises. The listing
also documents iCloud and a service-history PDF.
[Support](https://velogarage.app/support), [listing](https://apps.apple.com/us/app/velo-garage-service-tracker/id6760527480).

**Lesson:** take historical odometers, reversible duplicate handling, per-bike
defaults and export; leave calculators, shop logistics and training data outside
the first release. State exactly what backups contain.

### Loam MTB: the clearest domain-specific service model

Loam documents manual and connected sources, independent component clocks and
hour-based suspension service. Its product presentation uses component progress
against cited manufacturer schedules. That is an interval estimate, not measured
physical wear or documented learning from the rider's replacement samples.
[Product](https://loamlog.com/mtb/), [listing](https://apps.apple.com/us/app/loam-mountain-bike-service/id6781034553).

Its Bosch guide is unusually concrete: Smart System, EU account, per-bike Data Act
sharing and vendor approval; non-EU riders get a manual/Strava alternative. It
uses the drive-unit odometer for distance and actual rides for suspension hours,
with background refresh rather than a ride-finished Bosch webhook.
[Bosch guide](https://loamlog.com/mtb/bosch).

**Lesson:** label each clock's source, keep unknown wear unknown, distinguish
service kinds and ride hours, and describe regional integration requirements
before offering a connection button. Its encrypted backup is not evidence of
simultaneous iCloud-style device synchronization.

### ProBikeGarage: component lifecycle modeling worth studying

Beyond scheduled alerts, official documentation supports custom components,
cloning repeated consumables, installation/removal periods and nested groups such
as wheelsets. Ride-specific setups can omit trainer-unused parts. This is richer
than a flat component-type journal, but adds setup effort.
[Catalog/custom parts](https://www.probikegarage.com/blog/2018/09/18/add-components-with-one-click.html),
[grouping](https://www.probikegarage.com/help/grouping-components.html),
[overview/help](https://www.probikegarage.com/help/).

Its privacy policy describes server-held tracking-app tokens, activities,
account/contact data and device identifiers. This differs from private CloudKit,
without by itself establishing bad practice.
[Privacy](https://www.probikegarage.com/privacy.html).

**Lesson:** eventually model an actual installed chain or wheelset separately
from “chain” as a category. Do not require catalog selection or recursive part
installation just to record a replacement. Paid download and optional Premium
should be communicated separately; “free baseline” is otherwise confusing.

### Cogbook: direct overlap and a warning against vague positioning

Its documented onboarding adds bikes, chooses components, tracks manual/Health
mileage, sets alerts and consults history/costs. A large brand catalog is optional
paid depth; reminders support distance, hours and calendar. E-bike features include
battery cycles and motor servicing, not an established Bosch connection. iCloud
and CSV/PDF are explicit, with export in Pro.
[Developer workflow/features](https://develak.com/fr/applications/cogbook/),
[listing/prices](https://apps.apple.com/us/app/cogbook-bike-maintenance/id6782335042?platform=ipad).

Develak's privacy policy states no separate account, on-device data/exports,
optional private CloudKit and no third-party tracking SDKs.
[Privacy](https://develak.com/privacy-policy/).

**Lesson:** “bikes rather than rides” and “private iCloud” are already occupied
positions. CycleWrench should demonstrate its shorter flow and transparent
personal-interval calculation rather than making broad uniqueness claims.

### PedalCare: richer records, but distinguish shipping intelligence from plans

Its baseline questionnaire addresses already-used parts rather than assuming new
parts at zero. Records can have parts/labor costs, notes, photos and receipts;
its app advertises e-bike inactivity reminders and bike-specific spec sheets.
The September release note calls the wear-profile questionnaire preparation for
future smarter wear estimates; it does not establish a shipped learning model.
[Developer](https://pedalcare.io/), [listing](https://apps.apple.com/us/app/pedalcare-bike-maintenance/id6755446215).

The App Store privacy disclosure includes identifiers used for tracking and linked
contact/user content. That is a disclosed model, not an independent audit or proof
that every user is tracked.

**Lesson:** adopt an optional baseline/import step and optional warranty/cost
records. Do not ask for terrain/riding-style questionnaires until they materially
change an explainable calculation. Keep a full personal history usable over time.

### mainTrack: the value of arbitrary parts and several clocks

Official sources establish custom-created components, cross-bike installations,
manual activities/Strava, multiple-device synchronization and schedules by elapsed
time, usage and rides. This covers unusual assemblies without an exhaustive
catalog. Its backend privacy policy describes server/device usage information;
private iCloud and export are not established.
[Product](https://maintrack.app/), [listing](https://apps.apple.com/us/app/maintrack/id1447308380),
[privacy](https://maintrack.app/privacy-policy).

**Lesson:** generic names plus defaults are enough to start. Cross-bike installed
part tracking is useful later, but should not force every rider into inventory
management. Food-named IAPs look like support purchases; their precise behavior
remains untested, so do not assert all functionality is unrestricted.

### Hubtiger: shop handoffs and a caution about growing the navigation

The listing documents DIY service notes/attachments, shop bookings/messages,
component mileage and multiple bikes. Historical developer release notes also
mention bike-type component suggestions, opening-mileage corrections, and retired
component mileage. These establish prior documented features, not their quality
on current iOS. The last displayed update is September 2022.
[Listing and developer release notes](https://apps.apple.com/us/app/hubtiger-bike-management/id1370993581).

**Lesson:** retain retired components and service receipts, and make a mechanic
handoff possible through an export. A shop marketplace, group rides and social
features add little to this user's primary two-field job. Current reliability and
support require hands-on verification; old reviews are not evidence of a current
bug.

## What the evidence does and does not establish

- **Personalized averages:** none of the inspected descriptions clearly specifies
  arithmetic/median lifespan learned solely from completed personal replacement
  intervals. That remains a possible differentiation, not proof competitors lack it.
  “Smart wear,” progress gauges, service windows and durability comparisons are not
  enough to infer the model.
- **Custom components:** directly established in ProBikeGarage and mainTrack.
  Custom reminders, custom bike makes/models and brand catalogs are different
  capabilities and should not be counted as arbitrary component support.
- **Bike configurations:** several apps cover bike types or ride-specific setups.
  No inspected source establishes the exact regular/electric × suspension × brake
  filtering rules now used by CycleWrench; hands-on testing could reveal similar UX.
- **Bosch:** Loam documents a real Smart System/EU Data Act path. A generic “e-bike
  ready” or Health/Strava connection does not establish direct Bosch odometer access.
- **Sync versus backup:** cross-device synchronization, encrypted recovery,
  one-way PDF export and complete round-trip backup solve different problems.
- **Open source:** no inspected official app/product page links an open-source
  repository for these eight apps. Their source/license status is **unverified**;
  do not label them closed-source solely from that absence.
- **UX:** no hands-on tap counts or speed claims are available. All workflow
  comparisons concern documented structure, not tested interaction quality.

## Ranked near-term features for CycleWrench

These are recommendations inferred from the evidence and the user's stated goal,
not assertions that competitors prove a specific implementation is best.

| Rank | Feature | Why it earns its place | Minimal version |
| --- | --- | --- | --- |
| 1 | Correct, backdate and undo work | A wrong interval undermines every estimate; Velo Garage explicitly fixes historical odometer handling. | Edit component/action/reading, optional known date, delete with undo; keep undated records honestly undated. |
| 2 | Complete portable backup and verified restore | User explicitly fears losing history. Cloud sync propagates deletions; export provides a separate recovery path. | Round-trip JSON containing bikes, custom definitions, units, date certainty, notes and stable IDs; CSV for inspection. Test restore on a disposable store. |
| 3 | Fast component actions and repeat work | Catalogs and richer records can add setup cost. User wants defaults, custom parts and compact screens. | Last bike/reading, component-specific default action, front/rear modifier, “repeat” without copying the old odometer. Keep details collapsed. |
| 4 | Explainable personal intervals | Current market language often conflates mileage counters and wear. | Show sample count, median/mean and range, latest reset, and calculation source. With one sample, say early estimate; avoid fake precision. |
| 5 | Several clocks and service types | Loam, mainTrack and ProBikeGarage document multiple interval metrics. | Optional calendar reminder and manual ride-hours total; fork lowers/full service can have separate clocks. Do not force hours entry. |
| 6 | Optional notes, cost and warranty context | Receipts and labor/parts splits recur in richer competitors; a warranty replacement may otherwise be forgotten. | Note plus optional cost and warranty flag; unknown amount differs from zero. Later add receipt attachment. |
| 7 | Per-component history/details | Aggregates hide the evidence and make errors hard to correct. | Tap component → replacement/service events, completed intervals and editable notes. Keep this off the main logging screen. |

For the first release, finish ranks 1–4 before adding more external services.
Motor/battery events with unknown date or mileage should be recordable as incomplete
history, then excluded from numerical interval samples until the missing reading
is recovered. Do not manufacture a zero-mile battery installation just to satisfy
a required field.

## Later opportunities

1. **Installed-part identities and swaps:** retain a particular chain/wheelset's
   life across bikes; support chain rotation and retired components. Introduce only
   when the simpler type-level model is insufficient.
2. **HealthKit first, other integrations second:** one optional read-only ride source
   can reduce effort without a mandatory external account. Avoid double-counting
   the same ride across sources. Validate permissions and bike assignment.
3. **Bosch after access is proven:** explicit bike link, absolute odometer with
   source/timestamp, lower-reading reconciliation, manual fallback. Regional
   eligibility precedes a shipping promise.
4. **Small widget/Shortcut:** expose “log service” or nearest attention, without
   growing a full watch/training experience.
5. **Household sharing or mechanic PDF:** velohaus demonstrates shared garage value;
   Velo Garage shows controlled handoff. Read-only/shareable records may be enough
   before collaborative editing.
6. **Cited manufacturer presets:** optional starting point, always distinguish
   guidance from measured condition and from the rider's own completed intervals.

## Patterns to avoid

- Requiring a Strava account, brand catalog or full bike specification before the
  first manual entry. Unknown setup should not make the app unusable.
- Describing distance-used percentages as physical wear measurements or promising
  failure prevention from a historical average.
- Mixing replacement, inspection, lubrication and a full suspension rebuild into
  one reset or mean. Keep each action/service type interpretable.
- Averaging across bikes or materially different component models without saying
  so; mixing miles/km; treating an unknown initial lifetime as zero.
- Treating a moving-time or motor-on counter as suspension riding hours.
- Calling cloud account availability “backed up,” or a PDF report a restorable archive.
- Expanding into weather, race calendars, social feeds, shopping and shop booking
  before the maintenance journal is trustworthy.
- Copying competitor wording, proprietary artwork or exact screen compositions.
  Borrow interaction principles and domain lessons, then design independently.

## Positioning and validation

Proposed positioning: **“Your bike's service notebook. Log a reading and the work;
learn how your parts last.”** The open-source repo can make calculations and export
formats inspectable. Keep that promise narrower than a universal mechanic, ride
tracker or manufacturer's service authority.

A later hands-on study should use a fresh test bike in each app and the same
synthetic sequence: add bike at 1,000 mi; replace chain at 1,000 and 1,750; log a
service; update to 2,000 without service; add a custom part; correct a mistaken
reading; export; reinstall/restore on a test account where practical. Record
actual taps, required fields, offline behavior and what happens to the learned
interval. Do not enter or modify the user's Orbea Wild records.

## Source inventory

The 24 linked pages comprise eight US App Store listings and sixteen official
pages: velohaus product/privacy; Velo Garage product, support and updates; Loam
MTB product and Bosch guide; ProBikeGarage product/pricing, catalog/custom-parts,
grouping, help and privacy; Cogbook product and Develak privacy; PedalCare product;
mainTrack product and privacy. Repeated links count once.
