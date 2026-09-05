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
