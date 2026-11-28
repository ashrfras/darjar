import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import 'phone_verification_service.dart';
import 'professional_profiles.dart';
import 'http_api.dart' show localDevelopmentPhoneNumber;

const _cloudPlatformScope = 'https://www.googleapis.com/auth/cloud-platform';
const _customTokenAudience =
    'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit';

class GoogleCloudIdentityGateway implements FirebaseIdentityGateway {
  GoogleCloudIdentityGateway({
    required String projectId,
    required String apiKey,
    required String signerEmail,
    required http.Client client,
  }) : this._(projectId, apiKey, signerEmail, client);

  GoogleCloudIdentityGateway._(
    this._projectId,
    this._apiKey,
    this._signerEmail,
    this._client,
  );

  final String _projectId;
  final String _apiKey;
  final String _signerEmail;
  final http.Client _client;

  static Future<GoogleCloudIdentityGateway> create({
    required String projectId,
    required String apiKey,
    required String signerEmail,
  }) async {
    final client = await clientViaApplicationDefaultCredentials(
      scopes: const [_cloudPlatformScope],
    );
    return GoogleCloudIdentityGateway(
      projectId: projectId,
      apiKey: apiKey,
      signerEmail: signerEmail,
      client: client,
    );
  }

  Uri _accountsUri({String suffix = ''}) => Uri.https(
    'identitytoolkit.googleapis.com',
    '/v1/projects/$_projectId/accounts$suffix',
    {'key': _apiKey},
  );

  Future<VerifiedProfessionalIdentity> verifyProfessionalToken(
    String token,
  ) async {
    final identity = await _verifyFirebasePhoneToken(token);
    if (identity.phone == localDevelopmentPhoneNumber) {
      throw const ProfessionalFailure('invalid-identity', 401);
    }
    return identity;
  }

  Future<String> verifyResidenceDeletionToken(String token) async {
    final identity = await _verifyFirebasePhoneToken(token);
    return identity.uid;
  }

  Future<VerifiedProfessionalIdentity> _verifyFirebasePhoneToken(
    String token,
  ) async {
    const unauthorized = ProfessionalFailure('invalid-identity', 401);
    final segments = token.split('.');
    if (segments.length != 3) throw unauthorized;
    Map<String, dynamic> claims;
    try {
      claims =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
              )
              as Map<String, dynamic>;
    } catch (_) {
      throw unauthorized;
    }
    final uid = claims['sub'];
    if (claims['aud'] != _projectId ||
        claims['iss'] != 'https://securetoken.google.com/$_projectId' ||
        uid is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(uid) ||
        claims['firebase'] is! Map ||
        claims['firebase']['tenant'] != null) {
      throw unauthorized;
    }
    // Identity Toolkit verifies the signature and validity of the Firebase ID
    // token, and supplies the current phone number from the Firebase user record.
    final response = await http.post(
      Uri.https('identitytoolkit.googleapis.com', '/v1/accounts:lookup', {
        'key': _apiKey,
      }),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'idToken': token}),
    );
    if (response.statusCode == 400 || response.statusCode == 401) {
      throw unauthorized;
    }
    if (response.statusCode != 200) {
      throw const ProfessionalFailure('identity-service-unavailable', 503);
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    final users = result['users'] as List<dynamic>? ?? const [];
    if (users.length != 1) throw unauthorized;
    final user = users.single as Map<String, dynamic>;
    final phone = user['phoneNumber'];
    final validSince = int.tryParse('${user['validSince']}') ?? 0;
    final authTime = claims['auth_time'];
    if (user['localId'] != uid ||
        user['disabled'] == true ||
        authTime is! int ||
        authTime < validSince ||
        phone is! String ||
        phone != claims['phone_number'] ||
        !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(phone)) {
      throw unauthorized;
    }
    return (uid: uid, phone: phone);
  }

  @override
  Future<String> findOrCreateUser(String phoneNumber) async {
    final existing = await _lookup(phoneNumber);
    if (existing != null) return existing;

    final uid = 'phone_${sha256.convert(utf8.encode(phoneNumber))}';
    final response = await _client.post(
      _accountsUri(),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'localId': uid, 'phoneNumber': phoneNumber}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return uid;

    // A simultaneous request may have created the same phone account.
    final racedUser = await _lookup(phoneNumber);
    if (racedUser != null) return racedUser;
    throw _googleFailure(response, 'create Firebase user');
  }

  Future<String?> _lookup(String phoneNumber) async {
    final response = await _client.post(
      _accountsUri(suffix: ':lookup'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': [phoneNumber],
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _googleFailure(response, 'lookup Firebase user');
    }
    final body = jsonDecode(response.body) as Map<String, Object?>;
    final users = body['users'] as List<Object?>? ?? const [];
    if (users.isEmpty) return null;
    return (users.first! as Map<String, Object?>)['localId'] as String;
  }

  @override
  Future<String> createCustomToken({
    required String uid,
    required String phoneNumber,
  }) async {
    final issuedAt = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final header = _base64UrlJson({'alg': 'RS256', 'typ': 'JWT'});
    final payload = _base64UrlJson({
      'iss': _signerEmail,
      'sub': _signerEmail,
      'aud': _customTokenAudience,
      'iat': issuedAt,
      'exp': issuedAt + 3600,
      'uid': uid,
      'claims': {'phone_number': phoneNumber, 'phone_verified': true},
    });
    final unsignedToken = '$header.$payload';
    final response = await _client.post(
      Uri.parse(
        'https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/'
        '${Uri.encodeComponent(_signerEmail)}:signBlob',
      ),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'payload': base64Encode(utf8.encode(unsignedToken))}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _googleFailure(response, 'sign Firebase custom token');
    }
    final body = jsonDecode(response.body) as Map<String, Object?>;
    final signature = base64Decode(body['signedBlob'] as String);
    return '$unsignedToken.${base64UrlEncode(signature).replaceAll('=', '')}';
  }
}

String _base64UrlJson(Map<String, Object?> value) =>
    base64UrlEncode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

VerificationFailure _googleFailure(http.Response response, String operation) {
  return VerificationFailure(
    'authentication-service-error',
    message: '$operation failed (${response.statusCode}): ${response.body}',
  );
}
