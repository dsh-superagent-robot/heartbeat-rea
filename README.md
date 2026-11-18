# Heartica

A SwiftUI reconstruction of the Heartica heart-health app, built from the
requirements document provided in
[issue #1](https://github.com/dsh-superagent-robot/heartbeat-rea/issues/1).

The app is an iPhone-only wellness application: measure heart rate with the
camera, review derived HRV metrics, log blood pressure / oxygen / glucose, read
educational insights, follow multi-day protocols and health journeys, and manage
reminders and preferences.

## Requirements

- Xcode 15+ (built and verified with Xcode 27.1)
- iOS 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build & run

```bash
xcodegen generate
open Heartica.xcodeproj
```

Or from the command line:

```bash
xcodegen generate
xcodebuild -project Heartica.xcodeproj -scheme Heartica \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Run the unit tests:

```bash
xcodebuild test -project Heartica.xcodeproj -scheme Heartica \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

`project.yml` is the source of truth for the Xcode project; the generated
`Heartica.xcodeproj` is intentionally git-ignored.

## Structure

| Path | Contents |
|---|---|
| `Heartica/App` | App entry point, root routing, global state |
| `Heartica/CoreData` | Programmatic Core Data model (`HeartRate_2.6` entities) and data store |
| `Heartica/Models` | Domain models, metric bands, generated achievement/journey catalogs |
| `Heartica/Services` | Measurement engine, camera, HRV, CSI, Heart Age, progress |
| `Heartica/Features` | Onboarding, Home, Measure, Dashboard, History, Me, Insights, protocols and settings |
| `Heartica/Support` | Theme, persisted keys, profile storage, remote-config defaults |
| `HearticaTests` | Unit tests for HRV, bands, conversions, catalogs and profile calculation |

## Implemented scope

- Splash gating, 7-screen onboarding (stories, embedded trial offer, profile form)
  and the 9-step post-onboarding flow (Apple Health, profile review, quizzes,
  calculation, first risk report).
- Camera PPG pipeline with threshold gating, peak detection, two-layer NN
  validation, IQR filtering and pulse / SDNN / RMSSD / pNN50 / stress / energy /
  health-index / CSI derivation. In the simulator a synthetic PPG sensor is used
  so the flow can be exercised without a camera.
- Home carousel and cards, 8-card Dashboard with Swift Charts, chart settings,
  month-by-month History with edit/delete and a shared tag filter.
- Measurement results with the eight metric cards, status bands, AI-style
  comment, tagging and trends.
- Blood pressure, oxygen and glucose logging with clinical bands, unit
  conversion, tags and history.
- Me statistics with D/W/M/3M/Y windows, achievements (21 achievements, all
  tiers) and a 12-chapter / 100-level Journey.
- Insights reader (sample article set), Monthly Insights (premium-gated),
  Chronic Stress Index and Heart Age protocols, reminders with local
  notifications, Settings/Profile/Appearance, legal web views, What's New and a
  simulated paywall.

## Data & privacy

Health records are stored locally in Core Data; the profile is stored in
`UserDefaults`. The app makes no network requests. Purchase flows are simulated
locally (no StoreKit products are configured) and do not charge anything.

## Known limitations

The source report describes assets, copy and configuration extracted from an IPA
that is not part of this repository. The reconstruction therefore documents these
deliberate substitutions:

- Illustrations, Lottie animations, videos and IPA imagery are replaced by
  programmatic SwiftUI artwork and SF Symbols.
- The article corpus is a representative sample (12 articles) of the 83-article
  original, with original-style educational copy rather than the IPA's
  `Articles.strings` content.
- The paywall, purchase/restore, analytics, remote config, Firebase and Adapty
  integrations are local simulations; no third-party SDKs are linked.
- Apple Health authorizes and previews recent heart-rate sample counts but does
  not import historical HealthKit records into the trend database.
- The exact stress / energy / health-index conversion equations were not
  recoverable from the binary; a documented linear mapping over the confirmed
  ranges is used.
- CSV/PDF export is represented by a share sheet with a text summary; Lottie
  reward animations and achievement claiming persistence are not reproduced.

Debug-only launch variables are available for review and screenshot capture:
`HEARTICA_DEMO=1`, `HEARTICA_TAB=0…3`, `HEARTICA_MEASURE=1`,
`HEARTICA_AUTOSTART=1`, `HEARTICA_SCREEN=history|achievements|journey|csi|heartage|monthly|settings`,
`HEARTICA_PREMIUM=1`, `HEARTICA_PAYWALL=1`.
