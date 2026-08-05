import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import 'phone_verification_service.dart';

const _cloudPlatformScope = 'https://www.googleapis.com/auth/cloud-platform';
const _customTokenAudience =
    'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit';

class GoogleCloudIdentityGateway implements FirebaseIdentityGateway {
  GoogleCloudIdentityGateway._({
    required String projectId,
    required String apiKey,
    required String signerEmail,
    required AutoRefreshingAuthClient client,
  }) : this._values(projectId, apiKey, signerEmail, client);

  GoogleCloudIdentityGateway._values(
    this._projectId,
    this._apiKey,
    this._signerEmail,
    this._client,
  );

  final String _projectId;
  final String _apiKey;
  final String _signerEmail;
  final AutoRefreshingAuthClient _client;

  static Future<GoogleCloudIdentityGateway> create({
    required String projectId,
    required String apiKey,
    required String signerEmail,
  }) async {
    final client = await clientViaApplicationDefaultCredentials(
      scopes: const [_cloudPlatformScope],
    );
    return GoogleCloudIdentityGateway._(
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
