import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

const _datastoreScope = 'https://www.googleapis.com/auth/datastore';

Future<void> main(List<String> arguments) async {
  final projectId = arguments.isNotEmpty
      ? arguments.first
      : Platform.environment['GOOGLE_CLOUD_PROJECT'];
  if (projectId == null || projectId.trim().isEmpty) {
    stderr.writeln(
      'Usage: dart run bin/seed_service_categories.dart <project-id>',
    );
    exitCode = 64;
    return;
  }

  final source = File('service_categories.json');
  if (!source.existsSync()) {
    stderr.writeln('service_categories.json was not found.');
    exitCode = 66;
    return;
  }
  final categories = jsonDecode(await source.readAsString()) as List<Object?>;
  final client = await clientViaApplicationDefaultCredentials(
    scopes: const [_datastoreScope],
  );
  try {
    for (final raw in categories) {
      final category = raw! as Map<String, Object?>;
      final id = category['id']! as String;
      final fields = Map<String, Object?>.from(category)..remove('id');
      final uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/'
        'databases/(default)/documents/serviceCategories/$id',
      );
      final response = await client.patch(
        uri,
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'fields': {
            for (final entry in fields.entries)
              entry.key: _firestoreValue(entry.value),
          },
        }),
      );
      _expectSuccess(response, id);
      stdout.writeln('Seeded serviceCategories/$id');
    }
  } finally {
    client.close();
  }
}

Map<String, Object?> _firestoreValue(Object? value) {
  return switch (value) {
    String value => {'stringValue': value},
    int value => {'integerValue': value.toString()},
    bool value => {'booleanValue': value},
    List<Object?> value => {
      'arrayValue': {
        'values': [for (final item in value) _firestoreValue(item)],
      },
    },
    Map<String, Object?> value => {
      'mapValue': {
        'fields': {
          for (final entry in value.entries)
            entry.key: _firestoreValue(entry.value),
        },
      },
    },
    null => {'nullValue': null},
    _ => throw FormatException('Unsupported catalog value: $value'),
  };
}

void _expectSuccess(http.Response response, String categoryId) {
  if (response.statusCode >= 200 && response.statusCode < 300) return;
  throw StateError(
    'Could not seed $categoryId (${response.statusCode}): ${response.body}',
  );
}
