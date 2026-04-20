
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
    final imgPath = rec['img']?.toString();
    if (imgPath == null || imgPath.isEmpty) continue;
    
    try {
      final file = File(imgPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final fileName = rec['imageFileName']?.toString() ?? file.path.split('/').last;
        archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
      }
    } catch (e) {
      print('خطأ في معالجة صورة: $e');
    }
  }

  if (archive.isEmpty) {
    print('لم يتم العثور على أي صور صالحة.');
    return;
  }

  final zipData = ZipEncoder().encode(archive);
  if (zipData == null) return;

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/صور_المستفيدين_${DateTime.now().toIso8601String().substring(0, 10)}.zip');
  await file.writeAsBytes(zipData);
  await Share.shareXFiles([XFile(file.path)], text: 'صور المستفيدين');
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

Future<void> exportStatisticsToExcel(Map<String, dynamic> statsData) async {
  final excel = Excel.createExcel();
  
  // الجدول الرئيسي
  final mainSheet = excel['الإحصائيات الرئيسية'];
  final mainHeaders = statsData['mainHeaders'] as List<dynamic>;
  final mainRows = statsData['mainRows'] as List<dynamic>;
  
  mainSheet.appendRow(mainHeaders.map((h) => TextCellValue(h.toString())).toList());
  for (var row in mainRows) {
    mainSheet.appendRow(row.map((cell) => TextCellValue(cell.toString())).toList());
  }
  
  // جدول تحليل المنتهية المشغولة
  if (statsData['detailHeaders'] != null && statsData['detailRows'] != null) {
    final detailSheet = excel['تحليل المنتهية المشغولة'];
    final detailHeaders = statsData['detailHeaders'] as List<dynamic>;
    final detailRows = statsData['detailRows'] as List<dynamic>;
    
    detailSheet.appendRow(detailHeaders.map((h) => TextCellValue(h.toString())).toList());
    for (var row in detailRows) {
      detailSheet.appendRow(row.map((cell) => TextCellValue(cell.toString())).toList());
    }
  }

  final bytes = excel.encode();
  if (bytes == null) return;

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/تقرير_إحصائي_${DateTime.now().toIso8601String().substring(0, 10)}.xlsx');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)], text: 'تقرير إحصائي مفصل');
}
