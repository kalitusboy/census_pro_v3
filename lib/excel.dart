
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'db.dart';

Future<void> importExcel() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      print("⚠️ لم يتم اختيار أي ملف");
      return;
    }

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      print("⚠️ فشل في قراءة محتوى الملف");
      return;
    }

    final excel = Excel.decodeBytes(bytes);
    final db = await DB.db;
    int importedCount = 0;

    for (var tableName in excel.tables.keys) {
      final sheet = excel.tables[tableName]!;

      // نبدأ من الصف الثاني (تخطي الـ Header)
      for (var row in sheet.rows.skip(1)) {
        if (row.isEmpty || row[0] == null || row[0]!.value.toString().trim().isEmpty) {
          continue; // تخطي الصفوف الفارغة
        }

        String getVal(dynamic cell) {
          if (cell == null || cell.value == null) return '';
          return cell.value.toString().trim();
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

        // بناء uniqueKey بشكل صحيح ونظيف
        record['uniqueKey'] = '\( {record['program']}_ \){record['address']}_${record['name']}'
            .replaceAll(RegExp(r'[^a-zA-Z0-9_ ]'), '_')  // تنظيف الحروف
            .replaceAll(RegExp(r'\s+'), '_')             // استبدال المسافات
            .toLowerCase();

        try {
          await db.insert(
            'records',
            record,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          importedCount++;
        } catch (e) {
          print("خطأ في إدخال سجل: $e");
        }
      }
    }

    print("✅ تم استيراد $importedCount سجل بنجاح");
  } catch (e) {
    print("❌ خطأ عام أثناء الاستيراد: $e");
  }
}
