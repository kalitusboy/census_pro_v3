
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'db.dart';

Future<void> mergeData() async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (result == null || result.files.isEmpty) return;

  final db = await DB.db;

  for (var file in result.files) {
    final bytes = file.bytes;
    if (bytes == null) continue;

    try {
      final String content = utf8.decode(bytes);
      final data = jsonDecode(content);
      final List recordsList = data is List ? data : (data['records'] ?? []);

      for (var rec in recordsList) {
        if (rec is Map) {
          final recordMap = Map<String, dynamic>.from(rec);
          if (recordMap['uniqueKey'] == null) {
            recordMap['uniqueKey'] = '${recordMap['program']}_${recordMap['address']}_${recordMap['name']}'
                .replaceAll(' ', '_')
                .toLowerCase();
          }
          await db.insert(
            'records',
            recordMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      print('تم دمج الملف بنجاح: ${file.name}');
    } catch (e) {
      print('خطأ في دمج ملف: ${file.name} - $e');
    }
  }
}