import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:swustmeow/entity/soa/leave/leave_type.dart';
import 'package:swustmeow/entity/soa/leave/vehicle_type.dart';
import 'package:swustmeow/utils/math.dart';
import 'package:swustmeow/utils/time.dart';

part 'daily_leave_options.g.dart';

@JsonSerializable()
@HiveType(typeId: 15)
class DailyLeaveOptions {
  DailyLeaveOptions({
    this.leaveBeginDate,
    this.leaveBeginTime,
    this.leaveEndDate,
    this.leaveEndTime,
    this.leaveNumNo,
    required this.leaveType,
    required this.leaveThing,
    required this.area,
    required this.comeWhere1,
    required this.a1,
    required this.a2,
    required this.a3,
    required this.outAddress,
    required this.isTellRbl,
    required this.withNumNo,
    required this.jhrName,
    required this.jhrPhone,
    required this.outTel,
    required this.outMoveTel,
    required this.relation,
    required this.outName,
    required this.stuMoveTel,
    required this.stuOtherTel,
    this.goDate,
    this.goTime,
    required this.goVehicle,
    this.backDate,
    this.backTime,
    required this.backVehicle,
  });

  /// 请假开始日期
  final DateTime? leaveBeginDate;

  /// 请假开始时
  final int? leaveBeginTime;

  /// 请假结束日期
  final DateTime? leaveEndDate;

  /// 请假结束时
  final int? leaveEndTime;

  /// 一共请假多少天，范围 0~999
  final int? leaveNumNo;

  /// 请假类型
  @HiveField(0)
  final LeaveType leaveType;

  /// 请假事由，可为空
  @HiveField(1)
  final String leaveThing;

  /// 地区代码
  @HiveField(2)
  final String area;

  /// 地区（由地区代码确定）
  @HiveField(3)
  final String comeWhere1;

  /// 省
  @HiveField(4)
  final String a1;

  /// 市
  @HiveField(5)
  final String a2;

  // 区
  @HiveField(6)
  final String a3;

  /// 详细地址，必填
  @HiveField(7)
  final String outAddress;

  /// 是否已告知家长
  @HiveField(8)
  final bool isTellRbl;

  /// 同行人数
  @HiveField(9)
  final int withNumNo;

  /// 家长或监护人姓名，可为空
  @HiveField(10)
  final String jhrName;

  /// 家长或监护人联系电话，可为空
  @HiveField(11)
  final String jhrPhone;

  /// 外出联系人固定电话，必填
  @HiveField(12)
  final String outTel;

  /// 外出联系人移动电话，必填
  @HiveField(13)
  final String outMoveTel;

  /// 外出联系人与本人关系，必填
  @HiveField(14)
  final String relation;

  /// 外出联系人姓名，必填
  @HiveField(15)
  final String outName;

  /// 本人移动电话，可为空
  @HiveField(16)
  final String stuMoveTel;

  /// 本人其他联系方式，可为空
  @HiveField(17)
  final String stuOtherTel;

  /// 去时日期
  final DateTime? goDate;

  /// 去时时
  final int? goTime;

  /// 去时交通工具
  @HiveField(18)
  final VehicleType goVehicle;

  /// 返时日期
  final DateTime? backDate;

  /// 返时时
  final int? backTime;

  /// 返时交通工具
  @HiveField(19)
  final VehicleType backVehicle;

  factory DailyLeaveOptions.fromJson(Map<String, dynamic> json) =>
      _$DailyLeaveOptionsFromJson(json);

  factory DailyLeaveOptions.fromHTML(String html, {List<String>? excludeIds}) {
    excludeIds = excludeIds ?? [];
    final soup = BeautifulSoup(html);

    String? getValueFromInput(String id) => excludeIds!.contains(id)
        ? null
        : soup.find('input', id: id)!.getAttrValue('value') ?? '';

    String? getValueFromSelect(String id) => excludeIds!.contains(id)
        ? null
        : soup
            .find('select', id: id)!
            .findAll('option')
            .firstWhere(
                (element) => element.getAttrValue('selected') == 'selected')
            .getAttrValue('value')!;

    String? getTableSelectedValue(String id) => excludeIds!.contains(id)
        ? null
        : soup
            .find('table', id: id)!
            .findAll('input')
            .firstWhere(
                (element) => element.getAttrValue('checked') == 'checked')
            .getAttrValue('value')!;

    final leaveBeginDate =
        tryParseDateTime(getValueFromInput('AllLeave1_LeaveBeginDate'));
    final leaveBeginTime =
        tryParseInt(getValueFromSelect('AllLeave1_LeaveBeginTime'));
    final leaveEndDate =
        tryParseDateTime(getValueFromInput('AllLeave1_LeaveEndDate'));
    final leaveEndTime =
        tryParseInt(getValueFromSelect('AllLeave1_LeaveEndTime'));
    final leaveNumNo = tryParseInt(getValueFromInput('AllLeave1_LeaveNumNo'));
    final leaveType = LeaveType.from(
        getTableSelectedValue('AllLeave1_LeaveType') ?? LeaveType.seekJob.name);
    final leaveThing = excludeIds.contains('AllLeave1_LeaveThing')
        ? null
        : soup.find('textarea', id: 'AllLeave1_LeaveThing')!.text;
    final area = getValueFromInput('AllLeave1_area');
    final comeWhere1 = getValueFromInput('AllLeave1_ComeWhere1');
    final a1 = getValueFromInput('A1');
    final a2 = getValueFromInput('A2');
    final a3 = getValueFromInput('A3');
    final outAddress = getValueFromInput('AllLeave1_OutAddress');
    final isTellRbl = excludeIds.contains('AllLeave1_IsTellRbl')
        ? null
        : soup
                .find('span', id: 'AllLeave1_IsTellRbl')!
                .findAll('input')
                .singleWhere(
                    (element) => element.getAttrValue('checked') == 'checked')
                .getAttrValue('value') ==
            '1';
    final withNumNo = tryParseInt(getValueFromSelect('AllLeave1_WithNumNo'));
    final jhrName = getValueFromInput('AllLeave1_JHRName');
    final jhrPhone = getValueFromInput('AllLeave1_JHRPhone');
    final outTel = getValueFromInput('AllLeave1_OutTel');
    final outMoveTel = getValueFromInput('AllLeave1_OutMoveTel');
    final relation = getValueFromInput('AllLeave1_Relation');
    final outName = getValueFromInput('AllLeave1_OutName');
    final stuMoveTel = getValueFromInput('AllLeave1_StuMoveTel');
    final stuOtherTel = getValueFromInput('AllLeave1_OutMoveTel');
    final goDate = tryParseDateTime(getValueFromInput('AllLeave1_GoDate'));
    final goTime = tryParseInt(getValueFromSelect('AllLeave1_GoTime'));
    final goVehicle = VehicleType.from(
        getTableSelectedValue('AllLeave1_GoVehicle') ?? VehicleType.car.name);
    final backDate = tryParseDateTime(getValueFromInput('AllLeave1_BackDate'));
    final backTime = tryParseInt(getValueFromSelect('AllLeave1_BackTime'));
    final backVehicle = VehicleType.from(
        getTableSelectedValue('AllLeave1_BackVehicle') ?? VehicleType.car.name);

    return DailyLeaveOptions(
      leaveBeginDate: leaveBeginDate,
      leaveBeginTime: leaveBeginTime,
      leaveEndDate: leaveEndDate,
      leaveEndTime: leaveEndTime,
      leaveNumNo: leaveNumNo,
      leaveType: leaveType,
      leaveThing: leaveThing ?? '',
      area: area ?? '',
      comeWhere1: comeWhere1 ?? '',
      a1: a1 ?? '',
      a2: a2 ?? '',
      a3: a3 ?? '',
      outAddress: outAddress ?? '',
      isTellRbl: isTellRbl ?? false,
      withNumNo: withNumNo ?? 0,
      jhrName: jhrName ?? '',
      jhrPhone: jhrPhone ?? '',
      outTel: outTel ?? '',
      outMoveTel: outMoveTel ?? '',
      relation: relation ?? '',
      outName: outName ?? '',
      stuMoveTel: stuMoveTel ?? '',
      stuOtherTel: stuOtherTel ?? '',
      goDate: goDate,
      goTime: goTime,
      goVehicle: goVehicle,
      backDate: backDate,
      backTime: backTime,
      backVehicle: backVehicle,
    );
  }

  String parseTime() {
    final [b, e] = [leaveBeginDate, leaveEndDate]
        .map((d) => '${d!.year}年${d.month.padL2}月${d.day.padL2}日')
        .toList();
    return '$b${leaveBeginTime!.padL2}点至$e${leaveBeginTime!.padL2}点';
  }
}
