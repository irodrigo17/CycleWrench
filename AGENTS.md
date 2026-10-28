# CycleWrench

Native iOS bicycle maintenance journal. Keep the main interaction simple:
odometer → select serviced/replaced components → save → history.

## Development
- Swift 6, SwiftUI, SwiftData; minimum iOS 17.
- Run `make generate` after modifying `project.yml` or adding/removing files.
- Run `make build` to verify compilation without signing.
- Edit `project.yml`; generated Xcode projects are ignored.
- Keep dependencies minimal. No account or network service is required.
- Preserve persisted component raw values and plan migrations for schema changes.
- Keep front/rear components separate. Support all bicycles, not motorcycles.
- Add meaningful tests for future lifespan calculations and data migrations.
- Never commit signing identities, profiles, API keys, or developer-specific settings.

## Product constraints
- Distances have explicit units; never subtract miles from kilometers.
- Lifespan estimates must use completed replacement intervals for the same bike,
  component and unit, excluding the unknown distance before its first record.
- Servicing and replacement are distinct events; service does not automatically
  imply a component was replaced.
- Suspension service can depend on hours; mileage is not a manufacturer service rule.
