# AI-HR Reporting SDK — Integration Guide (Flutter)

How to embed the **NizamyAI Reporting chat** inside a Flutter app. Written for
the host app's developers (Nizamy / MRHR). The SDK ships as a single widget:
give it the logged-in user's access token, and you get a chat where managers ask
about their company data and get answers with KPI cards, charts and tables.

> Package: `aihr_reporting_sdk` · distributed publicly from
> `https://github.com/AA-Solutions-tech/aihr-reporting-sdk-dist.git`

---

## 1. What you're integrating

`aihr_reporting_sdk` is a thin Flutter package that renders the reporting chat
inside a WebView and passes it the user's session and language. Your app owns
login; the SDK keeps the token in memory only.

In the chat, a manager asks questions in English or Arabic, such as "Who was
late most this month?", "Who has not checked in today?", "Compare attendance
with last week" or "How much time did Nizamy save this month?". Each answer is
a short reply, with a card when the numbers need one (KPI tiles, a ranking, a
trend bar chart, a side-by-side comparison, an ROI donut or a table) and
suggested follow-up questions.

- **You provide:** the logged-in user's Nizamy access token, and a place to
  open the chat (for example an "Ask AI about your reports" card on your
  Reports screen).
- **The SDK provides:** the whole reporting chat as one widget,
  `AiHrReportingWidget`.
- **The SDK talks to:** the AI-HR backend (`https://hr.aasolutions.tech`) for
  the chat. The backend reads the numbers live from your Nizamy APIs on every
  question.

Nothing else — no WebView setup, no JS bridge — is exposed.

### What is stored

Nothing on our side: no copy of your company data and no chat history. The
conversation lives in the page's memory on the phone and is gone when the
screen closes. The token is never written to disk or put in a URL.

---

## 2. Prerequisites

- **Flutter** `>=3.16.0`, Dart `>=3.0.0`.
- **No repo access needed.** The dist repo is public, so `flutter pub get`
  works on any machine (developer laptops and CI).
- **One dependency.** The SDK depends only on `flutter_inappwebview ^6.0.0`.
  If your app already uses it, use a compatible version.

---

## 3. Add the dependency

In **your app's** `pubspec.yaml`, add a git dependency pinned to a version tag:

```yaml
dependencies:
  aihr_reporting_sdk:
    git:
      url: https://github.com/AA-Solutions-tech/aihr-reporting-sdk-dist.git
      ref: v0.1.0        # pin an exact version — do not use a branch
```

Then:

```bash
flutter pub get
```

> `flutter_inappwebview` comes in automatically as a transitive dependency —
> you don't add it yourself.

**Upgrading later:** bump `ref:` to the new tag (e.g. `v0.2.0`) and run
`flutter pub get` again. Versions are immutable — a given tag always resolves
to the same build.

---

## 4. Required platform configuration

The chat loads from our servers over `https://`. The SDK uses no location,
camera, microphone or biometric features.

### Android

Make sure your app has the internet permission in
`android/app/src/main/AndroidManifest.xml` (most apps already do):

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS

No changes needed.

---

## 5. Open the chat

There is no separate "launch" — you route to the widget from your own entry
point (for example the AI Reporting card under the date selector on your
Reports screen). Import it:

```dart
import 'package:aihr_reporting_sdk/aihr_reporting_sdk.dart';
```

### As a full screen (most common)

Put the widget in a page of its own that keeps the token in its own state
(the full page is in Section 8):

```dart
// In the State of your chat page
AiHrReportingWidget(
  authToken: _token,                     // the logged-in user's Nizamy access token
  language: 'ar',                        // optional; defaults to the app locale
  onAuthError: (reason) async {          // token rejected: get a fresh one, rebuild with it
    final fresh = await widget.session.refreshAccessToken();
    if (mounted) setState(() => _token = fresh);
  },
  onClose: () => Navigator.of(context).pop(),
)
```

Then open that page from your entry point:

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => ReportingChatPage(session: session)),
);
```

> Keep the token in the chat page's own state. Calling `setState` in the
> screen that opens the chat does not rebuild the pushed page, so the widget
> would keep the old token.

The widget fills its parent, so give it a sized container (a `Scaffold` body,
an `Expanded` — anything with bounded height). The chat has its own header
with a back arrow, which calls `onClose`.

---

## 6. The session contract

| Parameter | Type | Meaning |
|---|---|---|
| `authToken` *(required)* | `String` | The user's **live** Nizamy access token. Sent as `Authorization: Bearer <token>`. Held in memory only; never persisted by the SDK. Rebuild the widget with a new value after a refresh: the page swaps it in without reloading and keeps the conversation. |
| `language` | `String?` | `'en'` or `'ar'`. Leave it out to follow your app's locale (`Localizations.localeOf(context)`). Arabic switches the whole chat, cards included, to right-to-left. |
| `onAuthError` | `void Function(String? reason)?` | Our backend rejected the token (expired or invalid). Refresh it with your login flow and rebuild the widget with the new `authToken`. |
| `onClose` | `VoidCallback?` | The user tapped the back arrow in the chat header. Close the screen. |

### Who can use it

The chat follows your platform's access rules. Today it is available to the
roles that manage a company — Owner, Admin and Manager — and shows each of them
the same company data your own dashboard shows them. Any other role sees "AI
Reporting is not available for your account." You decide where the entry card
appears and who sees it.

> **Auth model:** your app owns login. Our backend checks the token with your
> Nizamy server, and the company comes only from that checked token, never from
> anything the phone sends.

---

## 7. Messages the user can see

These appear inside the chat; your app does not need to handle them, apart
from `onAuthError`.

| Message | When | What your app does |
|---|---|---|
| "Could not load reporting. Check your connection." with **Retry** | The chat page could not load (no internet, or our server is unreachable). | Nothing; the user taps Retry. |
| "Your session has expired. Reconnecting…" | Our backend rejected the token (HTTP 401). | `onAuthError` is called: refresh the token and rebuild the widget. |
| "AI Reporting is not available for your account." | The user's role does not have reporting access (HTTP 403). | Nothing; consider hiding the entry card for that role. |
| "You have asked a lot of questions in a short time…" | More than 60 questions from one user in an hour (HTTP 429). | Nothing; it clears by itself. |
| "Sorry, something went wrong. Please try again." | Your Nizamy server or ours had a temporary problem. | Nothing; the user can ask again. |
| A note under an answer, e.g. "No records for this period." | The data for that question is missing or incomplete (no records, no schedule, a period still in progress, a definition pending your approval). | Nothing; the answer says what is missing instead of showing unverified numbers. |

All messages are shown in Arabic too when the chat language is Arabic.

---

## 8. Full minimal example

```dart
import 'package:flutter/material.dart';
import 'package:aihr_reporting_sdk/aihr_reporting_sdk.dart';

class ReportingChatPage extends StatefulWidget {
  const ReportingChatPage({super.key, required this.session});

  final Session session;   // your app's session object

  @override
  State<ReportingChatPage> createState() => _ReportingChatPageState();
}

class _ReportingChatPageState extends State<ReportingChatPage> {
  late String _token = widget.session.accessToken;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AiHrReportingWidget(
          authToken: _token,
          onAuthError: (reason) async {
            final fresh = await widget.session.refreshAccessToken();
            if (mounted) setState(() => _token = fresh);
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
```

Open it from your Reports screen:

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => ReportingChatPage(session: session)),
);
```

---

## 9. Troubleshooting

| Symptom | Likely cause |
|---|---|
| **"Could not load reporting"** | No internet connection, or our server is unreachable. The chat loads from our servers; there is no offline copy. |
| **"Your session has expired" keeps coming back** | `onAuthError` is not wired, or the widget is not rebuilt with the refreshed token. |
| **"AI Reporting is not available for your account"** | The user's role does not have reporting access (Section 6). |
| **Answers say "No records for this period"** | Your attendance report has no rows for those days in that company. Try another period, or check the data in your Reports screen. |
| **Answers say days had "no schedule"** | People checked in, but those days had no shift assigned in Nizamy, so attendance and lateness cannot be measured. |
| **"Your session has expired" with a valid token** | The company is not registered with AI-HR yet. Our backend only accepts tokens of registered companies; contact the AI-HR team to register it. |
| **Chat shows English in an Arabic app** | `language` was passed as `'en'`, or your app's locale is English. Leave `language` out to follow the app locale. |
| **Links inside the chat do nothing** | By design: navigation is locked to the reporting page; any other link is blocked. |
| **Build fails on Android** | A `flutter_inappwebview` version conflict with your app; align both on a compatible 6.x version. |

---

## 10. Versioning

- Each release is an immutable tag (`v0.1.0`, `v0.2.0`, …) on the dist repo.
- Pin an exact tag in `pubspec.yaml`; never track a branch.
- To adopt a new version, bump `ref:` and run `flutter pub get`.
- **Chat changes need no rebuild.** The reporting chat loads live from our
  servers (`https://hr.aasolutions.tech/HR/aihr-reporting-app/`), so new
  questions, cards and wording reach your users automatically on our next
  deploy — no action needed on your side.
- **A rebuild is still required when a release changes something native** —
  a new widget parameter or a new platform requirement. In that case: bump
  `ref:`, run `flutter pub get`, and rebuild/re-release your app as usual.

---

*Questions or a new build? Contact the AI-HR team.*
