import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import 'db.dart';

Future<void> importExcel() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result == null || result.files.isEmpty) return;

    Uint8List? bytes;
    if (result.files.first.path != null) {
      bytes = await File(result.files.first.path!).readAsBytes();
    } else {
      bytes = result.files.first.bytes;
    }

    if (bytes == null) return;

    final excel = Excel.decodeBytes(bytes);

    for (final tableName in excel.tables.keys) {
      final sheet = excel.tables[tableName]!;

      for (final row in sheet.rows.skip(1)) {
        if (row.isEmpty || row[0] == null) continue;

        String getVal(Data? cell) {
          if (cell == null || cell.value == null) return '';
          return cell.value.toString().trim();
        }

        final record = <String, dynamic>{
          'name': getVal(row[0]),
          'program': row.length > 1 ? getVal(row[1]) : 'عام',
          'address': row.length > 2 ? getVal(row[2]) : '',
          'birthDate': row.length > 3 ? getVal(row[3]) : '',
          'birthPlace': row.length > 4 ? getVal(row[4]) : '',
          'done': 0,
          'e': 0,
          'g': 0,
          'w': 0,
          's': 0,
          'status': 'قيد الانتظار',
          'img': '',
          'imageFileName': '',
        };

        record['uniqueKey'] = DB.buildUniqueKey(record);

        await DB.upsertExcelRecord(record);
      }
    }
  } catch (e) {
    print('خطأ في الاستيراد: $e');
  }
}
