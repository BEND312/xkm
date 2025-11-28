import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class WidgetsDatabaseService {
  static const dbName = 'widgets.db';
  static const tableName = 'widgets';
  Database? _db;

  Future<void> open() async {
    var databasesPath = await getDatabasesPath();
    String dbPath = path.join(databasesPath, dbName);

    // TODO 支持 iOS
    if (Platform.isIOS) {
    } else {
      _db = await openDatabase(dbPath, version: 1,
          onCreate: (Database db, int version) async {
            await _createDb(db);
          }, onOpen: (Database db) async {
            // 检查表是否存在，如果不存在则创建 (处理数据库已存在但表被删除的情况)
            var tableExists = await _checkTableExists(db);
            if (!tableExists) {
              await _createDb(db);
              
            }
          });
    }
  }

  // 检查表是否存在
  static Future<bool> _checkTableExists(Database db) async {
    try {
      await db.rawQuery('SELECT * FROM $tableName LIMIT 1');
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _createDb(Database db) async {
    await db.execute('DROP TABLE IF EXISTS $tableName');
    await db.execute('''
      CREATE TABLE $tableName (
          single_course_success BOOLEAN,
          single_course_last_update_timestamp BIGINT,
          single_course_current_course_json TEXT,
          single_course_next_course_json TEXT,
          single_course_week_num INTEGER,
          today_courses_success BOOLEAN,
          today_courses_last_update_timestamp BIGINT,
          today_courses_today_courses_list TEXT,
          today_courses_week_num INTEGER
      );''');
  }

  Future<void> update(String columnName, dynamic value) async {
    if (_db == null) {
      await open(); // 确保数据库已打开
    }
    if (_db == null) {
      throw Exception('数据库无法开启');
    }

    try {
      // 检查列是否存在
      final tableInfo = await _db!.rawQuery('PRAGMA table_info($tableName)');
      final columnExists =
      tableInfo.any((column) => column['name'] == columnName);

      if (!columnExists) {
        // 列不存在，则新建列
        String columnType;
        if (value is bool) {
          columnType = 'BOOLEAN';
        } else if (value is int || value is double) {
          columnType = 'REAL';
        } else if (value is String || value == null) {
          columnType = 'TEXT';
        } else {
          throw Exception('未知数据类型 $columnName：${value.runtimeType}');
        }
        await _db!.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnType');
        
      }

      // 检查表是否为空
      final count = Sqflite.firstIntValue(
          await _db!.rawQuery('SELECT COUNT(*) FROM $tableName'));

      // 根据值类型构建 SQL 查询
      String sql;
      List<dynamic>? arguments;

      if (value == null) {
        sql = 'UPDATE $tableName SET $columnName = NULL';
      } else if (value is bool) {
        int intValue = value ? 1 : 0;
        sql = 'UPDATE $tableName SET $columnName = ?';
        arguments = [intValue];
      } else if (value is int || value is double) {
        sql = 'UPDATE $tableName SET $columnName = ?';
        arguments = [value];
      } else if (value is String) {
        sql = 'UPDATE $tableName SET $columnName = ?';
        arguments = [value];
      } else {
        throw Exception('未知数据类型 $columnName：${value.runtimeType}');
      }

      if (count != null && count > 0) {
        // 表不为空，执行更新
        await _db!.rawUpdate(sql, arguments);
      } else {
        // 表为空，执行插入
        if (value == null) {
          await _db!.rawInsert('INSERT INTO $tableName ($columnName) VALUES (NULL)');
        } else {
          await _db!.rawInsert('INSERT INTO $tableName ($columnName) VALUES (?)', arguments);
        }
      }
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }
}
