import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import 'db.dart';

Future<void> mergeData() async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (result == null || result.files.isEmpty) return;

  for (final file in result.files) {
    final bytes = file.bytes;
    if (bytes == null) continue;

    try {
      final content = utf8.decode(bytes);
      final data = jsonDecode(content);
      final List recordsList = data is List ? data : (data['records'] ?? []);

      for (final rec in recordsList) {
        if (rec is! Map) continue;

        final recordMap = Map<String, dynamic>.from(rec);
        if (recordMap['uniqueKey'] == null ||
            recordMap['uniqueKey'].toString().trim().isEmpty) {
          recordMap['uniqueKey'] = DB.buildUniqueKey(recordMap);
        }

        await DB.mergeRecord(recordMap);
      }

      print('تم دمج الملف بنجاح: ${file.name}');
    } catch (e) {
      print('خطأ في دمج ملف: ${file.name} - $e');
    }
  }
}
