
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DB {
  static Database? _db;

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

    if (record['uniqueKey'] == null || record['uniqueKey'].toString().isEmpty) {
      record['uniqueKey'] = '${record['program']}_${record['address']}_${record['name']}'
          .replaceAll(' ', '_')
          .toLowerCase();
    }

    print('حفظ السجل، طول الصورة: ${record['img']?.toString().length ?? 0} حرف');
    await database.insert(
      'records',
      record,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
