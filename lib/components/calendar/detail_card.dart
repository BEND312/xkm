import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/entity/calendar_event.dart';
import 'package:swustmeow/services/value_service.dart';
import 'package:swustmeow/utils/courses.dart';
import 'package:swustmeow/utils/widget.dart';

import '../../data/m_theme.dart';
import '../../entity/activity.dart';
import '../../entity/activity_type.dart';
import '../../utils/time.dart';

class DetailCard extends StatefulWidget {
  const DetailCard({
    super.key,
    required this.selectedDate,
    required this.activities,
    required this.systemEvents,
  });

  final DateTime selectedDate;
  final List<Activity> activities;
  final List<CalendarEvent>? systemEvents;

  @override
  State<StatefulWidget> createState() => _DetailCardState();
}

class _DetailCardState extends State<DetailCard> with TickerProviderStateMixin {
  String? _getWeekInfo() {
    const weeks = ['一', '二', '三', '四', '五', '六', '日'];
    final s = '周${weeks[widget.selectedDate.weekday - 1]}';
    final terms = ValueService.coursesContainers.map((c) => c.term).toList();
    if (terms.isEmpty) return s;

    List<int> result = [];
    for (final term in terms) {
      final (i, w) = getWeekNum(term, widget.selectedDate);
      if (i) result.add(w);
    }

    if (result.isEmpty) return s;
    return '教学第${result.first.padL2}周 - $s';
  }

  Widget _buildEventColumn(CalendarEvent event) {
    final color = Colors.black;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MTheme.primary2.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.allDay ? '全天' : '时段',
                    style: TextStyle(
                      fontSize: 12,
                      color: MTheme.primary2,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBadge(
                  FontAwesomeIcons.clock,
                  event.start!.dateStringWithHM,
                  color.withValues(alpha: 0.6),
                ),
                if (!event.allDay)
                  _buildBadge(
                    FontAwesomeIcons.arrowRight,
                    event.end!.dateStringWithHM,
                    color.withValues(alpha: 0.6),
                  ),
              ],
            ),
            if (event.description?.isNotEmpty == true) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 12,
            color: color,
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activities.firstOrNull;
    final isActivity = activity != null && widget.activities.isNotEmpty;
    final displayActivities = widget.activities.where((ac) => ac.name != null);
    final weekInfo = _getWeekInfo();
    final fg = context.theme.colorScheme.foreground;

    Color getColor(Activity ac) =>
        ac.isFestival && !ac.holiday ? fg : ActivityTypeData.of(ac.type).color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        key: Key(
          DateTime.now().millisecondsSinceEpoch.toString(),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8),
        shrinkWrap: true,
        children: joinGap(
          gap: 8.0,
          axis: Axis.vertical,
          widgets: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.selectedDate.year}年${widget.selectedDate.month.padL2}月${widget.selectedDate.day.padL2}日',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                  if (weekInfo != null)
                    Text(
                      weekInfo,
                      style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                ],
              ),
            ),
            if (isActivity && displayActivities.isNotEmpty)
              ...displayActivities.map(
                (ac) => Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: getColor(ac).withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ac.name ?? '未知事件',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: getColor(ac),
                              ),
                            ),
                          ),
                          if (ac.type != ActivityType.today)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: getColor(ac).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                ac.isFestival ? '节日' : '活动',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: getColor(ac),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (ac.holiday) ...[
                        SizedBox(height: 8),
                        _buildBadge(
                          FontAwesomeIcons.calendar,
                          '假期',
                          getColor(ac),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ...(widget.systemEvents ?? [])
                .map((event) => _buildEventColumn(event)),
            SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}
