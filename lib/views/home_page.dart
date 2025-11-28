import 'package:flutter/material.dart';
import 'package:swustmeow/components/home/home_header.dart';
import 'package:swustmeow/components/home/home_tool_grid.dart';
import 'package:swustmeow/data/global_keys.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/widget.dart';

import '../services/value_service.dart';

class HomePage extends StatefulWidget {
  final Function() onRefresh;

  const HomePage({super.key, required this.onRefresh});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const padding = 16.0;

    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: [
        ValueListenableBuilder(
          valueListenable: ValueService.isCourseLoading,
          builder: (context, isCourseLoading, child) {
            return HomeHeader(
              activities: ValueService.activities,
              containers: ValueService.coursesContainers,
              currentCourseContainer: ValueService.currentCoursesContainer.value,
              todayCourses: ValueService.todayCourses,
              nextCourse: ValueService.nextCourse,
              currentCourse: ValueService.currentCourse,
              isLoading: isCourseLoading,
              onRefresh: () async {
                await GlobalService.load(force: true);
                widget.onRefresh();
                setState(() {});
              },
            );
          },
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Column(
            children: [
              SizedBox(height: 8),
              buildShowcaseWidget(
                key: GlobalKeys.showcaseToolGridKey,
                title: '工具栏',
                description: '一键直达，快速访问。',
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 6),
                child: HomeToolGrid(padding: padding),
              ),
              SizedBox(height: 8),
              ...joinGap(
                gap: 12,
                axis: Axis.vertical,
                widgets: [
                ],
              ),
              SizedBox(height: 90),
            ],
          ),
        ),
      ],
    );
  }
}
