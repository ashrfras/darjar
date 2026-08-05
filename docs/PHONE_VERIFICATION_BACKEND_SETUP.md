# تشغيل التحقق من الهاتف عبر Zavu

خدمة التحقق موجودة في `backend/phone_verification` وتعمل على Cloud Run باستخدام
Dart. التطبيق لا يتصل بـZavu مباشرة ولا يحتوي أي مفتاح سري.

لا توفر Zavu endpoint لمقارنة OTP. لذلك تنشئ خدمة DarJar رمزًا عشوائيًا من ستة
أرقام، وترسل الرسالة عبر Zavu، وتحفظ في Firestore بصمة HMAC فقط مع خمس محاولات
ووقت صلاحية عشر دقائق. بعد نجاح الرمز تصدر الخدمة Firebase Custom Token، ولذلك
تبقى جلسات Firebase و`uid` وقواعد Firestore وStorage كما هي.

## 1. إعداد Zavu

1. أنشئ حسابًا في `https://dashboard.zavu.dev`.
2. أنشئ Team وProject مخصصين للإنتاج.
3. أنشئ Sender يدعم SMS واجعله Default Sender.
4. أنشئ Live API Key واحفظه فورًا؛ تعرض Zavu المفتاح مرة واحدة فقط.
5. الحسابات الجديدة تبدأ في Sandbox Mode، الذي يسمح بالإرسال إلى الأرقام
   الموثقة فقط. أضف أرقام الاختبار من صفحة Sandbox، واطلب تفعيل Production Mode
   قبل الإطلاق العام.

يمكن تحديد Sender صراحة عبر `ZAVU_SENDER_ID`. إذا لم تحدده، تستعمل الخدمة
Default Sender الخاص بالمشروع.

## 2. الأسرار

أنشئ سر مفتاح Zavu:

```bash
gcloud secrets create darjar-zavu-api-key --replication-policy=automatic
printf '%s' 'YOUR_ZAVU_LIVE_API_KEY' | \
  gcloud secrets versions add darjar-zavu-api-key --data-file=-
```

أنشئ pepper عشوائيًا لحماية بصمات رموز OTP. لا تحتاج إلى معرفة قيمته أو طباعته:

```bash
gcloud secrets create darjar-otp-hash-pepper --replication-policy=automatic
openssl rand -base64 48 | \
  gcloud secrets versions add darjar-otp-hash-pepper --data-file=-
```

تحقق من أرقام النسخ وحالتها دون عرض القيم:

```bash
gcloud secrets versions list darjar-zavu-api-key
gcloud secrets versions list darjar-otp-hash-pepper
```

## 3. حساب الخدمة والصلاحيات

```bash
RUNTIME_SA="darjar-phone-verify-runtime@raq-darjar.iam.gserviceaccount.com"
```

إذا لم يكن الحساب موجودًا:

```bash
gcloud iam service-accounts create darjar-phone-verify-runtime \
  --display-name="DarJar phone verification runtime"
```

```bash
gcloud projects add-iam-policy-binding raq-darjar \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/datastore.user"

gcloud projects add-iam-policy-binding raq-darjar \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/firebaseauth.admin"

gcloud iam service-accounts add-iam-policy-binding "${RUNTIME_SA}" \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/iam.serviceAccountTokenCreator"
```

امنحه قراءة السرّين الجديدين فقط:

```bash
gcloud secrets add-iam-policy-binding darjar-zavu-api-key \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding darjar-otp-hash-pepper \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/secretmanager.secretAccessor"
```

## 4. نشر الخدمة

حدد أرقام النسخ الفعالة بدل استعمال `latest`:

```bash
ZAVU_KEY_VERSION="1"
OTP_PEPPER_VERSION="1"
RUN_REGION="europe-southwest1"
RUNTIME_SA="darjar-phone-verify-runtime@raq-darjar.iam.gserviceaccount.com"
```

حمّل Firebase Web API Key إلى متغير دون طباعته:

```bash
FIREBASE_API_KEY="$(gcloud services api-keys get-key-string \
  fc524f04-f586-42ba-aa89-d564c0d3e818 \
  --project=raq-darjar \
  --location=global \
  --format='value(keyString)')"
```

انشر النسخة الجديدة. تستبدل `--set-secrets` و`--set-env-vars` إعدادات المزود
السابقة، فلا يبقى مفتاح المزود القديم مربوطًا بخدمة Cloud Run:

```bash
gcloud run deploy darjar-phone-verification \
  --source backend/phone_verification \
  --region="${RUN_REGION}" \
  --service-account="${RUNTIME_SA}" \
  --allow-unauthenticated \
  --set-secrets="ZAVU_API_KEY=darjar-zavu-api-key:${ZAVU_KEY_VERSION},OTP_HASH_PEPPER=darjar-otp-hash-pepper:${OTP_PEPPER_VERSION}" \
  --set-env-vars="^~^GOOGLE_CLOUD_PROJECT=raq-darjar~FIREBASE_TOKEN_SIGNER_EMAIL=${RUNTIME_SA}~FIREBASE_API_KEY=${FIREBASE_API_KEY}~ALLOWED_ORIGINS=https://darjar.app,https://www.darjar.app,https://raq-darjar.web.app"
```

إذا لم يكن Sender هو الافتراضي، أضف إلى قيمة `--set-env-vars`:

```text
~ZAVU_SENDER_ID=YOUR_SENDER_ID
```

## 5. الفحص والبناء

```bash
SERVICE_URL="$(gcloud run services describe darjar-phone-verification \
  --region="${RUN_REGION}" \
  --format='value(status.url)')"

curl -f "${SERVICE_URL}/health"

flutter build web \
  --dart-define="DARJAR_PHONE_VERIFICATION_URL=${SERVICE_URL}"
```

## 6. TTL

فعّل Firestore TTL على جلسات التحقق:

```bash
gcloud firestore fields ttls update expiresAt \
  --collection-group=phoneVerificationSessions \
  --enable-ttl

gcloud firestore fields ttls update expiresAt \
  --collection-group=phoneVerificationRateLimits \
  --enable-ttl
```

## 7. بوابات الجودة

```bash
(cd backend/phone_verification && \
  dart format --output=none --set-exit-if-changed . && \
  dart analyze && \
  dart test)

dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
```

لا تسجل الخدمة رقم الهاتف أو رمز OTP أو مفتاح Zavu أو Firebase Custom Token في
السجلات.
