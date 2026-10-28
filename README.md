# CycleWrench

A simple, local-first bicycle maintenance journal for iOS.
Enter your current odometer, select the components you replaced or serviced,
and save. View your maintenance history in one list.

Supports bicycle drivetrain, brakes, tires, bearings and suspension components.
Built with SwiftUI and SwiftData. No separate app account, analytics, or third-party dependencies. Signed device builds use private iCloud sync.

## Get started

Requires Xcode with the iOS SDK, and XcodeGen 2.45 or later.

```sh
brew install xcodegen
make generate
open CycleWrench.xcodeproj
```

Choose an iOS simulator and run. For a device, select your development team in
Xcode and use the bundle identifier registered in your Apple Developer account.
The registered app identifier is `com.cyclewrench`. Configure the private CloudKit
container `iCloud.com.cyclewrench` following [iCloud setup](docs/iCloudSetup.md). Never commit developer-specific signing changes.

```sh
make build
```

`project.yml` is the source of truth; the generated Xcode project is ignored.
GitHub Actions regenerates the project and compiles for the iOS simulator.

## Initial scope

Supports multiple named bicycles, an app-wide kilometer/mile display setting, independent
odometers and service histories, multi-component logging, and odometer-only updates.
Readings cannot decrease. Existing history is adopted into a “My bike” record on first launch.
This is an additive SwiftData migration; original component identifiers and readings are preserved.

Component estimates show the average completed interval, sample count, distance
since the latest event and approximate distance remaining. The Components screen
sorts by remaining distance, with unknown intervals last. Approaching average means
20% or less of the historical average remains; passing it is not a wear measurement.
At least two records are needed. Replacement life and servicing intervals are
separate, and a replacement breaks the service cycle. Time/hour-based suspension
limits are not inferred from distance.

Settings applies kilometers or miles across all bikes and history. Existing stored
units are retained and explicitly converted before display and interval calculation.
New bikes store kilometers internally.

Next: editing/deleting entries, bike renaming, and export/backup.

## Distribution

App Store Connect app ID: **6827839532**.

Before distribution: verify the registered bundle identifier, configure signing,
add an app icon, complete privacy/support metadata, test on devices and submit
through TestFlight. The repository scaffold is not a release-ready submission.

## License

MIT. See [LICENSE](LICENSE).

## Tests

Choose an installed simulator and run:

```sh
make generate
xcodebuild -project CycleWrench.xcodeproj -scheme CycleWrench \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Tests cover migration from the original on-disk schema, idempotent legacy
adoption with mixed distance units, and odometer updates isolated by bike.

## iCloud

Signed device builds use private CloudKit sync. Apple Developer container setup,
provisioning and Production schema deployment are required before distribution.
See [setup and device acceptance checks](docs/iCloudSetup.md). Unsigned simulator
builds store data locally; cloud restore has to be verified on signed devices.
