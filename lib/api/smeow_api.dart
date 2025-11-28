import 'package:dio/dio.dart';

class SMeowApiService {
  static final _dio = Dio();

  /// 初始化 Dio 配置
  static Future<void> init() async {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.validateStatus = (status) => true;
  }
}
