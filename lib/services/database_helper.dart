import 'package:project_crypto_app/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String tableName = 'users';
  static const String columnId = 'id';
  static const String columnFullName = 'fullName';
  static const String columnEmail = 'email';
  static const String columnPassword = 'password';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'coinlens_db.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnFullName TEXT NOT NULL,
        $columnEmail TEXT UNIQUE NOT NULL, 
        $columnPassword TEXT NOT NULL
      )
    ''');
  }

  Future<int> registerUser(User user) async {
    final db = await database;
    try {
      return await db.insert(
        tableName,
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      return -1;
    }
  }

  Future<User?> loginUser(String email, String hashedPassword) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: [columnId, columnFullName, columnEmail, columnPassword],
      where: '$columnEmail = ? AND $columnPassword = ?',
      whereArgs: [email, hashedPassword],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: [columnId, columnFullName, columnEmail, columnPassword],
      where: '$columnId = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);

    print('--- ISI TABEL USERS ---');
    if (maps.isEmpty) {
      print('Tabel kosong.');
    } else {
      for (var map in maps) {
        print(map);
      }
    }
    print('-----------------------');

    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }
}
