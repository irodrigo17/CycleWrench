# Optional Bosch odometer integration

Researched on October 27, 2026. No integration has been implemented, no Bosch
account has been accessed, and no credentials are required for this research.

## Recommendation

Investigate Bosch's **Connected Biking Platform / Cloud API for the eBike Flow
app** first. It is the most promising official route for an optional iOS
integration. Request developer onboarding information before committing to an
implementation or delivery date. Keep manual odometer entry fully functional.

The existence of public Bluetooth documentation does **not** establish that a
normal iPhone app can implement it. The current published protocol has specific
requirements that conflict with the public iOS advertising API.

## Official Bluetooth interface

Bosch's May 2026 Live Data Interface (LDI) exposes an odometer in meters,
without developer registration or API keys. It operates locally over Bluetooth;
it does not retrieve a Flow account's cloud history.

The bike is a GAP central and GATT server. The accessory must advertise as a
GAP peripheral, then act as a GATT client. The specification requires Service
Solicitation UUID and Appearance advertising fields. It explicitly excludes
smartphone support and calls out advertising and GATT-role restrictions.

The appendix identifies control-unit software **v19** as the first experimental
LDI release. Bosch states compatibility with Smart System remote-equipped bikes,
subject to change. The owner's model year alone does not confirm the installed
firmware. Check the control-unit software version and accessory-pairing options
in Flow before any hardware experiment. The first firmware also documents
MTU/DLE issues; default 23-byte MTU can truncate notifications.

Source: [Bosch LDI specification, sections 2.1.3–2.1.5 and appendix](https://www.bosch-ebike.com/fileadmin/EBC/Service/Downloads/LiveData/20260501_LiveDataInterface_V1_28042026.pdf).

Apple's `CBPeripheralManager.startAdvertising` supports only local-name and
service-UUID dictionary keys. It does not expose the LDI-required solicitation
and appearance fields through this API. Background advertising further restricts
discoverability: service UUIDs move into an overflow area discoverable by iOS
scanners, and the local name is omitted.

Source: [Apple Core Bluetooth advertising documentation](https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager/startadvertising(_:)).

Engineering conclusion: a standard foreground Core Bluetooth pairing screen is
not sufficient evidence of feasibility. An approved Bosch iOS SDK, future protocol
changes, or a separate accessory bridge may provide other routes. Do not rely on
private iOS APIs or undocumented Bosch authentication to ship this feature.

## Official cloud options

### Connected Biking Platform

Bosch currently advertises an **App and Service Provider** offering, with access
to Flow data after the rider grants permission. Its Flow offering lists the eBike
Profile API and Activity Records API. This is broader than the older
manufacturer-only SDK announcement.

The public page directs developers to contact Bosch. It does not establish
self-service access, pricing, availability for an independent open-source app,
region eligibility, exact odometer endpoint, or native-app authentication
requirements. Confirm these before implementing a client.

Source: [Bosch Connected Biking Platform](https://www.bosch-ebike.com/en/business/connected-biking-platform).

### EU Data Act portal

Bosch also provides a registered data-recipient path. The public portal requires
SingleKey ID login, acceptance of recipient terms, and client-application details
including login/recipient URLs. Bosch's Data Act page explicitly limits its
published offering to EU users. It should not be presented as a confirmed route
for a US rider.

Sources: [Bosch Data Act information](https://www.bosch-ebike.com/en/data-act),
[Bosch recipient onboarding portal](https://portal.bosch-ebike.com/data-act).

Unauthenticated official documentation did not establish whether either cloud
route supports public native clients with PKCE, requires a confidential client
and backend, offers polling/webhooks, or what its rate limits are. Bosch Smart
Home OAuth documentation is for a different product and must not be applied to
eBike APIs by assumption.

## Proposed optional product behavior

- Link the Bosch bike explicitly to a CycleWrench bike; do not match by name alone.
- Offer a deliberate **Read odometer** action first. Add background refresh only
  after access and reliability are proven.
- Import an absolute odometer with its source and retrieval timestamp. Do not
  silently add absolute totals to existing distance.
- Convert meters explicitly into the app's internal units, then use the global
  display preference.
- Treat lower readings, motor replacements, stale data, and conflicts as cases
  requiring reconciliation rather than overwriting a higher verified total.
- Keep manual entry available when offline, disconnected, unauthorized or unsupported.
- Store user tokens in Keychain. A confidential client secret, if required by
  Bosch, belongs on a backend, never in the open-source iOS app.

## Next feasibility work and rough effort

These are engineering estimates, not vendor commitments:

1. **Access check:** obtain Bosch's app-provider eligibility, regional support,
   read-only profile/odometer fields, freshness guarantees, authentication flow,
   rate limits, and terms. Vendor response time is unknown.
2. **Hardware check:** record the Wild's control-unit model and firmware; verify
   it is the Smart System associated with the user's Flow account.
3. **Cloud prototype after access:** roughly 2–4 engineering days for one-bike
   sign-in, identity selection and a verified odometer read if the API permits a
   straightforward native client. A backend requirement increases the scope.
4. **App-ready optional integration:** roughly 1–2 additional weeks for token
   lifecycle, errors, disconnect/revocation, units, reconciliation, privacy UX,
   multi-bike mapping, and device testing. Access approval is separate.
5. **Direct iPhone BLE:** treat as blocked by the documented interface mismatch
   until Bosch confirms an iOS-capable route. More implementation time alone does
   not resolve that mismatch.

A hardware bridge is technically plausible but adds a separate device and setup
flow; it is a poor default for CycleWrench's simple phone-first experience.
