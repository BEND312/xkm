import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/course_table/course_card.dart';
import 'package:swustmeow/components/course_table/course_detail_card.dart';
import 'package:swustmeow/components/course_table/header_row.dart';
import 'package:swustmeow/components/course_table/time_column.dart';
import 'package:swustmeow/components/utils/empty.dart';
import 'package:swustmeow/services/boxes/course_box.dart';

import '../../data/values.dart';
import '../../entity/soa/course/course_entry.dart';
import '../../entity/soa/course/courses_container.dart';
import '../../services/global_service.dart';
import '../../utils/courses.dart';

class CourseTable extends StatefulWidget {
  const CourseTable({
    super.key,
    required this.container,
    required this.isLoading,
    this.pageWidth,
    this.pageHeight,
    this.timeColumnWidth,
  });

  final CoursesContainer container;
  final bool isLoading;
  final double? pageWidth;
  final double? pageHeight;
  final double? timeColumnWidth;

  @override
  State<StatefulWidget> createState() => _CourseTableState();
}

class _CourseTableState extends State<CourseTable> {
  String? _term;
  int? _all;
  final _pageKey = GlobalKey();
  bool _shouldCheckSize = true;
  double? _pageWidth;
  double? _pageHeight;
  GlobalKey? _timeColumnKey;
  double? _timeColumnWidth;
  Map<String, CourseEntry> _displayEntries = {};

  late final PageController pageController;
  late final int initialPage;

  @override
  void initState() {
    super.initState();
    if (widget.pageWidth != null &&
        widget.pageHeight != null &&
        widget.timeColumnWidth != null) {
      _shouldCheckSize = false;
      _pageWidth = widget.pageWidth;
      _pageHeight = widget.pageHeight;
      _timeColumnWidth = widget.timeColumnWidth;
    }

    var (_, w) = getWeekNum(widget.container.term, DateTime.now());
    w = w > 0 ? w : 1;
    final (_, _, all) =
        GlobalService.termDates.value[widget.container.term]?.value ??
            Values.getFallbackTermDates(widget.container.term);
    initialPage = (w > all ? all : w) - 1;
    pageController = PageController(initialPage: initialPage, keepPage: true);

    _displayEntries =
        (CourseBox.get('displayEntries') as Map<dynamic, dynamic>?)?.cast() ??
            {};
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> _handleSelectDisplay(String key, CourseEntry entry) async {
    _displayEntries[key] = entry;
    await CourseBox.put('displayEntries', _displayEntries);
    setState(() {});
  }

  Widget _buildTimeColumn(int pageIndex) {
    return Column(
      key: pageIndex == initialPage ? _timeColumnKey : null,
      children: List.generate(
        6,
        (index) => Expanded(
          child: TimeColumn(
            number: index + 1,
            time: Values.courseTableTimes[index],
          ),
        ),
      ),
    );
  }

  Widget _buildColumn(int columnIndex, int pageIndex) {
    final w = pageIndex + 1;
    List<(int, int)> occupiedSections = [];

    return Stack(
      children: [
        ...List.generate(
          6,
          (indexOfDay) {
            final matched = widget.container.entries
                .where((entry) =>
                    entry.numberOfDay == indexOfDay + 1 &&
                    entry.weekday == columnIndex + 1)
                .toList()
              ..sort((a, b) => a.endWeek.compareTo(b.endWeek));
            final actives = matched
                .where((e) => w >= e.startWeek && w <= e.endWeek)
                .toList();

            final isConflict = actives.length > 1;
            final conflictKey = getConflictKey(columnIndex + 1, indexOfDay + 1);
            var conflictDisplay = _displayEntries[conflictKey];
            if (isConflict &&
                (conflictDisplay == null ||
                    !matched.contains(conflictDisplay))) {
              final shouldConflictDisplay = matched
                      .where((c) => c.courseName == conflictDisplay?.courseName)
                      .firstOrNull ??
                  actives.first;
              _displayEntries[conflictKey] = shouldConflictDisplay;
              conflictDisplay = shouldConflictDisplay;
              CourseBox.put('displayEntries', _displayEntries);
            }

            final display = actives.length > 1
                ? (conflictDisplay ?? actives.first)
                : actives.lastOrNull;

            if (display == null || _pageHeight == null || _pageWidth == null) {
              return const Empty();
            }

            final nod = display.numberOfDay;
            final startSection = display.startSection;
            final endSection = display.endSection;
            final supportSection = startSection != null && endSection != null;

            if (occupiedSections.reversed.any((pair) {
              final (s, e) = pair;
              return supportSection
                  ? startSection >= s && endSection <= e
                  : (2 * nod) - 1 >= s && 2 * nod <= e;
            })) {
              return const Empty();
            }

            final diff = supportSection ? (endSection - startSection + 1) : 0;
            final perHeight = (_pageHeight! - (6 - 1) * 1) / 6;
            final perWidth =
                (_pageWidth! - _timeColumnWidth! - (6 - 1) * 1) / 6;
            final perSection = perHeight / 2;
            final height = supportSection ? diff * perSection : perHeight;
            final dy = supportSection
                ? (startSection - 1) * perSection
                : (nod - 1) * perSection;

            occupiedSections.add(supportSection
                ? (startSection, endSection)
                : ((2 * nod) - 1, 2 * nod));

            return Transform.translate(
              offset: Offset(0, dy),
              child: SizedBox(
                height: height,
                width: perWidth,
                child: FTappable(
                  onPress: () {
                    if (actives.isEmpty) return;
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CourseDetailCard(
                        entries: matched,
                        term: _term!,
                        clicked: display,
                        isConflict: isConflict,
                        displayEntry: display,
                        onSelectDisplay: (display) => _handleSelectDisplay(
                          getConflictKey(columnIndex + 1, indexOfDay + 1),
                          display,
                        ),
                        onRefresh: () => setState(() {}),
                      ),
                    );
                  },
                  child: CourseCard(
                    entry: display,
                    active: actives.isNotEmpty,
                    isMore: matched.length > 1,
                    isConflict: isConflict,
                  ),
                ),
              ),
            );
          },
        ),
        Column(children: List.generate(6, (_) => const Empty())),
      ],
    );
  }

  Widget _buildPage(int pageIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_shouldCheckSize) return;

      final c = _pageKey.currentContext?.findRenderObject() as RenderBox?;
      final l =
          _timeColumnKey?.currentContext?.findRenderObject() as RenderBox?;
      final pageWidth = c?.size.width;
      final pageHeight = c?.size.height;
      final timeColumnWidth = l?.size.width;

      if (_pageWidth != pageWidth && pageWidth != null) {
        setState(() => _pageWidth = pageWidth);
      }

      if (_pageHeight != pageHeight && pageHeight != null) {
        setState(() => _pageHeight = pageHeight);
      }

      if (_timeColumnWidth != timeColumnWidth && timeColumnWidth != null) {
        setState(() => _timeColumnWidth = timeColumnWidth);
      }
    });

    return Padding(
      padding: EdgeInsets.only(right: 1),
      child: Row(
        key: _pageHeight == null && pageIndex == initialPage ? _pageKey : null,
        children: [
          _buildTimeColumn(pageIndex),
          ...List.generate(
            7,
            (index) => Expanded(
              child: _buildColumn(index, pageIndex),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _term = widget.container.term;
    final (_, _, all) = GlobalService.termDates.value[_term!]?.value ??
        Values.getFallbackTermDates(_term!);
    _all = all;
    _timeColumnKey = GlobalKey();

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          ListenableBuilder(
              listenable: pageController,
              builder: (context, _) {
                var page = pageController.positions.isEmpty ||
                        pageController.page == null
                    ? initialPage
                    : pageController.page ?? initialPage;
                page = page > 0 ? page : 0;
                final result = (page - page.toInt()).abs() >= 0.5
                    ? page.ceil()
                    : page.floor();
                return HeaderRow(term: _term!, weekNum: result + 1);
              }),
          Expanded(
            flex: 1,
            child: PageView.builder(
              controller: pageController,
              itemCount: _all,
              itemBuilder: (context, pageIndex) => _buildPage(pageIndex),
            ),
          )
        ],
      ),
    );
  }

  String getConflictKey(int weekday, int numberOfDay) {
    return '$weekday-$numberOfDay';
  }
}
