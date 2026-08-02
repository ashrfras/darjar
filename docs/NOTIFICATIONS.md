# DarJar notifications

DarJar has six notification types:

- `postCreated`: a resident created a post.
- `postLiked`: a resident liked another resident's post.
- `postCommented`: a resident commented on another resident's post.
- `duesOverdue`: a resident's dues became overdue.
- `duesMarkedPaid`: management recorded a resident's dues as fully paid.
- `budgetChanged`: a manual finance transaction changed the residence budget.

Posts remain the source of important news and alerts. A post notification only
says who added a post and links to that post.

The trusted sender is implemented as a Dart Cloud Run service in
`backend/notifications`. Deployment and platform setup are documented in
`docs/NOTIFICATIONS_BACKEND_SETUP.md`.

## Durable inbox

The trusted sender writes one document per recipient to:

```text
users/{recipientUserId}/notifications/{notificationId}
```

Required fields:

```text
type: postCreated | postLiked | postCommented | duesOverdue | duesMarkedPaid | budgetChanged
residenceId: string
recipientUserId: string
occurredAt: timestamp
targetId: string
actorName: string
periodKey: string
readAt: timestamp | null
```

The client can only read its own inbox and update `readAt`. Creating notification
documents is reserved for the Firebase Admin SDK, which bypasses client security
rules.

## Push payload

After writing the inbox document, the trusted sender sends an FCM notification
message to every active token in:

```text
users/{recipientUserId}/pushTokens/{tokenId}
```

The FCM `data` payload uses the same identifiers:

```json
{
  "notificationId": "notification-id",
  "type": "postCreated",
  "residenceId": "residence-id",
  "recipientUserId": "user-id",
  "targetId": "post-id",
  "actorName": "Author name",
  "periodKey": ""
}
```

The notification payload contains the localized Push title and body. The data
payload is used only for navigation when the notification is opened.

## Event rules

- Do not notify the author of their own post.
- Send like and comment notifications only to the post author, and do not
  notify users about their own interactions.
- Send `duesMarkedPaid` only when a due transitions to `paid`, and only to
  active members assigned to that due's apartment.
- Create `duesOverdue` once when a due changes from payable to overdue.
- Create `budgetChanged` only for an added, edited, or deleted manual finance
  transaction. Do not emit it for a balance recalculation.
- Resolve recipients from active residence memberships on the trusted server.
- Never put FCM server credentials or a service-account key in the Flutter app.

## Platform setup still required

- Generate a Web Push certificate in Firebase and pass its public VAPID key with
  `--dart-define=DARJAR_WEB_PUSH_VAPID_KEY=...`.
- Upload the APNs authentication key to Firebase and enable Push Notifications
  for the iOS App ID and Xcode target.
- Enable the FCM HTTP v1 API for the Firebase project.

# خصوصية أسماء الأشخاص

تعرض المنشورات والإشعارات الاسم الأول والحرف الأول فقط من النسب. إذا بدأ
النسب بـ`الـ`، يُؤخذ الحرف الذي يليها؛ مثل `أشرف راس` ← `أشرف ر.` و
`كريم المنيعي` ← `كريم م.`. يطبق التطبيق هذه القاعدة أيضًا عند قراءة
إشعارات قديمة، ويطبقها الخادم قبل حفظ الإشعار وإرسال الـPush.
