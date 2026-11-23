# أوامر DarJar السريعة

نفّذ هذه الأوامر من المجلد الرئيسي للمشروع.

## تشغيل بيئة التطوير المحلية

يجلب السكربت سر المصادقة المحلي من Google Secret Manager ثم يشغّل التطبيق على Chrome:

```bash
bash tool/run_web_local.sh
```

## نشر الويب على Firebase Hosting فقط

```bash
flutter build web
firebase deploy --only hosting
```

رقم واتساب المؤقت في صفحة «الدعم والتواصل» هو `+212708708001`. لتغييره، مرّر
`--dart-define=DARJAR_SUPPORT_WHATSAPP_NUMBER=<الرقم-الرسمي>`
عند بناء التطبيق. استخدم الرقم الدولي مع رمز البلد. انشر قواعد Firestore المحدّثة
قبل إصدار هذه النسخة لدعم حفظ إجابة النافذة على مستوى الحساب.

للتواصل اليدوي، يمكن لفريق دارجار المخوّل الوصول إلى Firestore مراجعة حسابات
`users` التي تحمل `whatsAppSupportEnabled == true`، والتحقق من الحالة عند
التواصل عبر رقم الحساب `phoneNumber`. تُستبعد الحسابات التي طلبت الحذف.

## نشر قواعد Firebase فقط

ينشر قواعد Firestore وCloud Storage من دون نشر الاستضافة أو الفهارس:

```bash
firebase deploy --only firestore:rules,storage
```

## إنشاء أرشيف Android

```bash
flutter build appbundle --release
```

الناتج: `build/app/outputs/bundle/release/app-release.aab`

## إنشاء أرشيف iOS

```bash
flutter build ipa --release
```

النواتج: `build/ios/archive/Runner.xcarchive` وملف `.ipa` داخل `build/ios/ipa/`.

> يتطلب بناء Android إعداد `android/key.properties`، ويتطلب بناء iOS إعداد التوقيع في Xcode.
