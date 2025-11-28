import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:swustmeow/data/global_keys.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/services/box_service.dart';
import 'package:swustmeow/services/database/database_service.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/services/hive_adapter_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:swustmeow/services/sms_interceptor_service.dart';
import 'package:swustmeow/services/tool_service.dart';
import 'package:swustmeow/services/uri_subscription_service.dart';
import 'components/utils/back_again_blocker.dart';
import 'data/values.dart';
import 'views/main_page.dart';

Future<void> main() async {
  debugPaintPointersEnabled = false;

  WidgetsFlutterBinding.ensureInitialized();

  // 初始化版本信息
  await Values.initialize();

  // 初始化 Hive
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  final has = HiveAdapterService();
  has.register();

  // 初始化缓存
  Values.cache = DefaultCacheManager();
  await BoxService.open();

  // 初始化数据库
  await DatabaseService.init();

  // 加载本地化
  await initializeDateFormatting('zh');

  // 加载工具设置
  await ToolService.loadToolSettings();

  // 初始化短信拦截器
  SmsInterceptorService.initialize();

  runApp(const Application());
}

class Application extends StatefulWidget {
  const Application({super.key});

  @override
  State<StatefulWidget> createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> with WidgetsBindingObserver {
  bool isDarkMode = false;

  // ThemeMode themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    final isDarkMode1 = brightness == Brightness.dark;
    if (!isDarkMode && isDarkMode1) {
      Values.isDarkMode.value = isDarkMode1;
      setState(() => isDarkMode = isDarkMode1);
    }
    WidgetsBinding.instance.addObserver(this);
    // _checkThemeMode();

    _loadUriListener();
    _loadGlobalService();
  }

  Future<void> _loadUriListener() async {
    GlobalService.uriSubscriptionService ??= UriSubscriptionService();
    await GlobalService.uriSubscriptionService!.initUriListener();
    if (!mounted) return;
    GlobalService.uriSubscriptionService!.initDefaultListeners(context);
  }

  Future<void> _loadGlobalService() async {
    try {
      await GlobalService.load();
      
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
    }
  }

  // Future<void> _checkThemeMode() async {
  //   final box = BoxService.commonBox;
  //   final tm = box.get('themeMode') as String?;
  //   if (tm == null) {
  //     await box.put('themeMode', themeMode.name);
  //   } else {
  //     setState(() {
  //       themeMode = ThemeMode.values.where((m) => m.name == tm).first;
  //       Values.themeMode = themeMode;
  //     });
  //   }
  // }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    final isDarkMode = View.of(context).platformDispatcher.platformBrightness ==
        Brightness.dark;
    Values.isDarkMode.value = isDarkMode;
    setState(() => this.isDarkMode = isDarkMode);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached) {
      GlobalService.dispose();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GlobalService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // 反过来，因为暗黑模式下需要白色的状态栏，反之相同
    // final overlayStyle = switch (themeMode) {
    //   ThemeMode.system =>
    //     isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    //   ThemeMode.light => SystemUiOverlayStyle.dark,
    //   ThemeMode.dark => SystemUiOverlayStyle.light,
    // };
    // final overlayStyle = SystemUiOverlayStyle.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    // .copyWith(
    //     cardStyle: theme.cardStyle.copyWith(
    //         decoration: theme.cardStyle.decoration.copyWith(
    //             color: isDarkMode
    //                 ? theme.colorScheme.primaryForeground
    //                 : null)),
    //     tileGroupStyle: theme.tileGroupStyle.copyWith(
    //         tileStyle: theme.tileGroupStyle.tileStyle.copyWith(
    //             enabledBackgroundColor: isDarkMode
    //                 ? theme.colorScheme.primaryForeground
    //                 : null)),
    //     selectGroupStyle: theme.selectGroupStyle.copyWith());

    final botToastBuilder = BotToastInit();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: MTheme.primary2,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: MTheme.primary2,
          selectionColor: MTheme.primary2.withValues(alpha: 0.5),
          selectionHandleColor: MTheme.primary2,
        ),
      ),
      localizationsDelegates: const [
        FLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh')],
      builder: (context, child) {
        var chi = child!;
        chi = IconTheme.merge(data: IconThemeData(size: 18.0), child: child);
        chi = FTheme(data: MTheme.themeData, child: chi);
        chi = botToastBuilder(context, chi);
        return chi;
      },
      navigatorObservers: [BotToastNavigatorObserver()],
      navigatorKey: GlobalKeys.navigatorKey,
      home: const BackAgainBlocker(child: MainPage()),
    );
  }
}
