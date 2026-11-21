import 'dart:convert';

import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

const _functionUrl = String.fromEnvironment(
  'DARJAR_ACTIVITY_LOG_URL',
  defaultValue: 'https://appactivitylog-1080325854470.europe-west1.run.app',
);

enum ActivityType {
  accountCreated,
  residenceCreated,
  residentJoined,
  firstPostPublished,
  accountDeletionRequested,
  accountDeleted,
  residenceDeleted,
  unknown,
}

class ActivityEvent {
  ActivityEvent.fromJson(Map<String, Object?> json)
    : id = json['id'] as String,
      type = ActivityType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => ActivityType.unknown,
      ),
      occurredAt = DateTime.parse(json['occurredAt'] as String),
      residentName = json['residentName'] as String?,
      phoneNumber = json['phoneNumber'] as String?,
      residenceId = json['residenceId'] as String?,
      residenceName = json['residenceName'] as String?;

  final String id;
  final ActivityType type;
  final DateTime occurredAt;
  final String? residentName;
  final String? phoneNumber;
  final String? residenceId;
  final String? residenceName;
}

class ActivityPage {
  const ActivityPage(this.events, this.nextCursor);

  final List<ActivityEvent> events;
  final String? nextCursor;
}

class ActivityAccessDenied implements Exception {
  const ActivityAccessDenied();
}

class ActivityLogRepository {
  ActivityLogRepository(this._auth, this._client, this._endpoint);

  final FirebaseAuth _auth;
  final http.Client _client;
  final Uri _endpoint;

  Future<bool> hasDeveloperAccess(String uid) async {
    try {
      final response = await _get(uid, {'access': 'true'});
      return response['developer'] == true;
    } on ActivityAccessDenied {
      return false;
    }
  }

  Future<ActivityPage> fetchPage(String uid, {String? cursor}) async {
    final response = await _get(uid, {'cursor': ?cursor});
    return ActivityPage([
      for (final event in response['events'] as List)
        ActivityEvent.fromJson(event as Map<String, Object?>),
    ], response['nextCursor'] as String?);
  }

  Future<Map<String, Object?>> _get(
    String uid,
    Map<String, String> parameters,
  ) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != uid) throw const ActivityAccessDenied();
    final token = await user.getIdToken();
    if (token == null || _auth.currentUser?.uid != uid) {
      throw const ActivityAccessDenied();
    }

    final response = await _client
        .get(
          _endpoint.replace(queryParameters: parameters),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 401 ||
        response.statusCode == 403 ||
        _auth.currentUser?.uid != uid) {
      throw const ActivityAccessDenied();
    }
    if (response.statusCode != 200) {
      throw StateError('Activity log request failed (${response.statusCode}).');
    }
    return jsonDecode(response.body) as Map<String, Object?>;
  }
}

final activityLogRepositoryProvider =
    Provider.autoDispose<ActivityLogRepository>((ref) {
      final client = http.Client();
      ref.onDispose(client.close);
      return ActivityLogRepository(
        ref.watch(firebaseAuthProvider),
        client,
        Uri.parse(_functionUrl),
      );
    });

final activityLogUserIdProvider = Provider.autoDispose<String?>((ref) {
  if (ref.watch(localhostAuthSimulationProvider)) return null;
  final currentUser = ref.watch(authRepositoryProvider).currentUser;
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user?.uid,
    loading: () => currentUser?.uid,
    error: (_, _) => null,
  );
});

final developerAccessProvider = FutureProvider.autoDispose<bool>((ref) {
  final uid = ref.watch(activityLogUserIdProvider);
  if (uid == null || Firebase.apps.isEmpty) return false;
  return ref.watch(activityLogRepositoryProvider).hasDeveloperAccess(uid);
});
