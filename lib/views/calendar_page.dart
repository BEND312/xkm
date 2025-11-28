import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/calendar/popovers/calendar_search_popover.dart';
import 'package:swustmeow/components/utils/refresh_icon.dart';
import 'package:swustmeow/entity/base_event.dart';
import 'package:swustmeow/services/boxes/calendar_box.dart';
import 'package:swustmeow/utils/text.dart';

import '../components/calendar/calendar.dart';
import '../components/calendar/calendar_header.dart';
import '../components/calendar/detail_card.dart';
import '../components/utils/base_header.dart';
import '../components/utils/base_page.dart';
import '../data/activities_store.dart';
import '../entity/activity.dart';
import '../entity/activity_type.dart';
import '../entity/calendar_event.dart';
import '../entity/system_calendar.dart';
import '../utils/calendar.dart';
import '../utils/status.dart';

class CalendarPage extends StatefulHookWidget {
  const CalendarPage({super.key, required this.activities});

  final List<Activity> activities;

  @override
  State<StatefulWidget> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with TickerProviderStateMixin {
  List<SystemCalendar>? _systemCalendars;
  List<CalendarEvent>? _systemEvents;
  bool _eventsRefreshLock = false;
  List<Activity> _activities = [];
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  late PageController _pageController;
  late FPopoverController _addEventPopoverController;
  late AnimationController _animationController;
  late FPopoverController _searchPopoverController;
  static const pages = 1000;
  bool _isRefreshing = false;
  late AnimationController _refreshAnimationController;

  // 1. 缓存月份数据计算结果
  final Map<int, DateTime> _monthCache = {};

  @override
  void initState() {
    super.initState();
    _getCachedEvents();
    _fetch();
    _activities = widget.activities;
    _selectedDate = DateTime.now();
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _pageController = PageController(initialPage: pages);
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..addListener(() => _refresh(() {}));
    _addEventPopoverController = FPopoverController(vsync: this);
    _searchPopoverController = FPopoverController(vsync: this);
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  Future<void> _fetch() async {
    await _fetchAllSystemCalendars();
    await _refreshEvents();
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _addEventPopoverController.dispose();
    _animationController.dispose();
    _searchPopoverController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllSystemCalendars() async {
    final result = await fetchAllSystemCalendars();
    final calendars =
        result.status == Status.ok ? result.value! : <SystemCalendar>[];
    setState(() => _systemCalendars = calendars);
  }

  void _getCachedEvents() {
    List<dynamic>? cachedSystemEvents = CalendarBox.get('calendarSystemEvents');
    setState(() {
      if (cachedSystemEvents?.isNotEmpty == true) {
        _systemEvents = cachedSystemEvents!.cast();
      }
    });
  }

  Future<void> _storeToCache(List<CalendarEvent> sev) async {
    await CalendarBox.put('calendarSystemEvents', sev);
  }

  Future<void> _refreshEvents() async {
    if (_eventsRefreshLock) return;
    _eventsRefreshLock = true;

    final result = await _getEvents();
    if (result == null) return;
    final sev = result;
    await _storeToCache(sev);

    if (!mounted) return;
    setState(() {
      _systemEvents = sev;
    });
  }

  Future<List<CalendarEvent>?> _getEvents() async {
    if (_systemCalendars == null) return null;

    List<CalendarEvent> systemEvents = [];
    for (final calendar in _systemCalendars!) {
      for (final event in calendar.events) {
        if (event.title == null ||
            event.eventId == null ||
            event.calendarId == null) {
          continue;
        }

        final e = CalendarEvent(
          eventId: event.eventId!,
          calendarId: event.calendarId!,
          title: event.title!,
          description: event.description,
          start: event.start,
          end: event.end,
          allDay: event.allDay ?? false,
          location: event.location,
        );

        systemEvents.add(e);
      }
    }

    return systemEvents;
  }

  DateTime _getMonthForPage(int page) {
    if (_monthCache.containsKey(page)) {
      return _monthCache[page]!;
    }

    final monthDiff = page - pages;
    final result = DateTime(
      DateTime.now().year,
      DateTime.now().month + monthDiff,
    );

    _monthCache[page] = result;
    return result;
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    _refresh(() {
      _isRefreshing = true;
      _refreshAnimationController.repeat();
    });
    final extra = await fetchExtraActivities();
    if (extra.status != Status.ok) return;
    _refresh(() => _activities =
        defaultActivities + (extra.value! as List<dynamic>).cast());
    _refresh(() {
      _isRefreshing = false;
      _refreshAnimationController.stop();
      _refreshAnimationController.reset();
    });
  }

  void _onBack() {
    _pageController.animateToPage(_pageController.initialPage,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    _refresh(() => _selectedDate = DateTime.now());
  }

  List<BaseEvent> _onSearch(String query) {
    if (query.trim() == '') return [];
    List<BaseEvent> result = [];
    result.addAll(_activities
        .where((ac) => ac.name?.pureString.contains(query.pureString) == true));
    result.addAll((_systemEvents ?? [])
        .where((ev) => ev.title.pureString.contains(query.pureString)));
    return result;
  }

  void _onDateSelected(DateTime date) {
    _refresh(() {
      _selectedDate = date;
      if (date.month != _displayedMonth.month ||
          date.year != _displayedMonth.year) {
        _displayedMonth = DateTime(date.year, date.month);
        final int diff = (_displayedMonth.year - DateTime.now().year) * 12 +
            _displayedMonth.month - DateTime.now().month;
        _pageController.animateToPage(pages + diff,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      }
    });
  }

  bool _getIsInEvent(DateTime date) =>
      [...?getEventsMatched(_systemEvents, date)].isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(
        title: '校历',
        suffixIcons: [
          CalendarSearchPopover(
            displayedMonth: _displayedMonth,
            onSearch: _onSearch,
            onSelectDate: _onDateSelected,
            searchPopoverController: _searchPopoverController,
          ),
          Stack(
            children: [
              RefreshIcon(
                isRefreshing: _isRefreshing,
                onRefresh: _onRefresh,
              ),
            ],
          ),
        ],
      ),
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    final activitiesMatched = useMemoized(() {
      return _activities.where((ac) => ac.isInActivity(_selectedDate)).toList()
        ..sort((a, b) => ActivityTypeData.of(b.type)
            .priority
            .compareTo(ActivityTypeData.of(a.type).priority));
    }, [_selectedDate, _activities]);

    final systemEventsMatched = useMemoized(
      () => getEventsMatched(_systemEvents, _selectedDate),
      [_systemEvents, _selectedDate],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          CalendarHeader(
            displayedMonth: _displayedMonth,
            onBack: _onBack,
          ),
          Calendar(
            activities: _activities,
            onDateSelected: _onDateSelected,
            selectedDate: _selectedDate,
            onPageChanged: (index) =>
                _refresh(() => _displayedMonth = _getMonthForPage(index)),
            getMonthForPage: _getMonthForPage,
            pageController: _pageController,
            getIsInEvent: _getIsInEvent,
          ),
          Expanded(
            child: DetailCard(
              key: ValueKey(_selectedDate),
              selectedDate: _selectedDate,
              activities: activitiesMatched,
              systemEvents: systemEventsMatched,
            ),
          )
        ],
      ),
    );
  }
}
