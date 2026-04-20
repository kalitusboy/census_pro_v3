
import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'db.dart';

Future<void> exportToExcel(List<dynamic> data) async {
  final excel = Excel.createExcel();
  final sheet = excel['النتائج'];

  sheet.appendRow([
    TextCellValue('الاسم'),
    TextCellValue('البرنامج'),
    TextCellValue('العنوان'),
    TextCellValue('تاريخ الميلاد'),
    TextCellValue('مكان الميلاد'),
    TextCellValue('كهرباء'),
    TextCellValue('غاز'),
    TextCellValue('مياه'),
    TextCellValue('تطهير'),
    TextCellValue('الحالة'),
    TextCellValue('اسم الصورة')
  ]);

  for (var row in data) {
    sheet.appendRow([
      TextCellValue(row['الاسم']?.toString() ?? ''),
      TextCellValue(row['البرنامج']?.toString() ?? ''),
      TextCellValue(row['العنوان']?.toString() ?? ''),
      TextCellValue(row['تاريخ_الميلاد']?.toString() ?? ''),
      TextCellValue(row['مكان_الميلاد']?.toString() ?? ''),
      IntCellValue(int.tryParse(row['كهرباء']?.toString() ?? '0') ?? 0),
      IntCellValue(int.tryParse(row['غاز']?.toString() ?? '0') ?? 0),
      IntCellValue(int.tryParse(row['مياه']?.toString() ?? '0') ?? 0),
      IntCellValue(int.tryParse(row['تطهير']?.toString() ?? '0') ?? 0),
      TextCellValue(row['الحالة']?.toString() ?? ''),
      TextCellValue(row['اسم_الصورة']?.toString() ?? '')
    ]);
  }

  final bytes = excel.encode();
  if (bytes == null) return;

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/تقرير_إحصاء_${DateTime.now().toIso8601String().substring(0, 10)}.xlsx');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)], text: 'تقرير الإحصاء');
}

Future<void> exportImagesToZip(List<dynamic> rows) async {
  final archive = Archive();

  for (var rec in rows) {
    if (rec['img'] == null || rec['img'].toString().isEmpty) continue;
    try {
      final String base64Data = rec['img'].toString().split(',').last;
      final bytes = base64Decode(base64Data);
      final fileName = rec['imageFileName']?.toString() ?? 'صورة_${DateTime.now().millisecondsSinceEpoch}.jpg';
      archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
    } catch (e) {
      print('خطأ في معالجة صورة: $e');
    }
  }

  if (archive.isEmpty) return;

  final zipData = ZipEncoder().encode(archive);
  if (zipData == null) return;

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/صور_المستفيدين_${DateTime.now().toIso8601String().substring(0, 10)}.zip');
  await file.writeAsBytes(zipData);
  await Share.shareXFiles([XFile(file.path)], text: 'صور المستفيدين');
}

Future<void> exportFullJson() async {
  final allRecords = await DB.getAllRecords();
  final jsonStr = jsonEncode(allRecords);
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/قاعدة_إحصاء_${DateTime.now().toIso8601String().substring(0, 10)}.json');
  await file.writeAsString(jsonStr);
  await Share.shareXFiles([XFile(file.path)], text: 'قاعدة البيانات الكاملة');
}