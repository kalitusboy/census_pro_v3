import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DB {
  static Database? _db;

  static const List<String> _baseFields = [
    'firstName',
    'lastName',
    'name',
    'program',
    'address',
    'birthDate',
    'birthPlace',
  ];

  static const List<String> _surveyFields = [
    'done',
    'e',
    'g',
    'w',
    's',
    'status',
    'img',
    'imageFileName',
  ];

  static Future<Database> get db async {
    _db ??= await init();
    return _db!;
  }

  static Future<Database> init() async {
    final path = join(await getDatabasesPath(), 'census2026.db');

    return await openDatabase(
      path,
      version: 3,
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
            uniqueKey TEXT
          )
        ''');

        await db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_records_uniqueKey ON records(uniqueKey)'
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE records ADD COLUMN uniqueKey TEXT');
        }

        if (oldVersion < 3) {
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_records_uniqueKey ON records(uniqueKey)'
          );
        }
      },
    );
  }

  static String buildUniqueKey(Map<String, dynamic> record) {
    return '${record['program'] ?? 'عام'}_${record['address'] ?? ''}_${record['name'] ?? ''}'
        .replaceAll(' ', '_')
        .toLowerCase();
  }

  static bool _isBlank(dynamic value) {
    return value == null || value.toString().trim().isEmpty;
  }

  static int _intValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static Uint8List _compressImage(Uint8List input) {
    final decoded = img.decodeImage(input);
    if (decoded == null) return input;

    final resized = decoded.width > 1600
        ? img.copyResize(decoded, width: 1600)
        : decoded;

    return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
  }

  static Future<String?> _saveImageIfNeeded(
    dynamic imgValue,
    String fileName,
  ) async {
    if (_isBlank(imgValue)) return null;

    final raw = imgValue.toString().trim();

    if (!raw.startsWith('data:image')) {
      return raw;
    }

    try {
      final base64Data = raw.split(',').last;
      final originalBytes = base64Decode(base64Data);
      final compressedBytes = _compressImage(originalBytes);

      final docsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(join(docsDir.path, 'beneficiary_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final safeName = (fileName.isEmpty
              ? 'img_${DateTime.now().millisecondsSinceEpoch}.jpg'
              : fileName)
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      final targetName = safeName.toLowerCase().endsWith('.jpg') ||
              safeName.toLowerCase().endsWith('.jpeg')
          ? safeName
          : '$safeName.jpg';

      final path = join(imagesDir.path, targetName);
      await File(path).writeAsBytes(compressedBytes, flush: true);
      return path;
    } catch (e) {
      print('خطأ أثناء حفظ الصورة: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllRecords() async {
    final database = await db;
    return await database.query('records', orderBy: 'id DESC');
  }

  static Future<void> upsertExcelRecord(Map<String, dynamic> record) async {
    final database = await db;

    if (_isBlank(record['uniqueKey'])) {
      record['uniqueKey'] = buildUniqueKey(record);
    }

    final existing = await database.query(
      'records',
      where: 'uniqueKey = ?',
      whereArgs: [record['uniqueKey']],
      limit: 1,
    );

    if (existing.isEmpty) {
      await database.insert('records', record);
      return;
    }

    final merged = Map<String, dynamic>.from(existing.first);

    for (final field in _baseFields) {
      if (_isBlank(merged[field]) && !_isBlank(record[field])) {
        merged[field] = record[field];
      }
    }

    await database.update(
      'records',
      merged,
      where: 'id = ?',
      whereArgs: [merged['id']],
    );
  }

  static Future<void> mergeRecord(Map<String, dynamic> record) async {
    final database = await db;

    if (_isBlank(record['uniqueKey'])) {
      record['uniqueKey'] = buildUniqueKey(record);
    }

    final existing = await database.query(
      'records',
      where: 'uniqueKey = ?',
      whereArgs: [record['uniqueKey']],
      limit: 1,
    );

    if (existing.isEmpty) {
      final imgPath = await _saveImageIfNeeded(
        record['img'],
        record['imageFileName']?.toString() ?? '',
      );
      if (imgPath != null) {
        record['img'] = imgPath;
      }
      await database.insert('records', record);
      return;
    }

    final merged = Map<String, dynamic>.from(existing.first);

    for (final field in _baseFields) {
      if (_isBlank(merged[field]) && !_isBlank(record[field])) {
        merged[field] = record[field];
      }
    }

    final existingDone = _intValue(merged['done']);
    final incomingDone = _intValue(record['done']);
    merged['done'] = existingDone == 1 || incomingDone == 1 ? 1 : 0;

    for (final field in ['e', 'g', 'w', 's']) {
      merged[field] = _intValue(merged[field]) == 1 || _intValue(record[field]) == 1 ? 1 : 0;
    }

    if (_isBlank(merged['status']) && !_isBlank(record['status'])) {
      merged['status'] = record['status'];
    } else if (incomingDone == 1 && !_isBlank(record['status'])) {
      merged['status'] = record['status'];
    }

    if (_isBlank(merged['imageFileName']) && !_isBlank(record['imageFileName'])) {
      merged['imageFileName'] = record['imageFileName'];
    }

    if (_isBlank(merged['img']) && !_isBlank(record['img'])) {
      final imgPath = await _saveImageIfNeeded(
        record['img'],
        merged['imageFileName']?.toString() ?? record['imageFileName']?.toString() ?? '',
      );
      if (imgPath != null) {
        merged['img'] = imgPath;
      }
    }

    await database.update(
      'records',
      merged,
      where: 'id = ?',
      whereArgs: [merged['id']],
    );
  }

  static Future<void> saveRecord(Map<String, dynamic> record) async {
    final database = await db;

    if (_isBlank(record['uniqueKey'])) {
      record['uniqueKey'] = buildUniqueKey(record);
    }

    final existing = await database.query(
      'records',
      where: 'uniqueKey = ?',
      whereArgs: [record['uniqueKey']],
      limit: 1,
    );

    final merged = existing.isEmpty
        ? Map<String, dynamic>.from(record)
        : {
            ...existing.first,
            ...record,
          };

    final imgPath = await _saveImageIfNeeded(
      merged['img'],
      merged['imageFileName']?.toString() ?? '',
    );
    if (imgPath != null) {
      merged['img'] = imgPath;
    }

    if (existing.isEmpty) {
      await database.insert('records', merged);
    } else {
      await database.update(
        'records',
        merged,
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }
}
