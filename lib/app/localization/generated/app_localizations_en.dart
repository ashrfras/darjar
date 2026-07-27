// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DarJar';

  @override
  String get brandLatin => 'DarJar';

  @override
  String get community => 'Community';

  @override
  String get directory => 'Directory';

  @override
  String get demoResidence => 'Yasmeen Residence';

  @override
  String get selectResidence => 'Select residence';

  @override
  String get residenceSwitcherDescription =>
      'Choose the residence you want to browse and manage now.';

  @override
  String get currentResidence => 'Current';

  @override
  String get acceptInvitation => 'Join';

  @override
  String get residenceInvitations => 'New residence invitations';

  @override
  String get residenceContextLoadError =>
      'The account residences could not be loaded.';

  @override
  String residenceDisplayName(String name) {
    return '$name Residence';
  }

  @override
  String get communityDescription =>
      'News, announcements, and discussions for residence neighbors.';

  @override
  String get shellPreviewDescription =>
      'A preview of the responsive navigation shell. Product functionality arrives in Milestone 2.';

  @override
  String get milestoneTwo => 'Coming in Milestone 2';

  @override
  String get componentGallery => 'Component gallery';

  @override
  String get componentGalleryDescription =>
      'An internal reference for DarJar interface elements and their basic states.';

  @override
  String get buttons => 'Buttons';

  @override
  String get primaryAction => 'Primary action';

  @override
  String get secondaryAction => 'Secondary action';

  @override
  String get disabledAction => 'Unavailable';

  @override
  String get fields => 'Fields';

  @override
  String get residenceName => 'Residence name';

  @override
  String get residenceNameHint => 'Example: Yasmeen';

  @override
  String get residenceNameGuidance =>
      'Enter the name directly without “إقامة” or “Résidence”.';

  @override
  String get chipsAndBadges => 'Chips and badges';

  @override
  String get all => 'All';

  @override
  String get announcements => 'Announcements';

  @override
  String get newLabel => 'New';

  @override
  String get completedLabel => 'Completed';

  @override
  String get processingLabel => 'Processing';

  @override
  String get cards => 'Cards';

  @override
  String get sampleCardTitle => 'Residence announcement';

  @override
  String get sampleCardDescription =>
      'An example of a simple, clear content card in DarJar.';

  @override
  String get onboardingHeadline => 'Apartment living, all in one place';

  @override
  String get onboardingDescription =>
      'Connect with neighbors, discover trusted local services, and follow residence matters with ease and privacy.';

  @override
  String get getStarted => 'Get started';

  @override
  String get back => 'Back';

  @override
  String get residenceSetupTitle => 'How would you like to start?';

  @override
  String get residenceSetupDescription =>
      'Join your current residence or create a new one for your neighbors.';

  @override
  String get joinMyResidence => 'Join my residence';

  @override
  String get joinMyResidenceDescription =>
      'Find your residence using the code you received.';

  @override
  String get createNewResidence => 'Create a new residence';

  @override
  String get createNewResidenceDescription =>
      'Add your residence and start inviting your neighbors.';

  @override
  String get createResidenceFormDescription =>
      'Enter the residence details and your basic information to continue.';

  @override
  String get yourInformation => 'Your information';

  @override
  String get createResidence => 'Create residence';

  @override
  String get joinResidence => 'Join residence';

  @override
  String get city => 'City';

  @override
  String get cityHint => 'Example: Casablanca';

  @override
  String get citySelectHint => 'Select a city';

  @override
  String get cityCasablanca => 'Casablanca';

  @override
  String get cityRabat => 'Rabat';

  @override
  String get cityMarrakesh => 'Marrakesh';

  @override
  String get cityTangier => 'Tangier';

  @override
  String get cityAgadir => 'Agadir';

  @override
  String get cityFes => 'Fes';

  @override
  String get unit => 'Unit';

  @override
  String get unitHint => 'Example: Building B, apartment 12';

  @override
  String get invitationCode => 'Invitation code';

  @override
  String get invitationCodeHint => 'Example: 48273165';

  @override
  String get createAndContinue => 'Create and continue';

  @override
  String get joinAndContinue => 'Join and continue';

  @override
  String get residenceAddressHint => 'Example: 12 Yasmeen Street, Maarif';

  @override
  String get countryCode => 'Country code';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneNumberHint => 'Example: 06 12 34 56 78';

  @override
  String get localPhoneNumberHint => 'Example: 6 12 34 56 78';

  @override
  String get firstName => 'First name';

  @override
  String get firstNameHint => 'Enter your first name';

  @override
  String get lastName => 'Last name';

  @override
  String get lastNameHint => 'Enter your last name';

  @override
  String get joinPhoneDescription =>
      'Enter your phone number to check whether it is linked to a residence.';

  @override
  String get verificationCodeNotice =>
      'A verification code will be sent to your phone number.';

  @override
  String get verificationCode => 'Verification code';

  @override
  String get verificationCodeHint => 'Enter any code for testing for now';

  @override
  String get verify => 'Verify';

  @override
  String get phoneNotRegisteredTitle =>
      'This number is not registered in any residence';

  @override
  String get phoneNotRegisteredDescription =>
      'If you received an invitation link, please tap it to join the residence.';

  @override
  String get joinCodeDescription =>
      'Enter the residence code to view its information and join immediately.';

  @override
  String get searchResidence => 'Find residence';

  @override
  String get searchingResidence => 'Searching…';

  @override
  String get residenceCodeInvalid => 'Enter the 8-digit residence code.';

  @override
  String get residenceCodeNotFound => 'No residence was found with this code';

  @override
  String get residenceCodeNotFoundDescription =>
      'Check the code with the person who sent it to you, then try again.';

  @override
  String get joinRequestsClosed =>
      'Join requests are currently disabled for this residence.';

  @override
  String get sendingJoinRequest => 'Joining…';

  @override
  String get joinRequestSent => 'You joined the residence';

  @override
  String get joinRequestSentDescription =>
      'Your membership is active and you can now access the residence.';

  @override
  String get creatingResidence => 'Creating residence…';

  @override
  String get setupFieldRequired => 'This field is required.';

  @override
  String get setupCompleteRequiredFields =>
      'Complete all residence, first name, and last name fields.';

  @override
  String get setupUnexpectedError =>
      'The operation could not be completed right now. Try again.';

  @override
  String get communityFeedDescription =>
      'The latest news and announcements from Yasmeen Residence.';

  @override
  String get newPost => 'New post';

  @override
  String get officialAnnouncement => 'Official announcement';

  @override
  String get createPost => 'Create post';

  @override
  String get createPostDescription =>
      'Share a question or update with neighbors in your residence.';

  @override
  String get postTitle => 'Post title';

  @override
  String get postTitleHint => 'Write a clear title';

  @override
  String get postBody => 'Details';

  @override
  String get postBodyHint =>
      'What would you like to share with your neighbors?';

  @override
  String get publish => 'Publish';

  @override
  String get cancel => 'Cancel';

  @override
  String get directoryPageDescription =>
      'Your trusted local guide to services and places recommended by neighbors.';

  @override
  String get directorySearchHint => 'Search for a service or place...';

  @override
  String get nearby => 'Nearby';

  @override
  String get craftspeople => 'Craftspeople';

  @override
  String get restaurants => 'Restaurants';

  @override
  String get cafes => 'Cafés';

  @override
  String get pharmacies => 'Pharmacies';

  @override
  String get nearbyFacilities => 'Facilities';

  @override
  String get recommendedByNeighbors => 'Recommended by your neighbors';

  @override
  String get topRatedCraftspeople => 'Most recommended craftspeople';

  @override
  String get exploreNearby => 'Explore nearby';

  @override
  String get viewAll => 'View all';

  @override
  String get recommended => 'Recommended';

  @override
  String get recommendedFromResidence =>
      'Recommended by Yasmeen Residence residents';

  @override
  String get searchResults => 'Search results';

  @override
  String get noDirectoryResults =>
      'No matching results. Try another term or category.';

  @override
  String localRecommendations(int count) {
    return '$count recommendations from your neighbors';
  }

  @override
  String get directoryProfileNotFound => 'Directory profile not found.';

  @override
  String get recommendationScore => 'Trust score';

  @override
  String get recommendations => 'Recommendations';

  @override
  String get fromYourResidence => 'From your residence';

  @override
  String get call => 'Call';

  @override
  String get recommend => 'Recommend';

  @override
  String get workedInResidences => 'Residences previously served';

  @override
  String get recentReviews => 'Recent reviews';

  @override
  String get noReviewsYet => 'No written reviews yet.';

  @override
  String get cityProfileTrustNotice =>
      'This is one shared city profile. DarJar highlights recommendations from your residence while preserving trusted work across other residences.';

  @override
  String recommendEntry(String name) {
    return 'Recommend $name';
  }

  @override
  String get recommendationPrompt =>
      'Share your experience to help neighbors make a trusted choice.';

  @override
  String get recommendationHint => 'What stood out about the service?';

  @override
  String get publishRecommendation => 'Publish recommendation';

  @override
  String get recommendationPublished =>
      'Thanks. Your recommendation is now visible to neighbors.';

  @override
  String get residencePageDescription =>
      'Everything related to residence management in one place.';

  @override
  String get myAccount => 'My account';

  @override
  String get residenceFinances => 'Residence finances';

  @override
  String get residenceFinancesDescription =>
      'A clear view of residence income, expenses, and how the shared budget is used.';

  @override
  String get totalIncome => 'Income this year';

  @override
  String get totalExpenses => 'Expenses this year';

  @override
  String get currentBalance => 'Current balance';

  @override
  String get collectionRate => 'Collection rate';

  @override
  String get expenseBreakdown => 'Expense breakdown';

  @override
  String get recentExpenses => 'Recent expenses';

  @override
  String get viewAllTransactions => 'View all transactions';

  @override
  String get financeTransactions => 'Financial transactions';

  @override
  String get financeTransactionsDescription =>
      'A detailed record of residence income and expenses for the selected period.';

  @override
  String get selectPeriod => 'Select date range';

  @override
  String periodFromTo(String start, String end) {
    return 'From $start to $end';
  }

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get periodIncome => 'Period income';

  @override
  String get periodExpenses => 'Period expenses';

  @override
  String get noTransactionsInPeriod =>
      'No transactions in the selected period.';

  @override
  String get viewFinanceDetails => 'View residence finance details';

  @override
  String get currency => 'MAD';

  @override
  String get supportingDocument => 'Supporting document';

  @override
  String get noSupportingDocument => 'No document attached';

  @override
  String get expenseCategoryMaintenance => 'Maintenance and repairs';

  @override
  String get expenseCategoryUtilities => 'Water and electricity';

  @override
  String get expenseCategoryCleaning => 'Cleaning';

  @override
  String get expenseCategorySecurity => 'Security';

  @override
  String get duesStatus => 'Dues status';

  @override
  String get duesDescription => 'Review manually updated records.';

  @override
  String get managementInformation => 'Management information';

  @override
  String get managementSettingsDescription =>
      'Management contact and bank account details.';

  @override
  String get managementDescription => 'Contact and bank transfer information.';

  @override
  String get documents => 'Documents';

  @override
  String get documentsDescription =>
      'Official notices and documents coming soon.';

  @override
  String get duesPageDescription =>
      'A simple view of residence dues recorded by management.';

  @override
  String get manualDuesNotice =>
      'DarJar does not collect money. Payment happens outside the app and management updates the status manually.';

  @override
  String get managementPageDescription =>
      'Residence management details and available contact methods.';

  @override
  String get managementCompany => 'Management organization';

  @override
  String get phone => 'Phone';

  @override
  String get officeHours => 'Office hours';

  @override
  String get bankInformation => 'Bank transfer information';

  @override
  String get bank => 'Bank';

  @override
  String get bankName => 'Bank name';

  @override
  String get bankAccount => 'Account number';

  @override
  String get externalTransferNotice =>
      'Transfers happen outside DarJar. The application does not process payments.';

  @override
  String get profile => 'Profile';

  @override
  String get residenceAdministration => 'Residence management';

  @override
  String get residenceSettings => 'Residence settings';

  @override
  String get apartments => 'Apartments and residents';

  @override
  String get apartmentsManagementDescription =>
      'Manage apartments and resident assignments';

  @override
  String get projects => 'Projects';

  @override
  String get projectsManagementDescription =>
      'Exceptional projects, maintenance projects';

  @override
  String get residenceManagementDescription =>
      'Residence structure, residence information, dues amount';

  @override
  String get email => 'Email';

  @override
  String get residence => 'Residence';

  @override
  String get settings => 'Settings';

  @override
  String get generalSettings => 'General settings';

  @override
  String get professionalSettings => 'Professional settings';

  @override
  String get professionalAccountDescription =>
      'To manage multiple residences, please switch to a professional account.';

  @override
  String get switchToProfessionalAccount => 'Switch to a professional account';

  @override
  String get replayOnboarding => 'Replay onboarding';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllNotificationsRead => 'Mark all as read';

  @override
  String get waterInterruptionNotificationTitle =>
      'Scheduled water interruption';

  @override
  String get waterInterruptionNotificationBody =>
      'Water will be off tomorrow from 6 to 10 AM for maintenance.';

  @override
  String get duesReminderNotificationTitle => 'Residence dues reminder';

  @override
  String get duesReminderNotificationBody =>
      'Please review this month\'s dues status on the residence page.';

  @override
  String get maintenanceNotificationTitle => 'Elevator maintenance';

  @override
  String get maintenanceNotificationBody =>
      'Elevator maintenance is complete and it is available for use.';

  @override
  String get notificationTimeMinutes => '15 min ago';

  @override
  String get notificationTimeHours => '2 hours ago';

  @override
  String get notificationTimeYesterday => 'Yesterday';

  @override
  String get communityNotifications => 'Community notifications';

  @override
  String get residenceNotifications => 'Residence notifications';

  @override
  String get residenceSettingsPageDescription =>
      'Manage residence information, structure, and subscriptions.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get residenceInformation => 'Residence information';

  @override
  String get residenceInformationDescription =>
      'Core information visible to residence members.';

  @override
  String get residenceId => 'Residence ID';

  @override
  String get residenceImage => 'Residence image or logo';

  @override
  String get residenceImageOptional =>
      'Optional, and can be changed at any time.';

  @override
  String get addImage => 'Add image';

  @override
  String get removeImage => 'Remove image';

  @override
  String get address => 'Address';

  @override
  String get establishmentYear => 'Establishment year';

  @override
  String get residenceStructure => 'Residence structure';

  @override
  String get residenceStructureDescription =>
      'Create residence buildings and set a name and floor count for each one.';

  @override
  String get buildings => 'Buildings';

  @override
  String get floors => 'Floors';

  @override
  String get manageStructure => 'Manage structure';

  @override
  String get buildingName => 'Building name';

  @override
  String get buildingNameHint => 'Example: Wing A';

  @override
  String get floorCount => 'Number of floors';

  @override
  String buildingFloorCount(int count) {
    return 'Floors: $count';
  }

  @override
  String get addBuilding => 'Add building';

  @override
  String get editBuilding => 'Edit building';

  @override
  String get deleteBuilding => 'Delete building';

  @override
  String get atLeastOneBuilding =>
      'A residence must have at least one building.';

  @override
  String get checkBuildingFields =>
      'Enter a building name and a valid number of floors.';

  @override
  String get structureContainsApartments =>
      'A building or floor containing apartments cannot be removed. Delete its apartments first.';

  @override
  String confirmDeleteBuilding(String name) {
    return 'Delete $name from the residence structure?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get subscription => 'Subscription';

  @override
  String get subscriptionDescription =>
      'Set the default subscription amount for residents.';

  @override
  String get defaultSubscription => 'Default subscription';

  @override
  String get monthly => 'Monthly';

  @override
  String get amount => 'Amount';

  @override
  String get joiningResidence => 'Joining the residence';

  @override
  String get joiningResidenceDescription =>
      'Share the invitation and control new resident requests.';

  @override
  String get permanentInvitationLink => 'Permanent invitation link';

  @override
  String get copyLink => 'Copy link';

  @override
  String get showQrCode => 'Show QR code';

  @override
  String get hideQrCode => 'Hide QR code';

  @override
  String get invitationQrCode => 'Residence invitation QR code';

  @override
  String get close => 'Close';

  @override
  String get scanToJoin => 'Scan to join';

  @override
  String get allowJoinRequests => 'Allow new join requests';

  @override
  String get joinRequestsEnabledDescription =>
      'New residents can submit a request to join.';

  @override
  String get joinRequestsDisabledDescription =>
      'New join requests are currently paused.';

  @override
  String get invitationExplorationNotice =>
      'The link remains valid for exploring the residence on the web, but a new join request cannot be submitted.';

  @override
  String get invitationLinkCopied => 'Invitation link copied.';

  @override
  String get residenceSettingsSaved => 'Residence settings saved.';

  @override
  String get unsavedChangesTitle => 'Changes not saved';

  @override
  String get unsavedChangesDescription =>
      'Your changes have not been saved. Would you like to save them before leaving?';

  @override
  String get discardChanges => 'Leave without saving';

  @override
  String get checkResidenceSettingsFields =>
      'Check the residence information and subscription amount.';

  @override
  String get authPhoneTitle => 'Sign in with your phone';

  @override
  String get authPhoneDescription =>
      'We will send a short code to verify your phone number and protect your account.';

  @override
  String get authPhoneHint => '0600000001';

  @override
  String get authSendCode => 'Send verification code';

  @override
  String get authSendingCode => 'Sending code…';

  @override
  String get authCodeTitle => 'Enter the verification code';

  @override
  String authCodeDescription(String phoneNumber) {
    return 'Enter the 6-digit code sent to $phoneNumber.';
  }

  @override
  String get authCodeHint => '6 digits';

  @override
  String get authVerifying => 'Verifying…';

  @override
  String get authChangePhone => 'Change phone number';

  @override
  String get authPrivacyNotice =>
      'Your phone number is used to sign in and protect your account under the privacy policy.';

  @override
  String get authInvalidPhone => 'Enter a valid Moroccan phone number.';

  @override
  String get authInvalidCode =>
      'The verification code is incorrect. Check it and try again.';

  @override
  String get authCodeExpired => 'The code has expired. Request a new one.';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get authNetworkError =>
      'Could not connect. Check your internet connection and try again.';

  @override
  String get authUnauthorizedDomain =>
      'This domain is not authorized for sign-in. Add it to Firebase Authentication authorized domains.';

  @override
  String get authCaptchaFailed =>
      'Security verification could not be completed. Try again and complete the reCAPTCHA challenge.';

  @override
  String get authPhoneOperationNotAllowed =>
      'Phone sign-in is not allowed. Check that Morocco is allowed in the SMS region policy and that billing is linked to the project.';

  @override
  String get authUnexpectedError => 'Could not sign in right now. Try again.';

  @override
  String get accountResolutionTitle => 'Confirm your information';

  @override
  String get accountResolutionDescription =>
      'Check your information, then select the residences you belong to.';

  @override
  String get accountResolutionFullName => 'Full name';

  @override
  String get accountResolutionInvitationsTitle =>
      'You have been invited to these residences';

  @override
  String get accountResolutionInvitationsDescription =>
      'Select the residences you belong to. Unselected invitations will remain pending for later.';

  @override
  String accountResolutionRole(String role) {
    return 'Role: $role';
  }

  @override
  String get accountRoleResident => 'Resident';

  @override
  String get accountRoleModerator => 'Moderator';

  @override
  String get accountRoleManager => 'Manager';

  @override
  String get accountRoleOwner => 'Owner';

  @override
  String get accountResolutionConfirm => 'Confirm and join selected residences';

  @override
  String get accountResolutionAccepting => 'Confirming memberships…';

  @override
  String get accountResolutionPendingNotice =>
      'Unselected residences will not be declined; their invitations will remain pending.';

  @override
  String get accountResolutionRetry => 'Try again';

  @override
  String get accountResolutionPermissionDenied =>
      'The database rules do not allow these invitations to be read or accepted. Deploy the new Firestore rules and try again.';

  @override
  String get accountResolutionFailedPrecondition =>
      'The required database index is not ready yet. Wait for it to finish building, then try again.';

  @override
  String get accountResolutionMissingProfile =>
      'The first or last name in the invitation is incomplete.';

  @override
  String get accountResolutionSignedOut =>
      'Your sign-in session ended. Sign in again.';

  @override
  String get accountResolutionUnexpectedError =>
      'Invitations could not be loaded or confirmed right now. Try again.';
}
