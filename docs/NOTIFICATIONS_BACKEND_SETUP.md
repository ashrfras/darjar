# تشغيل خدمة إشعارات DarJar

الخدمة موجودة في `backend/notifications` وتعمل على Cloud Run باستخدام Dart.
تستقبل أحداث Firestore عبر Eventarc لتوليد الإشعارات وأنشطة الموجز، وتشغّل فحص
الواجبات المتأخرة يوميًا عبر Cloud Scheduler.

لا تنشئ أو تنزّل مفتاح service account. تستخدم الخدمة Application Default
Credentials الخاصة بحساب Cloud Run.

## 1. المتطلبات

- ثبّت Google Cloud CLI وسجّل الدخول: `gcloud auth login`.
- تأكد أن مشروع Firebase هو `raq-darjar`.
- اعرف موقع Firestore من Firebase Console > Firestore > Database details.
- اختر منطقة Cloud Run قريبة ومتوافقة مع موقع Firestore.

استخدم قيمتين في الأوامر:

- `FIRESTORE_LOCATION`: موقع قاعدة Firestore، وقد يكون multi-region مثل `eur3`.
- `RUN_REGION`: منطقة Cloud Run مثل `europe-west1`.
- `SCHEDULER_REGION`: منطقة تدعم Cloud Scheduler؛ يمكن أن تختلف عن Cloud Run.

يمكن معرفة القيمة الأولى عبر:

```bash
gcloud firestore databases describe \
  --database="(default)" \
  --format="value(locationId)"
```

القيم الحالية لمشروع `raq-darjar`:

```text
FIRESTORE_LOCATION=europe-southwest1
RUN_REGION=europe-southwest1
SCHEDULER_REGION=europe-west1
```

Cloud Scheduler غير متاح في `europe-southwest1`، لذلك تعمل المهمة المجدولة من
`europe-west1` وتستدعي خدمة Cloud Run الموجودة في مدريد.

## 2. تفعيل الخدمات

```bash
gcloud config set project raq-darjar

gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  eventarc.googleapis.com \
  firestore.googleapis.com \
  fcm.googleapis.com \
  cloudscheduler.googleapis.com
```

## 3. حسابات الخدمة والصلاحيات

حساب تشغيل الخدمة:

```bash
gcloud iam service-accounts create darjar-notifications-runtime \
  --display-name="DarJar notifications runtime"

gcloud projects add-iam-policy-binding raq-darjar \
  --member="serviceAccount:darjar-notifications-runtime@raq-darjar.iam.gserviceaccount.com" \
  --role="roles/datastore.user"

gcloud projects add-iam-policy-binding raq-darjar \
  --member="serviceAccount:darjar-notifications-runtime@raq-darjar.iam.gserviceaccount.com" \
  --role="roles/firebasecloudmessaging.admin"
```

حساب استدعاء Eventarc وCloud Scheduler:

```bash
gcloud iam service-accounts create darjar-notifications-invoker \
  --display-name="DarJar notifications invoker"

gcloud projects add-iam-policy-binding raq-darjar \
  --member="serviceAccount:darjar-notifications-invoker@raq-darjar.iam.gserviceaccount.com" \
  --role="roles/eventarc.eventReceiver"
```

## 4. نشر قواعد Firestore والخدمة

من جذر مستودع DarJar:

```bash
firebase deploy --only firestore:rules

gcloud run deploy darjar-notifications \
  --source backend/notifications \
  --region RUN_REGION \
  --service-account="darjar-notifications-runtime@raq-darjar.iam.gserviceaccount.com" \
  --set-env-vars="GOOGLE_CLOUD_PROJECT=raq-darjar" \
  --no-allow-unauthenticated
```

امنح حساب الاستدعاء صلاحية استدعاء الخدمة:

```bash
gcloud run services add-iam-policy-binding darjar-notifications \
  --region RUN_REGION \
  --member="serviceAccount:darjar-notifications-invoker@raq-darjar.iam.gserviceaccount.com" \
  --role="roles/run.invoker"
```

احصل على رابط الخدمة واحتفظ به للخطوة السادسة:

```bash
gcloud run services describe darjar-notifications \
  --region RUN_REGION \
  --format="value(status.url)"
```

## 5. إنشاء مشغلات Firestore

إشعار أعضاء الإقامة عند انضمام ساكن جديد:

```bash
gcloud eventarc triggers create darjar-member-created \
  --location FIRESTORE_LOCATION \
  --destination-run-service darjar-notifications \
  --destination-run-region RUN_REGION \
  --destination-run-path /events/member-created \
  --event-filters="type=google.cloud.firestore.document.v1.created" \
  --event-filters="database=(default)" \
  --event-filters="namespace=(default)" \
  --event-filters-path-pattern="document=residences/{residenceId}/members/{memberId}" \
  --event-data-content-type="application/protobuf" \
  --service-account="darjar-notifications-invoker@raq-darjar.iam.gserviceaccount.com"
```

إشعارات المنشورات الجديدة:

```bash
gcloud eventarc triggers create darjar-post-created \
  --location FIRESTORE_LOCATION \
  --destination-run-service darjar-notifications \
  --destination-run-region RUN_REGION \
  --destination-run-path /events/post-created \
  --event-filters="type=google.cloud.firestore.document.v1.created" \
  --event-filters="database=(default)" \
  --event-filters="namespace=(default)" \
  --event-filters-path-pattern="document=residences/{residenceId}/communityPosts/{postId}" \
  --event-data-content-type="application/protobuf" \
  --service-account="darjar-notifications-invoker@raq-darjar.iam.gserviceaccount.com"
```

إشعارات الإعجاب بالمنشورات:

```bash
gcloud eventarc triggers create darjar-post-written \
  --location FIRESTORE_LOCATION \
  --destination-run-service darjar-notifications \
  --destination-run-region RUN_REGION \
  --destination-run-path /events/post-written \
  --event-filters="type=google.cloud.firestore.document.v1.updated" \
  --event-filters="database=(default)" \
  --event-filters="namespace=(default)" \
  --event-filters-path-pattern="document=residences/{residenceId}/communityPosts/{postId}" \
  --event-data-content-type="application/protobuf" \
  --service-account="darjar-notifications-invoker@raq-darjar.iam.gserviceaccount.com"
```

إشعارات التعليق على المنشورات:

```bash
gcloud eventarc triggers create darjar-comment-created \
  --location FIRESTORE_LOCATION \
  --destination-run-service darjar-notifications \
  --destination-run-region RUN_REGION \
  --destination-run-path /events/comment-created \
  --event-filters="type=google.cloud.firestore.document.v1.created" \
  --event-filters="database=(default)" \
  --event-filters="namespace=(default)" \
  --event-filters-path-pattern="document=residences/{residenceId}/communityPosts/{postId}/comments/{commentId}" \
  --event-data-content-type="application/protobuf" \
  --service-account="darjar-notifications-invoker@raq-darjar.iam.gserviceaccount.com"
```

إشعار المستخدم عند انتقال اشتراك شقته إلى حالة مؤدى:

```bash
gcloud eventarc triggers create darjar-due-written \
  --location FIRESTORE_LOCATION \
  --destination-run-service darjar-notifications \
  --destination-run-region RUN_REGION \
  --destination-run-path /events/due-written \
  --event-filters="type=google.cloud.firestore.document.v1.written" \
  --event-filters="database=(default)" \
  --event-filters="namespace=(default)" \
  --event-filters-path-pattern="document=residences/{residenceId}/dues/{dueId}" \
  --event-data-content-type="application/protobuf" \
  --service-account="darjar-notifications-invoker@raq-darjar.iam.gserviceaccount.com"
```

إشعارات إضافة أو تعديل أو حذف معاملة مالية:

```bash
gcloud eventarc triggers create darjar-budget-written \
  --location FIRESTORE_LOCATION \
  --destination-run-service darjar-notifications \
  --destination-run-region RUN_REGION \
  --destination-run-path /events/budget-written \
  --event-filters="type=google.cloud.firestore.document.v1.written" \
  --event-filters="database=(default)" \
  --event-filters="namespace=(default)" \
  --event-filters-path-pattern="document=residences/{residenceId}/financeTransactions/{transactionId}" \
  --event-data-content-type="application/protobuf" \
  --service-account="darjar-notifications-invoker@raq-darjar.iam.gserviceaccount.com"
```

إنشاء نشاط عند إضافة وثيقة:

```bash
gcloud eventarc triggers create darjar-document-created \
  --location FIRESTORE_LOCATION \
  --destination-run-service darjar-notifications \
  --destination-run-region RUN_REGION \
  --destination-run-path /events/document-created \
  --event-filters="type=google.cloud.firestore.document.v1.created" \
  --event-filters="database=(default)" \
  --event-filters="namespace=(default)" \
  --event-filters-path-pattern="document=residences/{residenceId}/documents/{documentId}" \
  --event-data-content-type="application/protobuf" \
  --service-account="darjar-notifications-invoker@raq-darjar.iam.gserviceaccount.com"
```

إنشاء نشاط عند إضافة خدمة:

```bash
gcloud eventarc triggers create darjar-service-created \
  --location FIRESTORE_LOCATION \
  --destination-run-service darjar-notifications \
  --destination-run-region RUN_REGION \
  --destination-run-path /events/service-created \
  --event-filters="type=google.cloud.firestore.document.v1.created" \
  --event-filters="database=(default)" \
  --event-filters="namespace=(default)" \
  --event-filters-path-pattern="document=services/{serviceId}" \
  --event-data-content-type="application/protobuf" \
  --service-account="darjar-notifications-invoker@raq-darjar.iam.gserviceaccount.com"
```

إنشاء نشاط عند تعديل قيمة الاشتراك الشهرية:

```bash
gcloud eventarc triggers create darjar-settings-written \
  --location FIRESTORE_LOCATION \
  --destination-run-service darjar-notifications \
  --destination-run-region RUN_REGION \
  --destination-run-path /events/settings-written \
  --event-filters="type=google.cloud.firestore.document.v1.updated" \
  --event-filters="database=(default)" \
  --event-filters="namespace=(default)" \
  --event-filters-path-pattern="document=residences/{residenceId}/settings/private" \
  --event-data-content-type="application/protobuf" \
  --service-account="darjar-notifications-invoker@raq-darjar.iam.gserviceaccount.com"
```

قد يستغرق المشغل عدة دقائق قبل أن يصبح نشطًا.

## 6. تعبئة الموجز من البيانات الحالية

بعد نشر القواعد والخدمة، شغّل العملية مرة واحدة. تستورد أحدث عشرة عناصر من كل
نوع ولكل إقامة: المصروفات، الاشتراكات المؤداة، الوثائق والخدمات. العملية
idempotent ويمكن تكرارها بأمان.

```bash
SERVICE_URL="$(gcloud run services describe darjar-notifications \
  --region europe-southwest1 \
  --format='value(status.url)')"

IDENTITY_TOKEN="$(gcloud auth print-identity-token)"

curl -fsS -X POST \
  -H "Authorization: Bearer $IDENTITY_TOKEN" \
  "$SERVICE_URL/jobs/backfill-feed-activities"
```

يعيد المسار عدد العناصر المرشحة التي عالجها. إعادة التشغيل لا تكرر الوثائق لأن
معرّفات أنشطة الـbackfill ثابتة.

## 7. الفحص اليومي للواجبات المتأخرة

استبدل `SERVICE_URL` بالرابط الذي أعادته الخطوة الرابعة:

```bash
gcloud scheduler jobs create http darjar-overdue-dues \
  --location SCHEDULER_REGION \
  --schedule="0 3 * * *" \
  --time-zone="Africa/Casablanca" \
  --uri="SERVICE_URL/jobs/overdue-dues" \
  --http-method=POST \
  --oidc-service-account-email="darjar-notifications-invoker@raq-darjar.iam.gserviceaccount.com" \
  --oidc-token-audience="SERVICE_URL"
```

يمكن تشغيل الفحص يدويًا بعد إنشائه:

```bash
gcloud scheduler jobs run darjar-overdue-dues --location SCHEDULER_REGION
```

## 8. Web Push وiOS

### الويب

1. Firebase Console > Project settings > Cloud Messaging.
2. أنشئ Web Push certificate وانسخ Public VAPID key.
3. ابنِ الويب هكذا:

```bash
flutter build web \
  --dart-define=DARJAR_WEB_PUSH_VAPID_KEY=PUBLIC_VAPID_KEY
```

### iOS

1. فعّل Push Notifications للـApp ID `ma.raqmain.darjar` في Apple Developer.
2. أنشئ APNs Authentication Key.
3. ارفعه في Firebase Console > Project settings > Cloud Messaging > Apple app.
4. فعّل Push Notifications وBackground Modes > Remote notifications في Xcode.
5. اختبر على iPhone حقيقي.

Android لا يحتاج مفتاحًا إضافيًا بعد وجود `google-services.json`.

## 9. اختبار النتيجة

استخدم حسابين عضوين في الإقامة نفسها:

1. افتح الحساب الثاني مرة واحدة ووافق على إذن الإشعارات ليُحفظ FCM token.
2. أنشئ منشورًا من الحساب الأول.
3. يجب أن يظهر الإشعار في جرس الحساب الثاني، ولا يظهر لكاتب المنشور.
4. ضع التطبيق الثاني في الخلفية وكرر الاختبار للتحقق من Push.
5. راقب الأخطاء:

```bash
gcloud run services logs read darjar-notifications \
  --region RUN_REGION \
  --limit 100
```
