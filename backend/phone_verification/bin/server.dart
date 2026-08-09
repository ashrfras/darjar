import 'dart:io';

import 'package:darjar_phone_verification/src/firestore_verification_session_store.dart';
import 'package:darjar_phone_verification/src/google_cloud_identity_gateway.dart';
import 'package:darjar_phone_verification/src/http_api.dart';
import 'package:darjar_phone_verification/src/phone_verification_service.dart';
import 'package:darjar_phone_verification/src/zavu_sms_gateway.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:shelf/shelf_io.dart';

const _cloudPlatformScope = 'https://www.googleapis.com/auth/cloud-platform';

Future<void> main() async {
  final environment = Platform.environment;
  final projectId = _required(
    environment,
    'GOOGLE_CLOUD_PROJECT',
    fallbackKey: 'GCP_PROJECT',
  );
  final signerEmail = _required(environment, 'FIREBASE_TOKEN_SIGNER_EMAIL');
  final firebaseApiKey = _required(environment, 'FIREBASE_API_KEY');
  final zavuApiKey = _required(environment, 'ZAVU_API_KEY');
  final otpHashPepper = _required(environment, 'OTP_HASH_PEPPER');
  if (otpHashPepper.length < 32) {
    stderr.writeln('OTP_HASH_PEPPER must contain at least 32 characters.');
    exit(78);
  }
  final zavuSenderId = environment['ZAVU_SENDER_ID']?.trim();
  final allowedOrigins = (environment['ALLOWED_ORIGINS'] ?? '')
      .split(',')
      .map((origin) => origin.trim())
      .where((origin) => origin.isNotEmpty)
      .toSet();

  final firestoreClient = await clientViaApplicationDefaultCredentials(
    scopes: const [_cloudPlatformScope],
  );
  final identity = await GoogleCloudIdentityGateway.create(
    projectId: projectId,
    apiKey: firebaseApiKey,
    signerEmail: signerEmail,
  );
  final service = PhoneVerificationService(
    sms: HttpZavuSmsGateway(
      apiKey: zavuApiKey,
      senderId: zavuSenderId?.isEmpty == true ? null : zavuSenderId,
    ),
    sessions: FirestoreVerificationSessionStore(
      projectId: projectId,
      client: firestoreClient,
    ),
    firebaseIdentity: identity,
    otpHashPepper: otpHashPepper,
  );
  final handler = PhoneVerificationApi(
    service: service,
    allowedOrigins: allowedOrigins,
    localDevelopmentSecret: environment['LOCAL_DEVELOPMENT_AUTH_SECRET'],
  ).handler;
  final port = int.tryParse(environment['PORT'] ?? '') ?? 8080;
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('Listening on ${server.address.host}:${server.port}');
}

String _required(
  Map<String, String> environment,
  String key, {
  String? fallbackKey,
}) {
  final value =
      environment[key] ??
      (fallbackKey == null ? null : environment[fallbackKey]);
  if (value == null || value.trim().isEmpty) {
    stderr.writeln('$key is required.');
    exit(78);
  }
  return value.trim();
}
