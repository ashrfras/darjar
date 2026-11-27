import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

typedef VerifiedProfessionalIdentity = ({String uid, String phone});

class ProfessionalFailure implements Exception {
  const ProfessionalFailure(this.code, this.status);
  final String code;
  final int status;
}

class ProfessionalProfiles {
  ProfessionalProfiles({
    required String projectId,
    required this.client,
    Uri? firestoreOrigin,
  }) : _origin = firestoreOrigin ?? Uri.https('firestore.googleapis.com'),
       _database = 'projects/$projectId/databases/(default)';

  final http.Client client;
  final Uri _origin;
  final String _database;
  String get _documents => '$_database/documents';

  Future<Map<String, Object?>> discover(
    VerifiedProfessionalIdentity identity,
  ) async {
    final user = await _read('users/${identity.uid}');
    _checkAccount(user);
    if (_string(user, 'professionalServiceId').isNotEmpty) {
      return {'candidates': const []};
    }
    final matches = await _matches(identity.phone);
    final candidates = [
      for (final match in matches)
        if (_claimable(match.fields))
          {
            'id': match.id,
            'name': _string(match.fields, 'name'),
            'profession': _string(match.fields, 'profession'),
            'categoryId': _string(match.fields, 'categoryId'),
          },
    ];
    if (matches.isNotEmpty && candidates.isEmpty) {
      throw const ProfessionalFailure('directory-phone-exists', 409);
    }
    return {'candidates': candidates};
  }

  Future<String> claim(
    VerifiedProfessionalIdentity identity,
    String serviceId,
    Map<String, Object?> input,
  ) async {
    if (!_validId(serviceId)) {
      throw const ProfessionalFailure('invalid-request', 400);
    }
    return _transaction((transaction) async {
      final user = await _read('users/${identity.uid}', transaction);
      _checkAccount(user);
      final service = await _read('services/$serviceId', transaction);
      final owned = _string(user, 'professionalServiceId');
      if (owned == serviceId &&
          _string(service, 'ownerUid') == identity.uid &&
          _isManageable(service)) {
        return (serviceId, [_accountWrite(identity, user, serviceId, input)]);
      }
      if (owned.isNotEmpty || await _phoneReserved(identity, transaction)) {
        throw const ProfessionalFailure('already-owns-service', 409);
      }
      if (service == null ||
          !_claimable(service) ||
          normalizeDirectoryPhone(_string(service, 'phone')) !=
              identity.phone) {
        throw const ProfessionalFailure('service-not-claimable', 409);
      }
      return (
        serviceId,
        [
          _write(
            'services/$serviceId',
            {'ownerUid': identity.uid},
            merge: true,
            timestamps: ['claimedAt'],
          ),
          _accountWrite(identity, user, serviceId, input),
          _phoneWrite(identity, serviceId),
        ],
      );
    });
  }

  Future<String> create(
    VerifiedProfessionalIdentity identity,
    Map<String, Object?> input,
  ) async {
    final name = _input(input, 'name', 120, required: true);
    final categoryId = _input(input, 'categoryId', 120, required: true);
    final city = _input(input, 'city', 10, required: true);
    final subcategories = input['subcategoryIds'];
    if (!_validId(categoryId) ||
        !RegExp(r'^[0-9]{7,10}$').hasMatch(city) ||
        subcategories is! List ||
        subcategories.isEmpty ||
        subcategories.length > 8 ||
        !subcategories.every((value) => value is String && _validId(value)) ||
        subcategories.toSet().length != subcategories.length) {
      throw const ProfessionalFailure('invalid-service', 400);
    }
    final fields = <String, Object?>{
      'name': name,
      'categoryId': categoryId,
      'subcategoryIds': subcategories,
      'profession': _input(input, 'profession', 160),
      'neighborhood': _input(input, 'neighborhood', 120),
      'city': city,
      'phone': identity.phone,
      'createdBy': identity.uid,
      'ownerUid': identity.uid,
      'source': 'professional',
      'status': 'active',
    };
    return _transaction((transaction) async {
      final user = await _read('users/${identity.uid}', transaction);
      _checkAccount(user);
      final owned = _string(user, 'professionalServiceId');
      if (owned.isNotEmpty) {
        // Reuse the active listing when a successful creation is retried.
        final service = await _read('services/$owned', transaction);
        if (_string(service, 'source') == 'professional' &&
            _string(service, 'ownerUid') == identity.uid &&
            _isManageable(service)) {
          return (owned, [_accountWrite(identity, user, owned, input)]);
        }
        throw const ProfessionalFailure('already-owns-service', 409);
      }
      if (await _phoneReserved(identity, transaction)) {
        throw const ProfessionalFailure('already-owns-service', 409);
      }
      if ((await _matches(identity.phone, transaction)).isNotEmpty) {
        throw const ProfessionalFailure('directory-phone-exists', 409);
      }
      final category = await _read(
        'serviceCategories/$categoryId',
        transaction,
      );
      final validSubcategories =
          category?['subcategoryIds'] as List? ?? const [];
      if (!subcategories.every(validSubcategories.contains)) {
        throw const ProfessionalFailure('invalid-service', 400);
      }
      // A new listing never inherits the reviews of a deleted listing.
      final random = Random.secure();
      final id =
          'professional_${base64UrlEncode(List.generate(18, (_) => random.nextInt(256)))}';
      return (
        id,
        [
          _write(
            'services/$id',
            fields,
            create: true,
            timestamps: ['createdAt'],
          ),
          _accountWrite(identity, user, id, input),
          _phoneWrite(identity, id),
        ],
      );
    });
  }

  Future<void> setPaused(
    VerifiedProfessionalIdentity identity,
    String serviceId, {
    required bool paused,
  }) async {
    if (!_validId(serviceId)) {
      throw const ProfessionalFailure('invalid-request', 400);
    }
    await _transaction((transaction) async {
      final user = await _read('users/${identity.uid}', transaction);
      _checkAccount(user);
      final path = 'services/$serviceId';
      final service = await _read(path, transaction);
      if (_string(user, 'professionalServiceId') != serviceId ||
          _string(service, 'ownerUid') != identity.uid ||
          !_isManageable(service)) {
        throw const ProfessionalFailure('not-service-owner', 403);
      }
      return (
        serviceId,
        [
          _write(
            path,
            {'status': paused ? 'paused' : 'active'},
            merge: true,
            timestamps: ['updatedAt'],
          ),
        ],
      );
    });
  }

  Future<void> delete(
    VerifiedProfessionalIdentity identity,
    String serviceId,
  ) async {
    if (!_validId(serviceId)) {
      throw const ProfessionalFailure('invalid-request', 400);
    }
    await _transaction((transaction) async {
      final userPath = 'users/${identity.uid}';
      final servicePath = 'services/$serviceId';
      final user = await _read(userPath, transaction);
      _checkAccount(user);
      final service = await _read(servicePath, transaction);
      final owned = _string(user, 'professionalServiceId');
      if (service == null && owned != serviceId) {
        return (serviceId, const <Map<String, Object?>>[]);
      }
      if (owned != serviceId || _string(service, 'ownerUid') != identity.uid) {
        throw const ProfessionalFailure('not-service-owner', 403);
      }
      if (_positiveNumber(service?['score']) ||
          _positiveNumber(service?['recommendationCount']) ||
          _hasStoredReviews(service?['reviews']) ||
          await _hasRecommendations(serviceId, transaction)) {
        throw const ProfessionalFailure('service-has-feedback', 409);
      }
      final phone = normalizeDirectoryPhone(_string(service, 'phone'));
      final reservationPath = phone == null ? null : _phonePath(phone);
      final reservation = reservationPath == null
          ? null
          : await _read(reservationPath, transaction);
      return (
        serviceId,
        [
          {'delete': '$_documents/$servicePath'},
          _write(
            userPath,
            const {},
            merge: true,
            removeFields: ['professionalServiceId', 'activeSpaceType'],
            timestamps: ['updatedAt'],
          ),
          if (reservationPath != null &&
              _string(reservation, 'ownerUid') == identity.uid &&
              _string(reservation, 'serviceId') == serviceId)
            {'delete': '$_documents/$reservationPath'},
        ],
      );
    });
  }

  String _phonePath(String phone) => 'professionalPhones/$phone';

  Future<bool> _phoneReserved(
    VerifiedProfessionalIdentity identity,
    String transaction,
  ) async => await _read(_phonePath(identity.phone), transaction) != null;

  Map<String, Object?> _phoneWrite(
    VerifiedProfessionalIdentity identity,
    String id,
  ) => _write(_phonePath(identity.phone), {
    'ownerUid': identity.uid,
    'serviceId': id,
  }, create: true);

  Map<String, Object?> _accountWrite(
    VerifiedProfessionalIdentity identity,
    Map<String, Object?>? user,
    String id,
    Map<String, Object?> input,
  ) => _write(
    'users/${identity.uid}',
    {
      if (user == null) ...{
        'firstName': _input(input, 'firstName', 120, required: true),
        'lastName': _input(input, 'lastName', 120, required: true),
        'phoneNumber': identity.phone,
      },
      'professionalServiceId': id,
      'activeSpaceType': 'professional',
    },
    merge: user != null,
    create: user == null,
    timestamps: [if (user == null) 'createdAt', 'updatedAt'],
  );

  void _checkAccount(Map<String, Object?>? user) {
    if (_string(user, 'accountStatus') == 'deletionRequested') {
      throw const ProfessionalFailure('account-unavailable', 403);
    }
  }

  Future<List<({String id, Map<String, Object?> fields})>> _matches(
    String phone, [
    String? transaction,
  ]) async {
    final aliases = _phoneAliases(phone);
    final result =
        await _post(':runQuery', {
              'transaction': ?transaction,
              'structuredQuery': {
                'from': [
                  {'collectionId': 'services'},
                ],
                'where': {
                  'fieldFilter': {
                    'field': {'fieldPath': 'phone'},
                    'op': 'IN',
                    'value': _value(aliases.toList()),
                  },
                },
              },
            })
            as List;
    return [
          for (final row in result.cast<Map<String, dynamic>>())
            if (row['document'] case final Map<String, dynamic> document)
              (
                id: (document['name'] as String).split('/').last,
                fields: _fields(document),
              ),
        ]
        .where(
          (match) =>
              normalizeDirectoryPhone(_string(match.fields, 'phone')) == phone,
        )
        .toList();
  }

  Future<bool> _hasRecommendations(String serviceId, String transaction) async {
    final result =
        await _post(':runQuery', {
              'transaction': transaction,
              'structuredQuery': {
                'from': [
                  {'collectionId': 'directoryRecommendations'},
                ],
                'where': {
                  'fieldFilter': {
                    'field': {'fieldPath': 'entryId'},
                    'op': 'EQUAL',
                    'value': _value(serviceId),
                  },
                },
                'limit': 1,
              },
            })
            as List;
    return result.any((row) => row['document'] != null);
  }

  Future<String> _transaction(
    Future<(String, List<Map<String, Object?>>)> Function(String) run,
  ) async {
    String? previousTransaction;
    for (var attempt = 0; attempt < 5; attempt++) {
      final begun =
          await _post(':beginTransaction', {
                if (previousTransaction != null)
                  'options': {
                    'readWrite': {'retryTransaction': previousTransaction},
                  },
              })
              as Map<String, dynamic>;
      final transaction = begun['transaction'] as String;
      try {
        final (id, writes) = await run(transaction);
        await _post(':commit', {'transaction': transaction, 'writes': writes});
        return id;
      } catch (error) {
        try {
          await _post(':rollback', {'transaction': transaction});
        } catch (_) {
          // Firestore may have already closed the transaction.
        }
        if (error is! _FirestoreFailure ||
            error.status != 'ABORTED' ||
            attempt == 4) {
          rethrow;
        }
        previousTransaction = transaction;
        await Future<void>.delayed(Duration(milliseconds: 25 << attempt));
      }
    }
    throw StateError('Firestore transaction retries exhausted');
  }

  Future<Map<String, Object?>?> _read(
    String path, [
    String? transaction,
  ]) async {
    final result =
        await _post(':batchGet', {
              'documents': ['$_documents/$path'],
              'transaction': ?transaction,
            })
            as List;
    final row = result.single as Map<String, dynamic>;
    final document = row['found'];
    return document is Map<String, dynamic> ? _fields(document) : null;
  }

  Future<Object?> _post(String path, Map<String, Object?> body) async =>
      _decode(
        await client.post(
          _uri(path),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode(body),
        ),
      );

  Uri _uri(String path) => _origin.replace(path: '/v1/$_documents$path');

  Map<String, Object?> _write(
    String path,
    Map<String, Object?> fields, {
    bool merge = false,
    bool create = false,
    List<String> timestamps = const [],
    List<String> removeFields = const [],
  }) => {
    'update': {
      'name': '$_documents/$path',
      'fields': fields.map((key, value) => MapEntry(key, _value(value))),
    },
    if (merge)
      'updateMask': {
        'fieldPaths': [...fields.keys, ...removeFields],
      },
    'currentDocument': {'exists': !create},
    'updateTransforms': [
      for (final field in timestamps)
        {'fieldPath': field, 'setToServerValue': 'REQUEST_TIME'},
    ],
  };
}

class _FirestoreFailure implements Exception {
  const _FirestoreFailure(this.status);
  final String status;
  @override
  String toString() =>
      'Firestore professional profile request failed ($status)';
}

Object? _decode(http.Response response) {
  final result = jsonDecode(response.body);
  if (response.statusCode >= 200 && response.statusCode < 300) return result;
  final error = result is Map ? result['error'] : null;
  throw _FirestoreFailure(
    error is Map ? error['status'].toString() : '${response.statusCode}',
  );
}

Map<String, Object?> _fields(Map<String, dynamic> document) =>
    (document['fields'] as Map<String, dynamic>? ?? const {}).map(
      (key, value) => MapEntry(
        key,
        value['stringValue'] ??
            value['doubleValue'] ??
            num.tryParse('${value['integerValue']}') ??
            (value['arrayValue']?['values'] as List?)
                ?.map((item) => item['stringValue'])
                .toList(),
      ),
    );

Map<String, Object?> _value(Object? value) => switch (value) {
  String value => {'stringValue': value},
  List values => {
    'arrayValue': {'values': values.map(_value).toList()},
  },
  _ => throw ArgumentError.value(value),
};

bool _validId(String value) =>
    RegExp(r'^[A-Za-z0-9_-]{1,200}$').hasMatch(value);

bool _positiveNumber(Object? value) => value is num && value > 0;

bool _hasStoredReviews(Object? value) => value is List && value.isNotEmpty;

bool _isManageable(Map<String, Object?>? fields) =>
    const ['active', 'paused'].contains(_string(fields, 'status'));

bool _claimable(Map<String, Object?> fields) =>
    _string(fields, 'status') == 'active' &&
    _string(fields, 'ownerUid').isEmpty;

String _string(Map<String, Object?>? fields, String key) =>
    fields?[key] is String ? fields![key]! as String : '';

String _input(
  Map<String, Object?> input,
  String key,
  int max, {
  bool required = false,
}) {
  final value = _string(input, key).trim();
  if ((required && value.isEmpty) || value.length > max) {
    throw ProfessionalFailure(
      key == 'firstName' || key == 'lastName'
          ? 'missing-profile-data'
          : 'invalid-service',
      400,
    );
  }
  return value;
}

String? normalizeDirectoryPhone(String value) {
  if (!RegExp(r'^\s*(?:\+|00)?[0-9 ()\.\-]+\s*$').hasMatch(value)) return null;
  final trimmed = value.trim();
  var digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (trimmed.startsWith('00')) {
    digits = digits.substring(2);
  } else if (!trimmed.startsWith('+') &&
      digits.length == 10 &&
      digits.startsWith('0')) {
    digits = '212${digits.substring(1)}';
  }
  return RegExp(r'^[1-9][0-9]{7,14}$').hasMatch(digits) ? '+$digits' : null;
}

Set<String> _phoneAliases(String phone) {
  final digits = phone.substring(1);
  return {
    phone,
    '00$digits',
    digits,
    if (digits.startsWith('212') && digits.length == 12) ...{
      '0${digits.substring(3)}',
      for (final separator in [' ', '-', '.']) ...{
        _groupPhone('0${digits.substring(3)}', separator),
        '+212$separator${_groupPhone(digits.substring(3), separator, first: 1)}',
      },
    },
  };
}

String _groupPhone(String digits, String separator, {int first = 2}) => [
  digits.substring(0, first),
  for (var i = first; i < digits.length; i += 2) digits.substring(i, i + 2),
].join(separator);
