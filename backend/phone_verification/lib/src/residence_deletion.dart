import 'dart:convert';

import 'package:http/http.dart' as http;

typedef _Json = Map<String, dynamic>;

class ResidenceDeletionFailure implements Exception {
  const ResidenceDeletionFailure(this.code, this.status);

  final String code;
  final int status;
}

class ResidenceDeletion {
  ResidenceDeletion({
    required String projectId,
    required this.client,
    required this.storageBucket,
    Uri? firestoreOrigin,
    Uri? storageOrigin,
  }) : _firestore = firestoreOrigin ?? Uri.https('firestore.googleapis.com'),
       _storage = storageOrigin ?? Uri.https('storage.googleapis.com'),
       _documents = 'projects/$projectId/databases/(default)/documents';

  final http.Client client;
  final String storageBucket;
  final Uri _firestore;
  final Uri _storage;
  final String _documents;

  Future<void> delete(String residenceId, String userId) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(residenceId)) {
      throw const ResidenceDeletionFailure('invalid-request', 400);
    }
    final residence = '$_documents/residences/$residenceId';
    final creator = '$residence/members/$userId';
    final settings = '$residence/settings/private';
    final user = '$_documents/users/$userId';
    final started = await _transaction((transaction) async {
      final document = await _read(residence, transaction);
      if (document == null) return (false, const <_Json>[]);
      final startedBy = _field(document, 'deletionStartedBy');
      if (startedBy == userId) return (true, const <_Json>[]);

      final createdBy =
          _field(document, 'createdBy') ??
          _field(await _read(settings, transaction), 'createdBy');
      if (createdBy != userId ||
          startedBy != null ||
          _field(await _read(creator, transaction), 'status') != 'active') {
        throw const ResidenceDeletionFailure('residence-delete-forbidden', 403);
      }

      // Memberships survive departure, removal, and account deletion requests.
      final members = await _query(
        residence,
        'members',
        transaction: transaction,
        limit: 2,
      );
      if (members.any((member) => member['name'] != creator)) {
        throw const ResidenceDeletionFailure(
          'residence-has-joined-residents',
          409,
        );
      }
      return (
        true,
        [
          _updateFields(residence, {
            'deletionStartedBy': {'stringValue': userId},
          }),
        ],
      );
    });
    if (!started) return;

    await _deleteStorage('residences/$residenceId/');
    await _deleteTree(residence, keep: {creator, settings});
    for (final collection in [
      'residenceCodes',
      'publicPaymentReceipts',
      'directoryRecommendations',
      'appActivityLog',
    ]) {
      await _clearMatches(_documents, collection, 'residenceId', residenceId);
    }
    await _clearMatches(user, 'notifications', 'residenceId', residenceId);
    await _clearMatches(
      user,
      'pushTokens',
      'residenceIds',
      residenceId,
      array: true,
      write: (name) => {
        'transform': {
          'document': name,
          'fieldTransforms': [
            {
              'fieldPath': 'residenceIds',
              'removeAllFromArray': {
                'values': [
                  {'stringValue': residenceId},
                ],
              },
            },
          ],
        },
        'currentDocument': {'exists': true},
      },
    );
    await _clearMatches(
      _documents,
      'services',
      'createdFromResidenceId',
      residenceId,
      write: (name) => _updateFields(
        name,
        {},
        remove: ['createdFromResidenceId', 'createdFromResidenceName'],
        mustExist: true,
      ),
    );

    // Preserve the creator membership until the final commit so a failed
    // cleanup can be retried from the same page.
    await _transaction((transaction) async {
      final document = await _read(residence, transaction);
      if (_field(document, 'deletionStartedBy') != userId) {
        return (false, const <_Json>[]);
      }
      final profile = await _read(user, transaction);
      return (
        true,
        [
          if (_field(profile, 'activeResidenceId') == residenceId)
            _updateFields(user, {}, remove: ['activeResidenceId']),
          {'delete': '$_documents/publicResidences/$residenceId'},
          {'delete': settings},
          {'delete': creator},
          {'delete': residence},
        ],
      );
    });
  }

  Future<void> _deleteTree(String document, {required Set<String> keep}) async {
    String? collectionToken;
    do {
      final page =
          await _post('$document:listCollectionIds', {
                'pageSize': 100,
                'pageToken': ?collectionToken,
              })
              as _Json;
      for (final id in page['collectionIds'] as List? ?? const []) {
        String? documentToken;
        do {
          final descendants = await _list('$document/$id', {
            'showMissing': 'true',
            'pageSize': '100',
            'mask.fieldPaths': '__name__',
            'pageToken': ?documentToken,
          });
          final writes = <_Json>[];
          for (final child in descendants['documents'] as List? ?? const []) {
            final name = child['name'] as String;
            await _deleteTree(name, keep: keep);
            if (!keep.contains(name) && child['updateTime'] != null) {
              writes.add({'delete': name});
            }
          }
          if (writes.isNotEmpty) await _commit(writes);
          documentToken = descendants['nextPageToken'] as String?;
        } while (documentToken != null && documentToken.isNotEmpty);
      }
      collectionToken = page['nextPageToken'] as String?;
    } while (collectionToken != null && collectionToken.isNotEmpty);
  }

  Future<void> _clearMatches(
    String parent,
    String collection,
    String field,
    String residenceId, {
    bool array = false,
    _Json Function(String)? write,
  }) async {
    while (true) {
      final documents = await _query(
        parent,
        collection,
        field: field,
        value: residenceId,
        array: array,
      );
      if (documents.isEmpty) return;
      await _commit([
        for (final document in documents)
          write?.call(document['name'] as String) ??
              {'delete': document['name']},
      ]);
    }
  }

  Future<void> _deleteStorage(String prefix) async {
    String? pageToken;
    do {
      final uri = _storage.replace(
        pathSegments: ['', 'storage', 'v1', 'b', storageBucket, 'o'],
        queryParameters: {
          'prefix': prefix,
          'versions': 'true',
          'fields': 'items(name,generation),nextPageToken',
          'pageToken': ?pageToken,
        },
      );
      final page = _decode(await client.get(uri)) as _Json;
      for (final object in page['items'] as List? ?? const []) {
        final response = await client.delete(
          uri.replace(
            pathSegments: [...uri.pathSegments, object['name'] as String],
            queryParameters: {'generation': object['generation'] as String},
          ),
        );
        if (response.statusCode != 404) _check(response);
      }
      pageToken = page['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);
  }

  Future<T> _transaction<T>(
    Future<(T, List<_Json>)> Function(String) run,
  ) async {
    for (var attempt = 0; ; attempt++) {
      final begin = await _post('$_documents:beginTransaction', {}) as _Json;
      final transaction = begin['transaction'] as String;
      try {
        final (value, writes) = await run(transaction);
        await _commit(writes, transaction: transaction);
        return value;
      } catch (error) {
        await _post('$_documents:rollback', {
          'transaction': transaction,
        }).catchError((_) => null);
        if (error is! _CloudFailure || error.status != 409 || attempt == 4) {
          rethrow;
        }
      }
    }
  }

  Future<void> _commit(List<_Json> writes, {String? transaction}) async {
    await _post('$_documents:commit', {
      'writes': writes,
      'transaction': ?transaction,
    });
  }

  Future<List<_Json>> _query(
    String parent,
    String collection, {
    String? field,
    String? value,
    String? transaction,
    bool array = false,
    int limit = 100,
  }) async {
    final response =
        await _post('$parent:runQuery', {
              'structuredQuery': {
                'from': [
                  {'collectionId': collection},
                ],
                'select': {
                  'fields': [
                    {'fieldPath': '__name__'},
                  ],
                },
                if (field != null)
                  'where': {
                    'fieldFilter': {
                      'field': {'fieldPath': field},
                      'op': array ? 'ARRAY_CONTAINS' : 'EQUAL',
                      'value': {'stringValue': value},
                    },
                  },
                'limit': limit,
              },
              'transaction': ?transaction,
            })
            as List;
    return [
      for (final row in response)
        if (row['document'] case final _Json document) document,
    ];
  }

  Future<_Json?> _read(String name, String transaction) async {
    final results =
        await _post('$_documents:batchGet', {
              'documents': [name],
              'transaction': transaction,
            })
            as List;
    return (results.single as _Json)['found'] as _Json?;
  }

  Future<_Json> _list(String name, Map<String, String> query) async =>
      _decode(
            await client.get(
              _firestore.replace(path: '/v1/$name', queryParameters: query),
            ),
          )
          as _Json;

  Future<Object?> _post(String path, _Json body) async => _decode(
    await client.post(
      _firestore.replace(path: '/v1/$path'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
    ),
  );

  static Object? _decode(http.Response response) {
    _check(response);
    return jsonDecode(response.body);
  }

  static void _check(http.Response response) {
    if (response.statusCode >= 300) {
      throw _CloudFailure(response.statusCode, response.body);
    }
  }
}

String? _field(_Json? document, String field) =>
    document?['fields']?[field]?['stringValue'] as String?;

_Json _updateFields(
  String name,
  _Json fields, {
  List<String> remove = const [],
  bool mustExist = false,
}) => {
  'update': {'name': name, 'fields': fields},
  'updateMask': {
    'fieldPaths': [...fields.keys, ...remove],
  },
  if (mustExist) 'currentDocument': {'exists': true},
};

class _CloudFailure implements Exception {
  const _CloudFailure(this.status, this.body);

  final int status;
  final String body;

  @override
  String toString() => 'Cloud API error ($status): $body';
}
