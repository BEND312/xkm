import 'package:forui/assets.dart';
import 'package:hive/hive.dart';

part 'vehicle_type.g.dart';

@HiveType(typeId: 16)
enum VehicleType {
  @HiveField(0)
  car,
  @HiveField(1)
  train,
  @HiveField(2)
  plane,
  @HiveField(3)
  bike,
  @HiveField(4)
  other;

  factory VehicleType.from(String name) => VehicleType.values
      .singleWhere((t) => VehicleTypeData.from(t).name == name);
}

class VehicleTypeData {
  const VehicleTypeData(this.name, this.icon);

  final String name;
  final SvgAsset icon;

  factory VehicleTypeData.from(VehicleType type) => switch (type) {
        VehicleType.car => VehicleTypeData(
            '汽车',
            SvgAsset(
              'forui_assets',
              'car-front',
              'assets/icons/car-front.svg',
            )),
        VehicleType.train => VehicleTypeData(
            '火车',
            SvgAsset(
              'forui_assets',
              'train-front',
              'assets/icons/train-front.svg',
            )),
        VehicleType.plane => VehicleTypeData(
            '飞机',
            SvgAsset(
              'forui_assets',
              'plane',
              'assets/icons/plane.svg',
            )),
        VehicleType.bike => VehicleTypeData(
            '自行车',
            SvgAsset(
              'forui_assets',
              'bike',
              'assets/icons/bike.svg',
            )),
        VehicleType.other => VehicleTypeData(
            '其他',
            SvgAsset(
              'forui_assets',
              'ellipsis',
              'assets/icons/ellipsis.svg',
            )),
      };
}
