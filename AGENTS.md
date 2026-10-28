# CycleWrench

Native iOS bicycle maintenance journal. Keep the main interaction simple:
odometer → select serviced/replaced components → save → history.

## Development
- Swift 6, SwiftUI, SwiftData; minimum iOS 17.
- Run `make generate` after modifying `project.yml` or adding/removing files.
- Run `make build` to verify compilation without signing.
- Run `make test` for regression tests; CI runs it on pushes and pull requests.
- Use synthetic/test bikes for all testing. Never modify Orbea Wild for tests.
- Edit `project.yml`; generated Xcode projects are ignored.
- Keep dependencies minimal. No account or network service is required.
- Preserve persisted component raw values and plan migrations for schema changes.
- Keep front/rear components separate. Support all bicycles, not motorcycles.
- Add meaningful tests for future lifespan calculations and data migrations.
- Make focused commits as work is completed; keep private rider archives out of Git.
- Never commit signing identities, profiles, API keys, or contributor-local signing overrides.
- `project.yml` intentionally contains the default project team ID; it is not a signing credential.

## Product constraints
- Distances have explicit units; never subtract miles from kilometers.
- Lifespan estimates must use completed replacement intervals for the same bike,
  component and unit, excluding the unknown distance before its first record.
- Servicing and replacement are distinct events; service does not automatically
  imply a component was replaced.
- Suspension service can depend on hours; mileage is not a manufacturer service rule.

## Persistence and sync
- Signed device builds use the private CloudKit container `iCloud.com.cyclewrench`.
- Keep synced fields optional or provide defaults; do not add unique constraints.
- Preserve existing stores on startup/migration failures. Never silently reset data.
- Simulator builds use local storage; cloud sync requires signed-device verification.
- Units are an app-wide display preference. Convert stored readings explicitly before comparing them.
- Undated imports must remain visibly undated. Unknown work must not become an inferred replacement.
