# Importing maintenance notes

Settings → Your data → Import service log accepts a JSON archive. The preview
shows the bike, source unit, record count and how many records have no date.
Importing the same archive again merges its records without duplicating them.
Personal archives belong outside source control; `work/` is ignored.

```json
{
  "version": 1,
  "id": "7e541c9f-bcbf-4dad-bd86-4195e470e726",
  "bikeName": "Example bike",
  "distanceUnit": "mi",
  "records": [
    {
      "id": "chain-100",
      "component": "chain",
      "action": "replaced",
      "odometer": 100
    },
    {
      "id": "frame-bearings-300",
      "component": "bearings",
      "action": "unspecified",
      "odometer": 300,
      "notes": "All frame bearings"
    }
  ]
}
```

- `id` is a stable UUID identifying the bike/archive. Every record needs its own
  stable string `id`. Keep both unchanged for repeat imports.
- `distanceUnit` is `mi` or `km`. Inputs convert to the bike's stored unit;
  history and estimates display in the global unit preference.
- `component` uses the stable `BicycleComponent` raw values in ServiceEntry.swift.
  A paired service should have two records, e.g. `fork` and `rearShock` or
  `frontBrakePads` and `rearBrakePads`.
- `action` is `replaced`, `serviced`, or `unspecified`. Unknown actions stay visible
  as “Work recorded”; they do not create replacement/service interval samples.
- Optional `date` uses ISO 8601, e.g. `2026-01-02T12:00:00Z`. Omitting it displays
  “Date not recorded”. Undated notes are ordered by odometer for distance-based
  calculations; no calendar service date is invented.
- Optional `notes` is freeform text. Generic bearings can describe frame pivots,
  hub bearings, a particular linkage, or any other assembly without a catalog.

The bike starts at its highest imported reading. A bike with a higher existing
odometer keeps that total. Existing data on other bikes is untouched.

This is an additive service-log import, not a full backup/export of the database.
If imports are performed concurrently on two offline devices before sync, CloudKit
cannot enforce unique constraints. Prefer importing once, then allowing that bike
and its records to sync before importing it again elsewhere.

For development automation, a Debug-only `CYCLEWRENCH_IMPORT_ARCHIVE` launch
environment variable accepts base64-encoded archive JSON and uses the same
validated importer. Release builds do not read this variable. Do not add personal
archives to shared schemes, tests, fixtures, or Git commits.

Archives may include an optional `configuration` object alongside `records`:

```json
"configuration": {
  "drive": "electric",
  "suspension": "fullSuspension",
  "brakes": "hydraulicDisc"
}
```

Valid values are the raw enum cases in `BikeConfiguration.swift`. Configuration
only fills fields that are still unspecified; reimporting cannot overwrite a
rider's setup choices. `motor` and `battery` are supported component identifiers.
History imports remain valid even if a past component is hidden by today's setup.
