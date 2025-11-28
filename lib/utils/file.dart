import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// 获取应用的下载根目录，此处使用应用文档目录下的 "library" 文件夹
Future<String> getDownloadDirectory() async {
  final Directory appDocDir = await getApplicationDocumentsDirectory();
  final Directory libraryDir = Directory('${appDocDir.path}/library');
  if (!(await libraryDir.exists())) {
    await libraryDir.create(recursive: true);
  }
  return libraryDir.path;
}

/// 获取指定目录的完整路径
Future<String> getDirectoryPath(String dirName) async {
  final String rootPath = await getDownloadDirectory();
  final Directory dirPath = Directory('$rootPath/$dirName');
  if (!(await dirPath.exists())) {
    await dirPath.create(recursive: true);
  }
  return dirPath.path;
}

/// 保存文件到本地
///
/// [dirName] 为目录名称，[fileName] 为文件名称（包含后缀），[bytes] 为下载后的二进制数据
///
/// 返回保存后的 [File] 对象
Future<File> saveFileLocally(
    String? dirName, String fileName, List<int> bytes) async {
  final String path = dirName != null
      ? await getDirectoryPath(dirName)
      : await getDownloadDirectory();
  final String filePath = '$path/$fileName';
  final File file = File(filePath);
  return await file.writeAsBytes(bytes, flush: true);
}

/// 检查本地是否已存在相同文件
///
/// [dirName] 为目录名称，[fileName] 为文件名称（包含后缀）
///
/// 返回 true 表示文件已存在，false 则不存在
Future<bool> isFileExists(String? dirName, String fileName) async {
  final String path = dirName != null
      ? await getDirectoryPath(dirName)
      : await getDownloadDirectory();
  final String filePath = '$path/$fileName';
  final File file = File(filePath);
  return await file.exists();
}

/// 打开本地文件
///
/// [dirName] 为目录名称，[fileName] 为文件名称（包含后缀）
///
/// 如果文件存在，则调用系统默认程序打开并返回 true；否则返回 false
Future<bool> openFile(String? dirName, String fileName) async {
  final String path = dirName != null
      ? await getDirectoryPath(dirName)
      : await getDownloadDirectory();
  final String filePath = '$path/$fileName';
  final File file = File(filePath);
  if (await file.exists()) {
    await OpenFile.open(filePath);
    return true;
  } else {
    return false;
  }
}
