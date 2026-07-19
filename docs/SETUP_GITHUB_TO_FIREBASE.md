# Setup: GitHub to Firebase

Assumptions: macOS, private repository, project folder `~/Projects/darjar`.

## 1. Verify tools

```bash
git --version
node --version
npm --version
flutter --version
dart --version
flutter doctor
```

Resolve important `flutter doctor` issues. Xcode is required for iOS; Android Studio and an Android SDK are required for Android; Chrome is the normal Flutter Web debug target.

## 2. Create Flutter locally

```bash
mkdir -p ~/Projects
cd ~/Projects
flutter create --org com.darjar --platforms=android,ios,web darjar
cd darjar
flutter run -d chrome
```

## 3. Create Git history

```bash
git status
git add .
git commit -m "chore: initialize Flutter application"
git branch -M main
```

## 4. Create GitHub repository

Create an empty **private** repository named `darjar`.

Do not initialize it with README, license, or `.gitignore`.

Then:

```bash
git remote add origin YOUR_GITHUB_REPOSITORY_URL
git push -u origin main
```

Or with GitHub CLI:

```bash
gh auth login
gh repo create darjar --private --source=. --remote=origin --push
```

## 5. Add this handoff

Copy these items into the repository root:

```text
AGENTS.md
CODEX_START_PROMPT.md
docs/
```

Then:

```bash
git add AGENTS.md CODEX_START_PROMPT.md docs
git commit -m "docs: add DarJar Codex handoff"
git push
```

## 6. Start Codex

Open the repository in Codex and paste `CODEX_START_PROMPT.md`.

Ask for Milestone 0 only.

After Codex finishes:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
flutter run -d chrome
```

Review the diff before committing.

## 7. Implement mock milestones before Firebase

Use one branch per milestone:

```bash
git checkout -b milestone/1-design-system
```

After approval:

```bash
git add .
git commit -m "feat: add DarJar design system and responsive shell"
git checkout main
git merge --no-ff milestone/1-design-system
git push
```

Repeat for Milestone 2.

Do not create Firestore collections or add Firebase packages yet.

## 8. Create Firebase development project

Create one development project in Firebase Console:

```text
darjar-dev
```

The actual project ID may require a suffix because Firebase project IDs are globally unique.

Do not create production yet.

## 9. Install CLIs

Since Node.js is already installed:

```bash
npm install -g firebase-tools
firebase login
firebase projects:list
dart pub global activate flutterfire_cli
```

If `flutterfire` is not found on macOS:

```bash
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc
```

## 10. Connect Flutter to Firebase in Milestone 3

From the repository root:

```bash
flutter pub add firebase_core
flutterfire configure
```

Select:
- the `darjar-dev` project
- Android
- iOS
- Web

FlutterFire generates `lib/firebase_options.dart`.

Initialize in the app bootstrap:

```dart
WidgetsFlutterBinding.ensureInitialized();

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Then test:

```bash
flutter run -d chrome
```

## 11. Add products gradually

First:

```bash
flutter pub add firebase_auth
flutter pub add cloud_firestore
flutterfire configure
```

Later, only when required:

```bash
flutter pub add firebase_storage
flutter pub add cloud_functions
flutter pub add firebase_app_check
flutter pub add firebase_messaging
flutter pub add firebase_crashlytics
flutterfire configure
```

## 12. Initialize Firebase project files

```bash
firebase init
```

Initially select only the features needed by the active milestone, such as Firestore and Emulators.

This creates versioned configuration such as:

```text
firebase.json
.firebaserc
firestore.rules
firestore.indexes.json
```

Never commit service-account private keys.

## 13. Emulators

After configuring them:

```bash
firebase emulators:start
```

Use an explicit development switch. Release builds must never connect to local emulators.

## 14. Firebase Hosting for the app

When ready:

```bash
flutter build web
firebase init hosting
```

Choose:
- public directory: `build/web`
- single-page app: Yes
- do not overwrite the Flutter-generated `index.html`

Deploy:

```bash
firebase deploy --only hosting
```

## 15. Repository safety

Never commit:
- service-account JSON
- APNs private keys
- Android keystores
- Apple certificates
- passwords
- private API keys
- secret `.env` files

Before pushing:

```bash
git status
git diff --cached
```
