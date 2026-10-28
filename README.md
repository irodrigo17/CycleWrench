# CycleWrench

A simple, local-first bicycle maintenance journal for iOS.
Enter your current odometer, select the components you replaced or serviced,
and save. View your maintenance history in one list.

Supports bicycle drivetrain, brakes, tires, bearings and suspension components.
Built with SwiftUI and SwiftData. No accounts, analytics, or third-party dependencies.

## Get started

Requires Xcode with the iOS SDK, and XcodeGen 2.45 or later.

```sh
brew install xcodegen
make generate
open CycleWrench.xcodeproj
```

Choose an iOS simulator and run. For a device, select your development team in
Xcode and use the bundle identifier registered in your Apple Developer account.
The default identifier `com.irodrigo17.CycleWrench` is a placeholder until verified
against App Store Connect. Never commit developer-specific signing changes.

```sh
make build
```

`project.yml` is the source of truth; the generated Xcode project is ignored.
GitHub Actions regenerates the project and compiles for the iOS simulator.

## Initial scope

Supports multiple named bicycles, a fixed kilometer/mile unit per bike, independent
odometers and service histories, multi-component logging, and odometer-only updates.
Readings cannot decrease. Existing history is adopted into a “My bike” record on first launch.
This is an additive SwiftData migration; original component identifiers and readings are preserved.

Next: editing/deleting entries, bike renaming, export/backup and component
lifespan estimates from completed replacement intervals. Estimates must exclude
unknown initial lifetimes and separate servicing from replacement.

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
