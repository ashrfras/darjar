# DarJar light-mode screenshots

Five screenshots rendered from the real Flutter pages in Arabic and RTL with in-memory sample data. Firebase is never initialized by the capture harness; no database reads or writes are required. Production application code is unchanged.

Regenerate from the repository root:

```sh
flutter test tool/screenshot_capture_test.dart
```

PNG files are in `screenshots/light/`. The harness loads the bundled Arabic fonts and the installed Flutter SDK's Material Icons font. Run it with Flutter available on PATH.

Interactive Chrome preview (same fixtures, always light mode):

```sh
flutter run -d chrome -t tool/screenshot_demo.dart --web-port 7358 --no-web-resources-cdn
```

Start at `/community`. The residence and administration navigation opens the other screenshot pages. The dedicated preview entry point never initializes Firebase, and its Firestore and Storage providers explicitly reject backend access. It is intended for browsing sample data; editing actions are not connected to a database.

Demo portraits: Random User sample portraits (randomuser.me); downloaded as local demo-avatar assets. Service and feed images reuse the bundled community image assets.
