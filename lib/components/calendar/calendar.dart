import 'package:flutter/material.dart';

import '../../entity/activity.dart';
import 'calendar_grid.dart';

class Calendar extends StatelessWidget {
  const Calendar({
    super.key,
    required this.activities,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPageChanged,
    required this.getMonthForPage,
    required this.pageController,
    this.showBadges = true,
    required this.getIsInEvent,
  });

  final List<Activity> activities;
  final DateTime selectedDate;
  final Function(DateTime date) onDateSelected;
  final Function(int index) onPageChanged;
  final DateTime Function(int index) getMonthForPage;
  final PageController pageController;
  final bool showBadges;
  final bool Function(DateTime) getIsInEvent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32 + 50 * 6 - 5,
      child: PageView.builder(
        controller: pageController,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final month = getMonthForPage(index);
          return CalendarGrid(
            displayedMonth: month,
            selectedDate: selectedDate,
            activities: activities,
            onDateSelected: onDateSelected,
            showBadges: showBadges,
            getIsInEvent: getIsInEvent,
          );
        },
      ),
    );
  }
}
