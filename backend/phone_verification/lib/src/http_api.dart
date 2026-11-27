import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'phone_verification_service.dart';
import 'professional_profiles.dart';
import 'residence_deletion.dart';

class PhoneVerificationApi {
  PhoneVerificationApi({
    required PhoneVerificationService service,
    required Set<String> allowedOrigins,
    String? localDevelopmentSecret,
    ProfessionalProfiles? professionalProfiles,
    ResidenceDeletion? residenceDeletion,
    Future<VerifiedProfessionalIdentity> Function(String)?
    verifyProfessionalToken,
  }) : this._(
         service,
         allowedOrigins,
         localDevelopmentSecret?.trim() ?? '',
         professionalProfiles,
         residenceDeletion,
         verifyProfessionalToken,
       );

  PhoneVerificationApi._(
    this._service,
    this._allowedOrigins,
    this._localDevelopmentSecret,
    this._professionalProfiles,
    this._residenceDeletion,
    this._verifyProfessionalToken,
  );

  final PhoneVerificationService _service;
  final Set<String> _allowedOrigins;
  final String _localDevelopmentSecret;
  final ProfessionalProfiles? _professionalProfiles;
  final ResidenceDeletion? _residenceDeletion;
  final Future<VerifiedProfessionalIdentity> Function(String)?
  _verifyProfessionalToken;

  Handler get handler {
    final router = Router()
      ..get('/health', (Request request) => Response.ok('ok'))
      ..post('/v1/phone-verifications', _start)
      ..post('/v1/phone-verifications/<sessionId>/check', _check);
    if (_professionalProfiles != null && _verifyProfessionalToken != null) {
      router.post('/v1/professional-profile/<action>', _professionalProfile);
    }
    if (_residenceDeletion != null && _verifyProfessionalToken != null) {
      router.post('/v1/residences/delete', _deleteResidence);
    }
    return const Pipeline()
        .addMiddleware(_securityHeaders)
        .addMiddleware(_cors)
        .addMiddleware(_preflight)
        .addMiddleware(logRequests())
        .addHandler(router.call);
  }

  Future<Response> _professionalProfile(Request request, String action) async {
    try {
      final input = await _requestJson(request);
      final identity = await _verifiedIdentity(request);
      final profiles = _professionalProfiles!;
      switch (action) {
        case 'discover':
          return _jsonResponse(
            HttpStatus.ok,
            await profiles.discover(identity),
          );
        case 'claim':
          final id = input['serviceId'];
          if (id is! String) {
            throw const FormatException('A service ID is required.');
          }
          return _jsonResponse(HttpStatus.ok, {
            'serviceId': await profiles.claim(identity, id, input),
          });
        case 'create':
          return _jsonResponse(HttpStatus.created, {
            'serviceId': await profiles.create(identity, input),
          });
        case 'set-availability':
          final id = input['serviceId'];
          final paused = input['paused'];
          if (id is! String || paused is! bool) {
            throw const FormatException(
              'A service ID and availability are required.',
            );
          }
          await profiles.setPaused(identity, id, paused: paused);
          return _jsonResponse(HttpStatus.ok, {'serviceId': id});
        case 'delete':
          final id = input['serviceId'];
          if (id is! String) {
            throw const FormatException('A service ID is required.');
          }
          await profiles.delete(identity, id);
          return _jsonResponse(HttpStatus.ok, {'serviceId': id});
        default:
          return _jsonResponse(HttpStatus.notFound, {
            'code': 'invalid-request',
          });
      }
    } on ProfessionalFailure catch (error) {
      return _jsonResponse(error.status, {'code': error.code});
    } on FormatException {
      return _jsonResponse(HttpStatus.badRequest, {'code': 'invalid-request'});
    } catch (error, stackTrace) {
      stderr.writeln('$error\n$stackTrace');
      return _jsonResponse(HttpStatus.internalServerError, {
        'code': 'professional-service-error',
      });
    }
  }

  Future<Response> _deleteResidence(Request request) async {
    try {
      final identity = await _verifiedIdentity(request);
      final input = await _requestJson(request);
      final id = input['residenceId'];
      if (id is! String) throw const FormatException();
      await _residenceDeletion!.delete(id, identity.uid);
      return _jsonResponse(HttpStatus.ok, {'residenceId': id});
    } on ResidenceDeletionFailure catch (error) {
      return _jsonResponse(error.status, {'code': error.code});
    } on ProfessionalFailure catch (error) {
      return _jsonResponse(error.status, {'code': error.code});
    } on FormatException {
      return _jsonResponse(HttpStatus.badRequest, {'code': 'invalid-request'});
    } catch (error, stackTrace) {
      stderr.writeln('$error\n$stackTrace');
      return _jsonResponse(HttpStatus.internalServerError, {
        'code': 'residence-delete-failed',
      });
    }
  }

  Future<VerifiedProfessionalIdentity> _verifiedIdentity(Request request) {
    final authorization = request.headers['authorization'] ?? '';
    if (!authorization.startsWith('Bearer ') || authorization.length > 8192) {
      throw const ProfessionalFailure(
        'invalid-identity',
        HttpStatus.unauthorized,
      );
    }
    return _verifyProfessionalToken!(authorization.substring(7));
  }

  Future<Response> _start(Request request) async {
    try {
      final body = await _requestJson(request);
      final phoneNumber = body['phoneNumber'] as String? ?? '';
      final languageCode = body['languageCode'] as String? ?? 'ar';
      final localDevelopmentRequest = isLocalDevelopmentAuthRequest(
        origin: request.headers['origin'],
        phoneNumber: phoneNumber,
      );
      if (localDevelopmentRequest) {
        if (!canUseLocalDevelopmentAuth(
          origin: request.headers['origin'],
          phoneNumber: phoneNumber,
          providedSecret: request.headers['x-darjar-local-auth'],
          configuredSecret: _localDevelopmentSecret,
        )) {
          throw const VerificationFailure('local-auth-not-authorized');
        }
        final customToken = await _service.authenticateWithoutSms(phoneNumber);
        return _jsonResponse(HttpStatus.created, {'customToken': customToken});
      }
      final sessionId = await _service.start(
        phoneNumber,
        languageCode: languageCode,
      );
      return _jsonResponse(HttpStatus.created, {'sessionId': sessionId});
    } on VerificationFailure catch (error, stackTrace) {
      return _failure(error, stackTrace);
    } on FormatException catch (error) {
      return _jsonResponse(HttpStatus.badRequest, {
        'code': 'invalid-request',
        'message': error.message,
      });
    } catch (error, stackTrace) {
      stderr.writeln('$error\n$stackTrace');
      return _jsonResponse(HttpStatus.internalServerError, {
        'code': 'authentication-service-error',
      });
    }
  }

  Future<Response> _check(Request request, String sessionId) async {
    try {
      final body = await _requestJson(request);
      final code = body['code'] as String? ?? '';
      final customToken = await _service.check(
        sessionId: sessionId,
        code: code,
      );
      return _jsonResponse(HttpStatus.ok, {'customToken': customToken});
    } on VerificationFailure catch (error, stackTrace) {
      return _failure(error, stackTrace);
    } on FormatException catch (error) {
      return _jsonResponse(HttpStatus.badRequest, {
        'code': 'invalid-request',
        'message': error.message,
      });
    } catch (error, stackTrace) {
      stderr.writeln('$error\n$stackTrace');
      return _jsonResponse(HttpStatus.internalServerError, {
        'code': 'authentication-service-error',
      });
    }
  }

  Response _failure(VerificationFailure error, StackTrace stackTrace) {
    if (error.code == 'authentication-service-error' ||
        error.code == 'verification-provider-error') {
      stderr.writeln('${error.code}: ${error.message}\n$stackTrace');
    }
    final status = switch (error.code) {
      'invalid-phone-number' ||
      'invalid-verification-code' ||
      'invalid-request' => HttpStatus.badRequest,
      'missing-verification-session' || 'session-expired' => HttpStatus.gone,
      'local-auth-not-authorized' => HttpStatus.forbidden,
      'too-many-requests' => HttpStatus.tooManyRequests,
      _ => HttpStatus.badGateway,
    };
    return _jsonResponse(status, {'code': error.code});
  }

  Future<Map<String, Object?>> _requestJson(Request request) async {
    final contentType = request.headers['content-type'] ?? '';
    if (!contentType.toLowerCase().startsWith('application/json')) {
      throw const FormatException('Content-Type must be application/json.');
    }
    final raw = await request.readAsString();
    if (raw.length > 4096) throw const FormatException('Request is too large.');
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Request body must be a JSON object.');
    }
    return decoded;
  }

  Response _jsonResponse(int status, Map<String, Object?> body) => Response(
    status,
    body: jsonEncode(body),
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );

  Middleware get _cors =>
      (innerHandler) => (request) async {
        final response = await innerHandler(request);
        final origin = request.headers['origin'];
        if (!isAllowedPhoneVerificationOrigin(origin, _allowedOrigins)) {
          return response;
        }
        return response.change(
          headers: {
            ...response.headers,
            'access-control-allow-origin': origin,
            'access-control-allow-methods': 'POST, OPTIONS',
            'access-control-allow-headers':
                'Authorization, Content-Type, X-Darjar-Local-Auth',
            'access-control-max-age': '3600',
            'vary': 'Origin',
          },
        );
      };

  Middleware get _securityHeaders =>
      (innerHandler) => (request) async {
        final response = await innerHandler(request);
        return response.change(
          headers: {
            ...response.headers,
            'cache-control': 'no-store',
            'x-content-type-options': 'nosniff',
            'referrer-policy': 'no-referrer',
          },
        );
      };

  Middleware get _preflight =>
      (innerHandler) => (request) {
        if (request.method == 'OPTIONS') {
          return Response.ok('');
        }
        return innerHandler(request);
      };
}

const localDevelopmentPhoneNumber = '+212708708001';

bool isLocalDevelopmentAuthRequest({
  required String? origin,
  required String phoneNumber,
}) =>
    isLoopbackPhoneVerificationOrigin(origin) &&
    phoneNumber == localDevelopmentPhoneNumber;

bool canUseLocalDevelopmentAuth({
  required String? origin,
  required String phoneNumber,
  required String? providedSecret,
  required String configuredSecret,
}) {
  if (!isLocalDevelopmentAuthRequest(
        origin: origin,
        phoneNumber: phoneNumber,
      ) ||
      configuredSecret.length < 32 ||
      providedSecret == null ||
      providedSecret.length != configuredSecret.length) {
    return false;
  }
  var difference = 0;
  for (var index = 0; index < configuredSecret.length; index += 1) {
    difference |=
        configuredSecret.codeUnitAt(index) ^ providedSecret.codeUnitAt(index);
  }
  return difference == 0;
}

bool isAllowedPhoneVerificationOrigin(
  String? origin,
  Set<String> configuredOrigins,
) {
  if (origin == null || origin.isEmpty) return false;
  if (configuredOrigins.contains(origin)) return true;
  return isLoopbackPhoneVerificationOrigin(origin);
}

bool isLoopbackPhoneVerificationOrigin(String? origin) {
  if (origin == null || origin.isEmpty) return false;
  final uri = Uri.tryParse(origin);
  if (uri == null || uri.scheme != 'http') return false;
  return uri.host == 'localhost' ||
      uri.host == '127.0.0.1' ||
      uri.host == '::1';
}
