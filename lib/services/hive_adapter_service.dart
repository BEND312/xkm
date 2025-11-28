import 'package:hive/hive.dart';
import 'package:swustmeow/entity/account.dart';
import 'package:swustmeow/entity/activity.dart';
import 'package:swustmeow/entity/activity_type.dart';
import 'package:swustmeow/entity/apaertment/apartment_student_info.dart';
import 'package:swustmeow/entity/apaertment/apartment_auth_token.dart';
import 'package:swustmeow/entity/calendar_event.dart';
import 'package:swustmeow/entity/duifene/duifene_course.dart';
import 'package:swustmeow/entity/duifene/sign/duifene_sign_mode.dart';
import 'package:swustmeow/entity/run_mode.dart';
import 'package:swustmeow/entity/server_info.dart';
import 'package:swustmeow/entity/soa/exam/exam_schedule.dart';
import 'package:swustmeow/entity/soa/exam/exam_type.dart';
import 'package:swustmeow/entity/soa/leave/daily_leave_options.dart';
import 'package:swustmeow/entity/soa/leave/leave_type.dart';
import 'package:swustmeow/entity/soa/leave/vehicle_type.dart';
import 'package:swustmeow/entity/soa/course/optional_course.dart';
import 'package:swustmeow/entity/soa/score/course_score.dart';
import 'package:swustmeow/entity/soa/score/points_data.dart';
import 'package:swustmeow/entity/soa/score/score_type.dart';
import 'package:swustmeow/entity/color_mode.dart';
import 'package:swustmeow/entity/ykt/ykt_auth_token.dart';
import 'package:swustmeow/entity/ykt/ykt_card.dart';
import 'package:swustmeow/entity/ykt/ykt_card_account_info.dart';

import '../entity/soa/course/course_entry.dart';
import '../entity/soa/course/course_type.dart';
import '../entity/soa/course/courses_container.dart';
import '../entity/soa/course/optional_course_type.dart';
import '../entity/soa/course/optional_task_type.dart';
import '../entity/soa/course/term_date.dart';

class HiveAdapterService {
  void register() {
    Hive.registerAdapter<ServerInfo>(ServerInfoAdapter());
    Hive.registerAdapter<ActivityType>(ActivityTypeAdapter());
    Hive.registerAdapter<Activity>(ActivityAdapter());
    Hive.registerAdapter<CalendarEvent>(CalendarEventAdapter());
    Hive.registerAdapter<CourseEntry>(CourseEntryAdapter());
    Hive.registerAdapter<DuiFenECourse>(DuiFenECourseAdapter());
    Hive.registerAdapter<DuiFenESignMode>(DuiFenESignModeAdapter());
    Hive.registerAdapter<RunMode>(RunModeAdapter());
    Hive.registerAdapter<CourseType>(CourseTypeAdapter());
    Hive.registerAdapter<CoursesContainer>(CoursesContainerAdapter());
    Hive.registerAdapter<TermDate>(TermDateAdapter());
    Hive.registerAdapter<OptionalCourse>(OptionalCourseAdapter());
    Hive.registerAdapter<OptionalCourseType>(OptionalCourseTypeAdapter());
    Hive.registerAdapter<OptionalTaskType>(OptionalTaskTypeAdapter());
    Hive.registerAdapter<DailyLeaveOptions>(DailyLeaveOptionsAdapter());
    Hive.registerAdapter<VehicleType>(VehicleTypeAdapter());
    Hive.registerAdapter<LeaveType>(LeaveTypeAdapter());
    Hive.registerAdapter<ExamSchedule>(ExamScheduleAdapter());
    Hive.registerAdapter<ExamType>(ExamTypeAdapter());
    Hive.registerAdapter<CourseScore>(CourseScoreAdapter());
    Hive.registerAdapter<ApartmentAuthToken>(ApartmentAuthTokenAdapter());
    Hive.registerAdapter<ApartmentStudentInfo>(ApartmentStudentInfoAdapter());
    Hive.registerAdapter<ScoreType>(ScoreTypeAdapter());
    Hive.registerAdapter<PointsData>(PointsDataAdapter());
    Hive.registerAdapter<Account>(AccountAdapter());
    Hive.registerAdapter<YKTCard>(YKTCardAdapter());
    Hive.registerAdapter<YKTAuthToken>(YKTAuthTokenAdapter());
    Hive.registerAdapter<YKTCardAccountInfo>(YKTCardAccountInfoAdapter());
    Hive.registerAdapter<ColorMode>(ColorModeAdapter());
  }
}
