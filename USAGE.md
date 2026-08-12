# xebo_survey_sdk — Usage Guide

## Setup (once, e.g. in `main()`)

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  XeboSurveyManager.instance.configure(
    apiKey: 'YOUR_API_KEY',
    collectorId: 'YOUR_COLLECTOR_ID',
    zone: 'az2', // az1, az2, az4, ... — whichever zone your account is in
  );

  runApp(const MyApp());
}
```

`configure()` also pre-fetches the survey used by `fetchAndPresentSurvey` in the background and starts network-connectivity monitoring (to auto-flush any offline-queued responses once connectivity returns).

## Theme — every field

```dart
configureTheme(const XeboThemeConfig(
  primaryColor: '#4F46E5',    // buttons, selected states, focus border. Default: #4F46E5
  backgroundColor: '#FFFFFF', // sheet background. Default: #FFFFFF
  textColor: '#1F2937',       // question/answer text. Default: #1F2937
  cornerRadius: 12,           // buttons, input fields, sheet top corners. Default: 12
  fontFamily: 'Inter',        // any font family bundled/available in your app. Default: system font
));
```

- Colors accept `#RRGGBB` or `#AARRGGBB` hex strings; anything unparseable falls back to the default for that field.
- All fields are optional — omit any you don't want to override.
- Call it once, anytime before showing a survey (typically alongside `configure()`).

## User identity — every field

```dart
XeboSurveyManager.instance.setUser(const XeboUserData(
  name: 'Jane Doe',
  email: 'jane@example.com',
  phone: '+1234567890',
  uniqueId: 'user-123',
  country: 'US',
  city: 'San Francisco',
  region: 'CA',
  eData: {'plan': 'pro', 'signupCohort': '2026-Q1'}, // arbitrary custom key/value pairs
));

XeboSurveyManager.instance.clearUser(); // reset to anonymous
```

These flatten into `custom_variables` on submission (`fName`, `email`, `mobile`, `unique_id`, `country`, `city`, `region`, plus each `eData` key) — they populate the identity/embedded-data columns on the Xebo dashboard. `setUser` is global — used by both functions below unless you don't call it at all (survey stays anonymous).

## Function 1 — `fetchAndPresentSurvey`

Uses the survey/collector/zone from `configure()`. Simple, no callbacks, pre-fetch means instant display on repeat calls.

```dart
ElevatedButton(
  onPressed: () async {
    await XeboSurveyManager.instance.fetchAndPresentSurvey(context);
  },
  child: const Text('Show Survey'),
)
```

Failures are only logged via `debugLog` (visible in your console as `[Xebo] fetchAndPresentSurvey failed: ...`) — nothing surfaces to your UI. If the network is down at submission time, the response is queued locally and retried automatically once connectivity returns (`flushOfflineQueue()` is also callable manually).

## Function 2 — `showInAppSurvey`

Independent survey/collector/zone per call, full lifecycle visibility.

```dart
await XeboSurveyManager.instance.showInAppSurvey(
  context: context,
  surveyId: 'YOUR_SURVEY_ID',
  collectorId: 'YOUR_COLLECTOR_ID', // uuid or dashboard id — either works
  zone: 'az4',
  xApiKey: '',                      // optional — empty reuses the key from configure()
  userData: const XeboUserData(     // optional — overrides setUser() for just this call
    name: 'Jane Doe',
    email: 'jane@example.com',
  ),

  onLoading: () {},
  onLoadFailed: (error) {},
  onCompleted: (response) {
    // {surveyId, collectorId, questions: [{uuid, answer: [{row_id, col_id, text}]}]}
  },
  onPartialResponse: (response) {},   // same shape, fires on early "Skip"
  onSubmissionSucceeded: () {},
  onSubmissionFailed: (error) {},
  onDismissed: () {},
);
```

Firing order — completion: `onLoading` → renders → `onCompleted` (immediate) → `onSubmissionSucceeded`/`onSubmissionFailed` (background) → auto-dismiss ~2s later → `onDismissed`.

Firing order — early skip: `onLoading` → renders → `onPartialResponse` → `onDismissed`.

Only one session at a time — a second call while one is active throws `StateError`.

## Supported question types (all 10 — auto-rendered, no config needed on your side)

Both functions render whatever question types the survey has configured on the Xebo dashboard, via the same internal widgets — you don't select a type yourself, it's driven entirely by the survey's own setup:

| Type | Renders as |
|---|---|
| `singleChoice` | Radio-style list, one selectable option |
| `multipleChoice` | Checkbox-style list, multiple selectable options |
| `dropdown` | Dropdown/picker of options |
| `singleTextBox` | One free-text input field |
| `multipleTextBox` | Multiple free-text input fields (one per row) |
| `nps` | 0–10 Net Promoter Score scale, with optional `npsLabels` (lower/upper text, detractor/passive/promoter colors) |
| `multiNps` | Multiple NPS scales in one question |
| `rating` | Star / heart / circle / tile / emoji rating icons (style + color set per-question on the dashboard) |
| `multiRating` | Multiple rating rows in one question |
| `thankYou` | Auto-appended closing screen — always the last "question" in every survey, not configurable, not counted toward your answered questions |

Each question can also carry (from the dashboard, automatically applied): `title`, `subtitle`/helper text, `placeholder` text, `isRequired`, and — for choice/NPS-Pro types — `conditionalFollowUps` (a follow-up question shown only for certain rating ranges).
