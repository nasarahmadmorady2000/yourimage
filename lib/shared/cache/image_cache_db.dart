import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ImageCacheDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'image_cache.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE images (
            id INTEGER PRIMARY KEY
          )
        ''');
      },
    );

    return _db!;
  }

  static Future<void> saveImages(List<int> ids) async {
    final db = await database;

    await db.delete('images');

    for (final id in ids) {
      await db.insert('images', {'id': id});
    }
  }

  static Future<List<int>> getImages() async {
    final db = await database;

    final result = await db.query('images');

    return result.map((e) => e['id'] as int).toList();
  }

  static Future<void> clear() async {
    final db = await database;
    await db.delete('images');
  }
}
