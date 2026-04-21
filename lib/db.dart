
import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DB {
  static Database? _db;

  static String _guessMimeTypeFromPath(String filePath) {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  // ========== دوال إدارة الصور ==========
  static Future<String> getImagesDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${dir.path}/census_images');
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }
    return imgDir.path;
  }

  static Future<String> saveImageToFile(String base64Image, String fileName) async {
    try {
      final bytes = base64Decode(base64Image.split(',').last);
      final imgDirPath = await getImagesDirectory();
      final file = File('$imgDirPath/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      print('خطأ في حفظ الصورة: $e');
      return '';
    }
  }

  static Future<void> deleteImageFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('خطأ في حذف الصورة: $e');
    }
  }

  static Future<String> imagePathToDataUrl(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return '';
    try {
      final file = File(filePath);
      if (!await file.exists()) return '';
      final bytes = await file.readAsBytes();
      final mime = _guessMimeTypeFromPath(filePath);
      return 'data:$mime;base64,${base64Encode(bytes)}';
    } catch (e) {
      print('خطأ في قراءة الصورة: $e');
      return '';
    }
  }

  // ========== دوال إدارة قاعدة البيانات ==========
  static Future<Database> get db async {
    _db ??= await init();
    return _db!;
  }

  static Future<Database> init() async {
    String path = join(await getDatabasesPath(), 'census2026.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            firstName TEXT,
            lastName TEXT,
            name TEXT,
            program TEXT,
            address TEXT,
            birthDate TEXT,
            birthPlace TEXT,
            done INTEGER DEFAULT 0,
            e INTEGER DEFAULT 0,
            g INTEGER DEFAULT 0,
            w INTEGER DEFAULT 0,
            s INTEGER DEFAULT 0,
            status TEXT,
            img TEXT,
            imageFileName TEXT,
            uniqueKey TEXT UNIQUE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE records ADD COLUMN uniqueKey TEXT UNIQUE');
        }
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getAllRecords() async {
    final database = await db;
    return await database.query('records');
  }

  static Future<void> saveRecord(Map<String, dynamic> record) async {
    final database = await db;

    // معالجة الصورة: إذا وُجد base64، نحفظه كملف ونستبدل القيمة بالمسار
    if (record['img'] != null && record['img'].toString().startsWith('data:image')) {
      final base64 = record['img'];
      final fileName = record['imageFileName'] ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // حذف الصورة القديمة إذا كان هناك مسار قديم (عند التحديث)
      if (record['id'] != null) {
        final old = await database.query(
          'records',
          columns: ['img'],
          where: 'id = ?',
          whereArgs: [record['id']],
        );
        if (old.isNotEmpty) {
          final oldImg = old.first['img'] as String?;
          if (oldImg != null && oldImg.isNotEmpty && !oldImg.startsWith('data:image')) {
            await deleteImageFile(oldImg);
          }
        }
      }

      final filePath = await saveImageToFile(base64, fileName);
      record['img'] = filePath; // استبدال base64 بمسار الملف
    }

    // إنشاء مفتاح فريد إذا لم يكن موجود
    if (record['uniqueKey'] == null || record['uniqueKey'].toString().isEmpty) {
      record['uniqueKey'] = '${record['program']}_${record['address']}_${record['name']}'
          .replaceAll(' ', '_')
          .toLowerCase();
    }

    await database.insert(
      'records',
      record,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
