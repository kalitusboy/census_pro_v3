
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
        if (rec is! Map) continue;
        final recordMap = Map<String, dynamic>.from(rec);

        // إنشاء uniqueKey إذا لم يكن موجوداً
        final uniqueKey = recordMap['uniqueKey'] ??
            '${recordMap['program']}_${recordMap['address']}_${recordMap['name']}'
                .replaceAll(' ', '_')
                .toLowerCase();
        recordMap['uniqueKey'] = uniqueKey;

        // 1. نحاول إدراج السجل (إذا لم يكن موجوداً أصلاً)
        try {
          await db.insert(
            'records',
            recordMap,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        } catch (e) {
          // السجل موجود مسبقاً، نتجاهل الخطأ
        }

        // 2. إذا كان السجل في الملف منجزاً (done=1)، نقوم بتحديث السجل الموجود
        if (recordMap['done'] == 1 || recordMap['done'] == true) {
          // نحضر البيانات التي نريد تحديثها (فقط الحقول المتعلقة بالإنجاز)
          final updateMap = {
            'done': 1,
            'e': recordMap['e'] ?? 0,
            'g': recordMap['g'] ?? 0,
            'w': recordMap['w'] ?? 0,
            's': recordMap['s'] ?? 0,
            'status': recordMap['status'],
            'img': recordMap['img'],
            'imageFileName': recordMap['imageFileName'],
          };

          // لا نحدث حقول الهوية (الاسم، العنوان...) لأنها ثابتة
          // ولكن يمكن تحديثها إذا أردت (مثلاً تصحيح إملائي) - حسب الحاجة

          await db.update(
            'records',
            updateMap,
            where: 'uniqueKey = ?',
            whereArgs: [uniqueKey],
          );
        }
        // إذا كان done=0، لا نفعل شيئاً (نترك السجل الموجود كما هو)
      }
      print('تم دمج الملف بنجاح: ${file.name}');
    } catch (e) {
      print('خطأ في دمج ملف: ${file.name} - $e');
    }
  }
}
