# Instructions for Codex

## Fixed decisions
- Use Flutter and Dart only.
- Keep iOS, Android, and Web in one Flutter repository.
- The web version launches the application itself.
- Use Riverpod and go_router.
- Arabic and RTL are first-class from the first milestone.
- Use a feature-first structure.
- Do not connect Firebase during Milestones 0–2.
- Do not add payment processing.
- Do not create a separate marketing website or React frontend.

## Product rules
- DarJar is residence-centered, not a public social network.
- A resident can create a residence and invite neighbors.
- Management or the syndic is not required to start.
- The core context is `residenceId`.
- Dues are tracked manually; DarJar does not hold money.
- Roles: resident, moderator, manager, owner, platformAdmin.
- Users cannot grant themselves privileged roles.

## Engineering rules
- Work one milestone at a time.
- Inspect the repository before editing.
- Prefer simple, readable code.
- Explain important Flutter/Dart choices to an owner coming from JavaScript and Node.js.
- Avoid premature abstractions and unnecessary packages.
- Use mock repositories before Firebase repositories.
- Never commit passwords, service-account keys, APNs keys, keystores, or signing credentials.

## Quality gates
Run after each milestone:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
```
