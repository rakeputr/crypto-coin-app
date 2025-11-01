import 'package:project_crypto_app/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String userTable = 'users';
  static const String columnId = 'id';
  static const String columnFullName = 'fullName';
  static const String columnEmail = 'email';
  static const String columnPassword = 'password';

  static const String favTable = 'favorites';
  static const String favId = 'id';
  static const String favUserId = 'userId';
  static const String favCoinId = 'coinId';

  static const String commTable = 'communities';
  static const String commId = 'id';
  static const String commName = 'name';
  static const String commLat = 'latitude';
  static const String commLon = 'longitude';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'coinlens_db.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _insertYogyaDummyData(Database db) async {
    await db.insert(commTable, {
      commName: 'Komunitas NFT UPN "Veteran" YK',
      commLat: -7.7785,
      commLon: 110.4075,
    });
    await db.insert(commTable, {
      commName: 'Warung Kopi & Diskusi Blockchain (Seturan)',
      commLat: -7.7720,
      commLon: 110.4020,
    });
    await db.insert(commTable, {
      commName: 'Grup Trading Harian Jogja',
      commLat: -7.7850,
      commLon: 110.4150,
    });
    await db.insert(commTable, {
      commName: 'Meetup Programmer Web3 (Ring Road)',
      commLat: -7.7800,
      commLon: 110.3800,
    });
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $userTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnFullName TEXT NOT NULL,
        $columnEmail TEXT UNIQUE NOT NULL,
        $columnPassword TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $favTable (
        $favId INTEGER PRIMARY KEY AUTOINCREMENT,
        $favUserId TEXT NOT NULL,
        $favCoinId TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $commTable (
        $commId INTEGER PRIMARY KEY AUTOINCREMENT,
        $commName TEXT NOT NULL,
        $commLat REAL NOT NULL,
        $commLon REAL NOT NULL
      )
    ''');

    await _insertYogyaDummyData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $favTable (
          $favId INTEGER PRIMARY KEY AUTOINCREMENT,
          $favUserId TEXT NOT NULL,
          $favCoinId TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $commTable (
          $commId INTEGER PRIMARY KEY AUTOINCREMENT,
          $commName TEXT NOT NULL,
          $commLat REAL NOT NULL,
          $commLon REAL NOT NULL
        )
      ''');
    }
    if (newVersion >= 4) {
      await db.delete(commTable);
      await _insertYogyaDummyData(db);
    }
  }

  Future<int> registerUser(User user) async {
    final db = await database;
    try {
      return await db.insert(
        userTable,
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
      userTable,
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
      userTable,
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
    final List<Map<String, dynamic>> maps = await db.query(userTable);

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

  Future<void> addFavorite(String userId, String coinId) async {
    final db = await database;
    await db.insert(favTable, {
      favUserId: userId,
      favCoinId: coinId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeFavorite(String userId, String coinId) async {
    final db = await database;
    await db.delete(
      favTable,
      where: '$favUserId = ? AND $favCoinId = ?',
      whereArgs: [userId, coinId],
    );
  }

  Future<bool> isFavorite(String userId, String coinId) async {
    final db = await database;
    final result = await db.query(
      favTable,
      where: '$favUserId = ? AND $favCoinId = ?',
      whereArgs: [userId, coinId],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getFavorites(String userId) async {
    final db = await database;
    return await db.query(
      favTable,
      where: '$favUserId = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllCommunities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(commTable);
    return maps;
  }

  Future<int> addCommunity({
    required String name,
    required double lat,
    required double lon,
  }) async {
    final db = await database;
    return await db.insert(commTable, {
      commName: name,
      commLat: lat,
      commLon: lon,
    });
  }
}
