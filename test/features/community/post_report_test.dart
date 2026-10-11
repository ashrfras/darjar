import 'package:darjar/features/community/data/community_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports stay scoped to residence, post, and reporter', () async {
    final repository = MockCommunityRepository();
    const postId = 'poll-garden';

    await repository.reportPost(
      residenceId: 'residence-a',
      userId: 'resident-a',
      postId: postId,
      reason: CommunityReportReason.spam,
    );
    await repository.reportPost(
      residenceId: 'residence-a',
      userId: 'resident-a',
      postId: postId,
      reason: CommunityReportReason.privacy,
    );
    await repository.reportPost(
      residenceId: 'residence-a',
      userId: 'resident-b',
      postId: postId,
      reason: CommunityReportReason.harassment,
    );

    expect(repository.reports, {
      'residence-a/$postId/resident-a': CommunityReportReason.privacy,
      'residence-a/$postId/resident-b': CommunityReportReason.harassment,
    });
    await expectLater(
      repository.reportPost(
        residenceId: 'residence-a',
        userId: 'resident-a',
        postId: 'missing-post',
        reason: CommunityReportReason.other,
      ),
      throwsA(isA<CommunityFailure>()),
    );
    repository.dispose();
  });
}
