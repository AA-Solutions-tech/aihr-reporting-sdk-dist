# aihr_reporting_sdk

A Flutter widget that shows the NizamyAI Reporting chat to a company's managers.
They ask about attendance, check-ins, lateness, shifts, leave and ROI in English
or Arabic, and get short answers with KPI cards, charts and tables, plus
suggested follow-up questions. Numbers come live from your Nizamy APIs on every
question.

**Integration steps:** see [`MRHR_REPORTING_SDK_INTEGRATION_GUIDE.md`](MRHR_REPORTING_SDK_INTEGRATION_GUIDE.md).

## At a glance

```yaml
dependencies:
  aihr_reporting_sdk:
    git:
      url: https://github.com/AA-Solutions-tech/aihr-reporting-sdk-dist.git
      ref: v0.1.0
```

```dart
AiHrReportingWidget(
  authToken: accessToken,
  onAuthError: (reason) => refreshTokenAndRebuild(),
  onClose: () => Navigator.of(context).pop(),
)
```

- The chat page is hosted by the AI-HR backend, so chat changes reach every
  installed app without a new package version.
- The token is kept in memory only. Nothing is stored on our side: no copy of
  your data and no chat history.
- The chat follows your platform's access rules; you decide where its entry
  card appears.
- Only the internet permission is needed; see the guide, Section 4.
