import 'package:flutter/material.dart';

/// Every action uses the same 20px icon inside a 24px slot.
/// Only the built-in glyph's bottom padding is compensated, so the visible
/// strokes sit on one bottom line (20px from the top of the slot).
class CommunityPostActionIcon extends StatelessWidget {
  const CommunityPostActionIcon(this.icon, {super.key});

  static const iconSize = 20.0;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bottomOffset = switch (icon) {
      Icons.thumb_up_outlined ||
      Icons.thumb_up_rounded ||
      Icons.bookmark_border_rounded ||
      Icons.bookmark_rounded => 0.5,
      Icons.chat_bubble_outline_rounded => 0.75,
      Icons.ios_share_rounded => -1.25,
      _ => 0.0,
    };
    return SizedBox.square(
      dimension: 24,
      child: Center(
        child: Transform.translate(
          offset: Offset(0, bottomOffset),
          child: Icon(icon, size: iconSize),
        ),
      ),
    );
  }
}
