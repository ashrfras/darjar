# تشغيل سجل نشاط التطبيق

تقرأ تطبيقات دارجار السجل من دالة HTTPS ‏`appactivitylog`. تتحقق الدالة من رمز
Firebase Auth وصلاحية `developer` المرتبطة بحساب Firebase
وموعد إنشائه. تتحقق منها لكل طلب، بما فيه التحقق من ظهور الخيار في «حسابي». يتطلب
إلغاء الصلاحية تعيين `developer` إلى `false` في مستند `appPermissions/{uid}`
باستخدام صلاحيات الإدارة.

تحتوي السجلات على نوع الحدث ووقته ومعرّف الحساب أو الإقامة عند الحاجة. عند القراءة،
تجلب الدالة اسم الساكن ورقمه واسم الإقامة من المستندات الحالية وتعيد معلومات العرض
ومعرّف الإقامة. تبقى التفاصيل التي حُذفت مستنداتها غير متاحة. وقت الواجهة
بحسب المنطقة الزمنية للجهاز. يُسجّل إنشاء ملف حساب دارجار في Firestore، ويُسجّل
طلب حذفه عند تقديمه. يُسجّل الحذف النهائي عند حذف مستند الحساب أو الإقامة.
حذف مستخدم من Firebase Auth وحده، دون حذف ملف دارجار، يقع خارج مسار حذف
الحساب المُراقب هنا. تسجل التعبئة الأولية أول منشور ما زال له مستند، بما في ذلك
المنشورات المؤرشفة. لا يمكن استرجاع وقائع الحذف أو الانضمام التي اختفت مصادرها قبل تشغيل السجل.

## نشر دالة القراءة

دعم Dart في Cloud Functions for Firebase تجريبي. يلزم Firebase CLI ‏15.15 أو
أحدث. تُستقبل أحداث Firestore عبر Eventarc في خدمة الإشعارات الحالية، لأن نشر
مشغلات Firestore المباشرة لدوال Dart غير متاح في الإصدار التجريبي.
[وثائق دوال Dart](https://firebase.google.com/docs/functions/start-dart)

أنشئ حساب تشغيل للقراءة والتحقق من جلسات Firebase Auth. استخدم بيانات الاعتماد
الافتراضية للحسابات الإدارية أو هويات التشغيل. أدوار IAM أدناه تمنح القراءة
على مستوى المشروع لحساب تشغيل الدالة فقط. تحتفظ الدالة باستعلام ثابت على السجل
وتتحقق من تفويض كل طلب.

```bash
gcloud iam service-accounts create darjar-activity-reader --project=raq-darjar

for role in roles/datastore.viewer roles/firebaseauth.viewer; do
  gcloud projects add-iam-policy-binding raq-darjar \
    --member=serviceAccount:darjar-activity-reader@raq-darjar.iam.gserviceaccount.com \
    --role="$role"
done

firebase experiments:enable dartfunctions
firebase deploy --only functions:activity-log --project raq-darjar
```

عنوان الدالة الافتراضي في التطبيق هو عنوان Cloud Run المبني على رقم المشروع
في `europe-west1`. إذا اختلف عنوان النشر، مرّر
`--dart-define=DARJAR_ACTIVITY_LOG_URL=<function-url>` عند بناء إصدارات Flutter.

## تفعيل التسجيل والتعبئة الأولية

انشر `backend/notifications` حسب [إعداد خدمة الإشعارات](NOTIFICATIONS_BACKEND_SETUP.md)،
مع إبقاء استدعاء الخدمة محميًا بـ IAM وإبقاء مشغلات الإشعارات الحالية.

أنشئ المشغلات التالية مرة واحدة. شغّلها في `europe-southwest1`، موقع Firestore
وخدمة الإشعارات في مشروع دارجار.

```bash
for definition in \
  'users written users/{userId}' \
  'residences written residences/{residenceId}' \
  'members written residences/{residenceId}/members/{memberId}' \
  'posts created residences/{residenceId}/communityPosts/{postId}'; do
  read -r name event path <<< "$definition"
  gcloud eventarc triggers create "darjar-app-activity-$name" \
    --project=raq-darjar --location=europe-southwest1 \
    --destination-run-service=darjar-notifications \
    --destination-run-region=europe-southwest1 \
    --destination-run-path=/events/app-activity \
    --event-filters="type=google.cloud.firestore.document.v1.$event" \
    --event-filters='database=(default)' \
    --event-filters-path-pattern="document=$path" \
    --event-data-content-type=application/protobuf \
    --service-account=darjar-notifications-invoker@raq-darjar.iam.gserviceaccount.com
done
```

نفّذ الأوامر التالية من جذر المستودع بعد تفعيل المشغلات. يمكن إعادة تنفيذ
التعبئة بأمان. إذا وصلت أحداث النشر بترتيب مختلف، يبقى في السجل أقدم وقت معروف
لأول منشور.

```bash
(cd backend/notifications && dart pub get && dart run bin/backfill_app_activity.dart raq-darjar)
(cd backend/activity_log && dart pub get && dart run bin/grant_initial_developer.dart raq-darjar)
```

بعد نشر التطبيق، يظهر «نشاط التطبيق» تحت «عن التطبيق» ضمن «حسابي» عند الدخول بحساب
المطوّر. يعمل دخول الاختبار الحالي دون SMS لأنه يصدر جلسة Firebase Auth للحساب.
وضع المحاكاة المحلي الذي ينشئ مستخدمًا وهميًا داخل التطبيق لا يملك رمز Firebase.
تحقق من أن الدالة ترد بـ `401` دون رمز، وبـ `403` لحساب عادي، وبصفحة من 30 حدثًا
كحد أقصى لحساب المطوّر. تتطلب أدوات التعبئة والمنح صلاحيات خادمية، وتمنع قواعد
Firestore وصول تطبيقات العملاء مباشرة إلى مجموعتي السجل والصلاحيات.

## التحقق محلياً

```bash
firebase emulators:exec --only auth,firestore --project demo-darjar \
  'cd backend/activity_log && dart test test/activity_log_emulator_test.dart'
```

يتحقق الاختبار من دخول المطوّر دون SMS ومنع الطلبات غير المصرّح بها والوصول المباشر إلى Firestore،
ومن ترقيم الصفحات عند تساوي وقت عدة أحداث.

## وضع دعم الإقامات

يستخدم وضع الدعم شاشات التطبيق وقوائمه الحالية بصلاحيات الإدارة المفوّضة، مع شريط لإنهاء الدعم. يبدأ من حدث «إنشاء إقامة»
ويحمل سياق الإقامة في جلسة التطبيق. يحتفظ الحساب بعضوياته وإقامته المفضلة، وتظل
عمليات رئيس الإقامة محصورة به. يتحقق Firestore وCloud Storage من علامة
`developer` في رمز Firebase Auth ومن المنح في `appPermissions/{uid}`. سحب
المنح في Firestore يمنع استخدامه حتى قبل تحديث الرمز.

عند نشر هذه الميزة، حدّث منح الحساب المعتمد مرة واحدة ثم انشر القواعد والواجهة.

```bash
(cd backend/activity_log && dart run bin/grant_initial_developer.dart raq-darjar)
firebase deploy --only firestore:rules,storage --project raq-darjar
```

يفرض التطبيق تحديث رمز Firebase عند فتح الإقامة للدعم.
