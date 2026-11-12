## 1.1.1

* Support UAT zones (`uat-*`): verify the API key via `pit-api.xebo.ai`, and submit responses to `{zone}-api.xebo.ai` (UAT has no `-feedback-api` host). Applies to both `fetchAndPresentSurvey` and `showInAppSurvey`.

## 1.1.0

* Add `XeboSurveyManager.showInAppSurvey(...)` — a pure-Dart, cross-platform (iOS + Android) alternative to `fetchAndPresentSurvey` with granular lifecycle callbacks: `onLoading`, `onLoadFailed`, `onCompleted`, `onDismissed`, `onPartialResponse`, `onSubmissionSucceeded`, `onSubmissionFailed`. No native platform-channel dependency — but its network flow deliberately mirrors the native iOS SDK's own `XeboSurvey.inAppSurvey(...)` session semantics (see `xebo_in_app_survey_service.dart`):
  * fetches the survey *draft* directly by `surveyId` (collectorId passed as a header), no separate collector→surveyId lookup;
  * a failed key-verify isn't fatal — falls back to the raw api key;
  * `collectorId` is resolved to its uuid only at submission time, only if it isn't already uuid-shaped;
  * `onCompleted` fires immediately on the last answer; submission runs in the background and the sheet auto-dismisses ~2s later regardless of outcome;
  * `onPartialResponse` fires unconditionally on an early skip, even with zero answers.
* `XeboSurveySheet.onDismiss` now passes the answers collected so far, so partial-response reporting has real data to work with.

## 0.0.1

* TODO: Describe initial release.
