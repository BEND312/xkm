import 'package:swustmeow/services/database/widgets_database_service.dart';

class DatabaseService {
  static WidgetsDatabaseService? widgetsDatabaseService;

  static Future<void> init() async {
    widgetsDatabaseService ??= WidgetsDatabaseService();
    await widgetsDatabaseService?.open();
  }
}