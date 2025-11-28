import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:swustmeow/components/utils/empty.dart';

import '../../entity/soa/course/course_entry.dart';
import '../../services/boxes/course_box.dart';

class CourseCard extends StatefulWidget {
  const CourseCard({
    super.key,
    required this.entry,
    required this.active,
    required this.isMore,
    required this.isConflict,
  });

  final CourseEntry? entry;
  final bool active;

  /// 当前课程表位置是否有更多课程
  final bool isMore;

  /// 当前课程表位置是否重课（排课冲突）
  final bool isConflict;

  @override
  State<StatefulWidget> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  late bool _showSubCourseName;
  late bool _showRedBorderForConflict;
  late bool _showStarForMultiCandidates;
  late double _cardOpacity;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _showSubCourseName = CourseBox.get('showSubCourseName') as bool? ?? false;
    _showRedBorderForConflict =
        CourseBox.get('showRedBorderForConflict') as bool? ?? true;
    _showStarForMultiCandidates =
        CourseBox.get('showStarForMultiCandidates') as bool? ?? false;

    _cardOpacity = CourseBox.get('cardOpacity') as double? ?? 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entry == null || !widget.active) return Empty();
    _loadSettings();

    return _buildCardContent();
  }

  Widget _buildCardContent() {
    final color = widget.entry!.getColor();
    final textColor =
        color.computeLuminance() > 0.7 ? Colors.black : Colors.white;

    final bgColor = widget.active ? color : Colors.grey.withValues(alpha: 0.4);
    final primaryColor = textColor.withValues(alpha: widget.active ? 1 : 0.8);
    final secondaryColor =
        textColor.withValues(alpha: widget.active ? 0.8 : 0.6);

    final courseName = _showSubCourseName
        ? widget.entry!.displayName
        : widget.entry!.courseName;
    final name = courseName;
    final conflictBorderWidth = 1.5;
    final supportSection =
        widget.entry?.startSection != null && widget.entry?.endSection != null;
    final sections = supportSection
        ? widget.entry!.endSection! - widget.entry!.startSection! + 1
        : 2;
    final shouldOverflow = sections <= 2;

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.all(Radius.circular(6 + conflictBorderWidth)),
        border: widget.isConflict && _showRedBorderForConflict
            ? Border.all(
                color: Colors.red,
                width: conflictBorderWidth,
              )
            : null,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: _cardOpacity),
                borderRadius: const BorderRadius.all(Radius.circular(6)),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  (widget.isMore && _showStarForMultiCandidates ? '*' : '') +
                      name,
                  style: TextStyle(
                    color: primaryColor,
                    height: 0,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                    wordSpacing: 0,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: shouldOverflow ? 4 : 10,
                  minFontSize: 10,
                ),
                AutoSizeText(
                  '@${widget.entry!.place}',
                  style: TextStyle(
                      color: secondaryColor,
                      height: 0,
                      fontSize: 10,
                      letterSpacing: 0,
                      wordSpacing: 0),
                  overflow: TextOverflow.ellipsis,
                  maxLines: shouldOverflow ? 4 : 10,
                  minFontSize: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
