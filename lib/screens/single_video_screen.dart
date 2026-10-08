import 'package:flutter/material.dart';

import '../models/video_source.dart';
import '../widgets/video_page.dart';
import 'assign_sheet.dart';
import 'comments_sheet.dart';

/// A pushed full-screen player for a single video (used by search results and
/// the inbox). [isActive] is always true because only this page is shown.
class SingleVideoScreen extends StatelessWidget {
  const SingleVideoScreen({
    super.key,
    required this.source,
    this.ownerName,
    this.showAssign = false,
  });

  final VideoSource source;
  final String? ownerName;
  final bool showAssign;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          VideoPage(
            source: source,
            isActive: true,
            ownerName: ownerName,
            showAssign: showAssign,
            onOpenComments: () => showCommentsSheet(context, source.id),
            onAssign: showAssign ? () => showAssignSheet(context, source.id) : null,
          ),
          Positioned(
            top: 40,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
