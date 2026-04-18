
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'db.dart';
import 'package:sqflite/sqflite.dart';

Future<void> importExcel() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx', 'xls'],
  );

  if (result == null || result.files.isEmpty) return;

  final bytes = result.files.first.bytes;
  if (bytes == null) return;

  final excel = Excel.decodeBytes(bytes);
  final db = await DB.db;

  for (var tableName in excel.tables.keys) {
    final sheet = excel.tables[tableName]!;

    for (var row in sheet.rows.skip(1)) {
      if (row.isEmpty || row[0] == null) continue;

      String getVal(Data? cell) {
        if (cell == null || cell.value == null) return '';
        return cell.value.toString();
      }

      final record = {
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
        'status': '',
        'img': '',
        'imageFileName': '',
      };

      record['uniqueKey'] = '${record['program']}_${record['address']}_${record['name']}'
          .replaceAll(' ', '_')
          .toLowerCase();

      await db.insert('records', record,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}