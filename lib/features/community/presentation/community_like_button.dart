import 'dart:math' as math;

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/presentation/community_post_action_icon.dart';
import 'package:flutter/material.dart';

/// Shared optimistic interaction for posts and residence updates.
class CommunityLikeButton extends StatefulWidget {
  const CommunityLikeButton({
    required this.isLiked,
    required this.likes,
    required this.onLike,
    this.compact = false,
    this.likedColor = AppColors.danger,
    super.key,
  });

  final bool isLiked;
  final int likes;
  final Future<void> Function() onLike;
  final bool compact;
  final Color likedColor;

  @override
  State<CommunityLikeButton> createState() => _CommunityLikeButtonState();
}

class _CommunityLikeButtonState extends State<CommunityLikeButton>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 1, end: .8), weight: 15),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: .8,
        end: 1.45,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.45,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 50,
    ),
  ]).animate(_animation);
  bool _requestInFlight = false;
  bool? _pendingLiked;

  bool get _isLiked => _pendingLiked ?? widget.isLiked;
  int get _likes => math.max(
    0,
    widget.likes + (_isLiked == widget.isLiked ? 0 : (_isLiked ? 1 : -1)),
  );

  @override
  void didUpdateWidget(covariant CommunityLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_requestInFlight && widget.isLiked == _pendingLiked) {
      _pendingLiked = null;
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    // Keep the optimistic result until both the write and its stream update
    // arrive. Repeated taps cannot start competing toggle requests.
    if (_requestInFlight || _pendingLiked != null) return;
    final previousLiked = widget.isLiked;
    final nextLiked = !previousLiked;
    setState(() {
      _requestInFlight = true;
      _pendingLiked = nextLiked;
    });
    if (nextLiked && !MediaQuery.disableAnimationsOf(context)) {
      _animation.forward(from: 0);
    } else {
      _animation.reset();
    }
    var succeeded = false;
    try {
      await widget.onLike();
      succeeded = true;
    } on CommunityFailure {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).communityActionFailed),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _requestInFlight = false;
          if (!succeeded) {
            _pendingLiked = previousLiked;
            _animation.reset();
          }
          if (widget.isLiked == _pendingLiked) _pendingLiked = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _isLiked ? widget.likedColor : AppColors.inkMuted;
    final icon = _isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      selected: _isLiked,
      label: AppLocalizations.of(context).communityLike,
      child: TextButton.icon(
        onPressed: _toggle,
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: widget.compact ? const Size(0, 40) : const Size(64, 48),
          padding: widget.compact
              ? const EdgeInsets.symmetric(horizontal: 7, vertical: 7)
              : null,
          visualDensity: VisualDensity.standard,
          textStyle: widget.compact
              ? Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)
              : null,
        ),
        icon: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final progress = reduceMotion ? 0.0 : _animation.value;
            return CustomPaint(
              foregroundPainter: _LikeBurstPainter(progress, widget.likedColor),
              child: Transform.rotate(
                angle: -math.sin(progress * math.pi) * .2,
                child: Transform.scale(
                  key: const Key('community-like-scale'),
                  scale: reduceMotion ? 1 : _scale.value,
                  child: child,
                ),
              ),
            );
          },
          child: widget.compact
              ? SizedBox.square(dimension: 24, child: Icon(icon, size: 17))
              : CommunityPostActionIcon(icon),
        ),
        label: Text('$_likes'),
      ),
    );
  }
}

class _LikeBurstPainter extends CustomPainter {
  const _LikeBurstPainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = size.center(Offset.zero);
    final fade = math.sin(progress * math.pi);
    final paint = Paint()..color = color.withValues(alpha: fade * .65);
    canvas.drawCircle(
      center,
      9 + progress * 19,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * (1 - progress),
    );
    paint.style = PaintingStyle.fill;
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final radius = 13 + Curves.easeOut.transform(progress) * 18;
      final offset = Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(center + offset, 2.8 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LikeBurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
