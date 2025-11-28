import 'package:flutter/material.dart';
import 'package:swustmeow/utils/courses.dart';

import '../../data/m_theme.dart';
import '../../data/values.dart';
import '../../services/global_service.dart';
import '../../utils/time.dart';

class HeaderRow extends StatefulWidget {
  const HeaderRow({super.key, required this.term, required this.weekNum});

  final String term;
  final int weekNum;

  @override
  State<StatefulWidget> createState() => _HeaderRowState();
}

class _HeaderRowState extends State<HeaderRow> {
  static const days = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final (i, _) = getWeekNum(widget.term, now);
    final (start, _, _) = GlobalService.termDates.value[widget.term]?.value ??
        Values.getFallbackTermDates(widget.term);
    final time = start.add(Duration(days: 7 * (widget.weekNum - 1)));
    final hasBg = MTheme.courseTableImagePath != null;

    getTextStyle(DateTime t) {
      final isToday = i && now.monthDayEquals(t);
      return TextStyle(
        fontSize: 10,
        color: hasBg
            ? isToday
                ? MTheme.courseTableText
                : MTheme.courseTableUseWhiteFont
                    ? Colors.white
                    : Colors.black
            : isToday
                ? MTheme.primary2
                : Colors.black,
        fontFeatures: [FontFeature.tabularFigures()],
      );
    }

    return Row(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 0, 0),
          child: Text(
            '${widget.weekNum.padL2}周',
            style: TextStyle(
              color:
                  MTheme.courseTableUseWhiteFont ? Colors.white : Colors.black,
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        ...List.generate(days.length, (index) {
          final t = time.add(Duration(days: index));
          return Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(days[index], style: getTextStyle(t)),
                  Text(
                    '${t.month.padL2}/${t.day.padL2}',
                    style: getTextStyle(t),
                  )
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
