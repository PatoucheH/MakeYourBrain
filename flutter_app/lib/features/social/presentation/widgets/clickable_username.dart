import 'package:flutter/material.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import 'user_profile_bottom_sheet.dart';

class ClickableUsername extends StatelessWidget {
  final String userId;
  final String displayName;
  final TextStyle? style;
  final TextOverflow? overflow;

  const ClickableUsername({
    super.key,
    required this.userId,
    required this.displayName,
    this.style,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final currentUserId = AuthRepository().getCurrentUserId();
        UserProfileBottomSheet.show(context, userId, currentUserId);
      },
      child: Text(
        displayName,
        style: (style ?? const TextStyle()).copyWith(
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
        ),
        overflow: overflow ?? TextOverflow.ellipsis,
      ),
    );
  }
}
