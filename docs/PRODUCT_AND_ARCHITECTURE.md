# Product and Architecture

## Definition
DarJar is the operating system of apartment living: one application for community, a resident-powered local directory, and residence management.

## Main areas

### Community
- Feed
- Resident posts
- Official announcements
- Polls
- Discussions
- Lost and found

### Directory
- Trusted city-wide profiles with residence-aware recommendations
- Craftspeople as the highest-priority category
- Restaurants, cafés, pharmacies, and nearby facilities
- Search and category browsing
- Profile details, recommendation scores, and recent resident reviews
- One shared profile per provider, with recommendations from the current residence highlighted

### Residence
- Maintenance requests
- Documents
- Management information
- Member administration
- Official notices
- Manual dues status
- Reservations later

## Growth model
1. A resident creates a residence.
2. Neighbors join by invitation.
3. The community gains value.
4. Moderators emerge.
5. Management joins later.

## Dues
DarJar does not process payments in the MVP.
Management may publish bank information, residents transfer externally, and authorized managers update status manually.

Possible statuses:
- paid
- overdue
- pending verification
- not configured

## MVP non-goals
- Payment gateway
- Escrow
- Full accounting
- Syndic ERP
- Public social network
- AI assistant
- Separate web product

## UI philosophy
The same DarJar identity must appear on all platforms.

### Compact
- Bottom navigation
- One content column
- Touch-first layout

### Medium
- Wider layout
- Optional two-column grids
- Navigation rail when appropriate

### Expanded
- Persistent sidebar or rail
- Central app content
- Optional context panel
- Never stretch reading content across the entire screen

Suggested breakpoints:
- compact: under 600
- medium: 600–1023
- expanded: 1024+

## Arabic
- Arabic is the default.
- RTL is tested from Milestone 0.
- All strings are localized, not hard-coded in widgets.
- English is structurally supported.

## Stack
- Flutter
- Dart
- Riverpod
- go_router
- Firebase after mock validation

## Suggested structure
```text
lib/
  app/
    routing/
    localization/
    theme/
  core/
    responsive/
    errors/
    widgets/
  features/
    onboarding/
    residence/
    community/
    directory/
    residence/
    dues/
    management/
    profile/
  shared/
    models/
    repositories/
    widgets/
  main.dart
```

Create folders only when they contain real code.

## Data approach
1. In-memory mock data
2. Mock repositories
3. Firebase development project
4. Production project later

The UI depends on repository interfaces so Firebase can replace mocks gradually.

## Preliminary Firestore shape
```text
users/{userId}
residences/{residenceId}
residences/{residenceId}/members/{userId}
residences/{residenceId}/posts/{postId}
directoryEntries/{entryId}
directoryEntries/{entryId}/recommendations/{recommendationId}
residences/{residenceId}/directoryRecommendations/{recommendationId}
residences/{residenceId}/maintenanceRequests/{requestId}
residences/{residenceId}/duesPeriods/{periodId}
residences/{residenceId}/duesPeriods/{periodId}/records/{userId}
residences/{residenceId}/documents/{documentId}
residences/{residenceId}/invitations/{invitationId}
users/{userId}/notifications/{notificationId}
```

## Security direction
- Residence data requires active membership.
- Official announcements require an authorized role.
- Residents cannot mark their own dues as paid.
- Role elevation and platform administration require trusted server logic.
- Rules are written and tested alongside each Firebase feature.
