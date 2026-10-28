# Private iCloud sync

CycleWrench uses SwiftData with the private CloudKit database `iCloud.com.cyclewrench`.
The app identifier is `com.cyclewrench`. Data stays on the device for offline use;
sync happens asynchronously through the rider's Apple account, without a separate
CycleWrench account or server. Uploaded data can be downloaded after reinstalling
or on another device signed into the same iCloud account. Unsynced local changes
cannot be restored after uninstalling.

## Developer account setup (required)

1. In Apple Developer Certificates, Identifiers & Profiles, enable iCloud (CloudKit)
   and Push Notifications for `com.cyclewrench`. Create the container
   `iCloud.com.cyclewrench` and assign it to this App ID.
2. Run `make generate`. The generated project inherits development team
   `K3CQQKBR25` from `project.yml`. Open it in Xcode, sign into the owning developer
   account and refresh automatic provisioning. Keep signing credentials local.
   The iCloud container entitlement and remote-notification background mode are
   generated from `project.yml`.
3. Run a signed development build on a device signed into iCloud, with iCloud
   enabled for CycleWrench. Log some work, then check Settings → iCloud in the app.
   Account availability is not an upload confirmation. Last upload/download are
   observed Core Data CloudKit events for the current session, not guarantees that
   every current change has finished syncing.
4. In CloudKit Console, verify that the development schema and records exist.
   If record types need explicit initialization, follow Apple's SwiftData schema
   initialization procedure below using the same four model types (Bike, ServiceEntry, OdometerReading, CustomComponent) and store URL.
5. Deploy the development schema to Production in CloudKit Console before testing
   TestFlight/App Store builds. Development and Production are separate databases.
   Xcode/provisioning selects the appropriate environment when signing.

## Simulator and test builds

CloudKit works in Simulator too. Normal Xcode builds with code signing enabled
use private iCloud sync on both simulators and devices; there is no simulator-wide
opt-out in the app. In the simulator's **Settings** app, sign into an Apple Account
and enable iCloud for CycleWrench. Xcode's account is the developer/signing account;
the account inside the simulator owns the synced user data. They are separate
sign-ins.

`project.yml` expands `CycleWrenchCloudSyncEnabled` from `CODE_SIGNING_ALLOWED` into
the app's Info.plist. `make build`/`make test` explicitly set signing to NO so those
builds remain local without contacting iCloud. Debug launch environment
`CYCLEWRENCH_LOCAL_ONLY=1` can also force local storage for synthetic media capture.
Automated test hosts always use an isolated in-memory store, even if signing is on.
Unsigned/local and signed/cloud builds keep the same store URL, so enabling sync
can adopt existing local records without deleting the store.

Settings now reports the actual account state on cloud-enabled builds. Account
availability alone is not confirmation of upload or restore. Sign in separately
on every test simulator; do account-backed tests only with a disposable test bike
and test account/store. Do not use the rider's Orbea Wild as a test fixture.

## Required device acceptance check

- On device A, create a bike and log a service and an odometer-only update.
- Confirm an upload has completed, then verify the bike and both records appear
  on device B using the same account and CloudKit environment.
- Make an offline odometer update on each device, reconnect, and verify the
  highest recorded odometer survives. Readings are append-only; displayed mileage
  includes their maximum to protect against a stale mutable Bike record.
- After verifying uploads, reinstall on a test device and wait for the bike/history
  to restore. The app does not seed a new bike into an empty restored store.
- Sign out of iCloud or disconnect the network: local reads/writes should continue;
  Settings must not report unconfirmed changes as safely uploaded.

## Schema and migration

All synced scalar attributes have declaration-level defaults or are optional. No
unique constraints or required SwiftData relationships are used. Cross-model UUIDs
allow records to arrive out of order; unknown bikes' records remain stored until
their bike arrives. The legacy local store migrates additively; existing attributes
and component identifiers remain intact. Never delete/reset the store on errors.
CloudKit production schemas are additive: plan future changes accordingly.

The selected bike and display-unit preference currently stay local to each device;
bikes, service history and odometer readings sync. Units are global across bikes
within an installation and every stored distance carries its original unit.

## References

- [Apple: Syncing model data across a person's devices](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)
- [Apple: Enabling CloudKit in your app](https://developer.apple.com/documentation/cloudkit/enabling-cloudkit-in-your-app)
- [Apple: Setting up Core Data with CloudKit](https://developer.apple.com/documentation/coredata/setting-up-core-data-with-cloudkit)

Custom component restrictions use defaulted scalar fields, so existing catalog
items migrate as unrestricted and sync with their definitions. Restriction changes
do not alter stored service entries or their component-name snapshots.
