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
  static const String commDescription = 'description';
  static const String commLat = 'latitude';
  static const String commLon = 'longitude';
  static const String commAddress = 'address';
  static const String commImageUrl = 'imageUrl';
  static const String commCreatedBy = 'createdBy';
  static const String commCreatedAt = 'createdAt';
  static const String commMemberCount = 'memberCount';

  static const String memberTable = 'community_members';
  static const String memberId = 'id';
  static const String memberCommunityId = 'communityId';
  static const String memberUserId = 'userId';
  static const String memberUserName = 'userName';
  static const String memberJoinedAt = 'joinedAt';
  static const String memberRole = 'role';

  static const String postTable = 'community_posts';
  static const String postId = 'id';
  static const String postCommunityId = 'communityId';
  static const String postUserId = 'userId';
  static const String postUserName = 'userName';
  static const String postContent = 'content';
  static const String postImageUrl = 'imageUrl';
  static const String postCreatedAt = 'createdAt';
  static const String postLikeCount = 'likeCount';

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
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _insertYogyaDummyData(Database db) async {
    final now = DateTime.now().toIso8601String();
    const String dummyCreatorId = 'dummy_admin_id';

    await db.insert(commTable, {
      commName: 'Komunitas NFT UPN "Veteran" YK',
      commDescription:
          'Komunitas diskusi dan edukasi seputar Non-Fungible Token (NFT) dan Web3 untuk mahasiswa UPN "Veteran" Yogyakarta.',
      commLat: -7.7785,
      commLon: 110.4075,
      commAddress:
          'Jl. Swadaya No.18A, Condongcatur, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55283',
      commImageUrl: 'https://placehold.co/600x400/007bff/white?text=NFT+UPN',
      commCreatedBy: dummyCreatorId,
      commCreatedAt: now,
      commMemberCount: 0,
    });
    await db.insert(commTable, {
      commName: 'Warung Kopi & Diskusi Blockchain (Seturan)',
      commDescription:
          'Tempat kumpul santai sambil ngopi dan membahas perkembangan teknologi Blockchain, DeFi, dan Crypto terbaru di area Seturan.',
      commLat: -7.7720,
      commLon: 110.4020,
      commAddress:
          'Jl. Seturan Raya No.15, Kledokan, Caturtunggal, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      commImageUrl:
          'https://placehold.co/600x400/28a745/white?text=Diskusi+Kopi',
      commCreatedBy: dummyCreatorId,
      commCreatedAt: now,
      commMemberCount: 0,
    });
    await db.insert(commTable, {
      commName: 'Grup Trading Harian Jogja',
      commDescription:
          'Fokus pada analisis teknikal, strategi trading harian, dan berita pasar kripto untuk trader di area Yogyakarta.',
      commLat: -7.7850,
      commLon: 110.4150,
      commAddress: 'Area Malioboro, Daerah Istimewa Yogyakarta',
      commImageUrl:
          'https://placehold.co/600x400/ffc107/white?text=Trading+Harian',
      commCreatedBy: dummyCreatorId,
      commCreatedAt: now,
      commMemberCount: 0,
    });
    await db.insert(commTable, {
      commName: 'Meetup Programmer Web3 (Ring Road)',
      commDescription:
          'Pertemuan rutin untuk developer yang tertarik pada Solidity, smart contracts, dan pembangunan DApps.',
      commLat: -7.7800,
      commLon: 110.3800,
      commAddress: 'Dekat Ring Road Utara, Yogyakarta',
      commImageUrl: 'https://placehold.co/600x400/dc3545/white?text=Web3+Dev',
      commCreatedBy: dummyCreatorId,
      commCreatedAt: now,
      commMemberCount: 0,
    });
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users Table
    await db.execute('''
      CREATE TABLE $userTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnFullName TEXT NOT NULL,
        $columnEmail TEXT UNIQUE NOT NULL,
        $columnPassword TEXT NOT NULL
      )
    ''');

    // Favorites Table
    await db.execute('''
      CREATE TABLE $favTable (
        $favId INTEGER PRIMARY KEY AUTOINCREMENT,
        $favUserId TEXT NOT NULL,
        $favCoinId TEXT NOT NULL
      )
    ''');

    // Communities Table
    await db.execute('''
    CREATE TABLE $commTable (
      $commId INTEGER PRIMARY KEY AUTOINCREMENT,
      $commName TEXT NOT NULL,
      $commDescription TEXT,
      $commLat REAL NOT NULL,
      $commLon REAL NOT NULL,
      $commAddress TEXT,
      $commImageUrl TEXT,
      $commCreatedBy TEXT NOT NULL,
      $commCreatedAt TEXT NOT NULL,
      $commMemberCount INTEGER DEFAULT 0
    )
  ''');

    // Community Members Table
    await db.execute('''
    CREATE TABLE $memberTable (
      $memberId INTEGER PRIMARY KEY AUTOINCREMENT,
      $memberCommunityId INTEGER NOT NULL,
      $memberUserId TEXT NOT NULL,
      $memberUserName TEXT NOT NULL,
      $memberJoinedAt TEXT NOT NULL,
      $memberRole TEXT DEFAULT 'member',
      FOREIGN KEY ($memberCommunityId) REFERENCES $commTable ($commId) ON DELETE CASCADE,
      UNIQUE($memberCommunityId, $memberUserId)
    )
  ''');

    // Community Posts Table
    await db.execute('''
    CREATE TABLE $postTable (
      $postId INTEGER PRIMARY KEY AUTOINCREMENT,
      $postCommunityId INTEGER NOT NULL,
      $postUserId TEXT NOT NULL,
      $postUserName TEXT NOT NULL,
      $postContent TEXT NOT NULL,
      $postImageUrl TEXT,
      $postCreatedAt TEXT NOT NULL,
      $postLikeCount INTEGER DEFAULT 0,
      FOREIGN KEY ($postCommunityId) REFERENCES $commTable ($commId) ON DELETE CASCADE
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
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS $commTable');
      await db.execute('''
        CREATE TABLE $commTable (
          $commId INTEGER PRIMARY KEY AUTOINCREMENT,
          $commName TEXT NOT NULL,
          $commDescription TEXT,
          $commLat REAL NOT NULL,
          $commLon REAL NOT NULL,
          $commAddress TEXT,
          $commImageUrl TEXT,
          $commCreatedBy TEXT NOT NULL,
          $commCreatedAt TEXT NOT NULL,
          $commMemberCount INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE $memberTable (
          $memberId INTEGER PRIMARY KEY AUTOINCREMENT,
          $memberCommunityId INTEGER NOT NULL,
          $memberUserId TEXT NOT NULL,
          $memberUserName TEXT NOT NULL,
          $memberJoinedAt TEXT NOT NULL,
          $memberRole TEXT DEFAULT 'member',
          FOREIGN KEY ($memberCommunityId) REFERENCES $commTable ($commId) ON DELETE CASCADE,
          UNIQUE($memberCommunityId, $memberUserId)
        )
      ''');

      await db.execute('''
        CREATE TABLE $postTable (
          $postId INTEGER PRIMARY KEY AUTOINCREMENT,
          $postCommunityId INTEGER NOT NULL,
          $postUserId TEXT NOT NULL,
          $postUserName TEXT NOT NULL,
          $postContent TEXT NOT NULL,
          $postImageUrl TEXT,
          $postCreatedAt TEXT NOT NULL,
          $postLikeCount INTEGER DEFAULT 0,
          FOREIGN KEY ($postCommunityId) REFERENCES $commTable ($commId) ON DELETE CASCADE
        )
      ''');
    }
    if (newVersion >= 5) {
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
      print('Error during user registration: $e');
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

  // ========== FAVORITE OPERATIONS ==========

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

  // ========== COMMUNITY OPERATIONS ==========

  // Create Community
  Future<int> createCommunity({
    required String name,
    required String description,
    required double lat,
    required double lon,
    required String address,
    String? imageUrl,
    required String createdBy,
    required String creatorName,
  }) async {
    final db = await database;

    final communityId = await db.insert(commTable, {
      commName: name,
      commDescription: description,
      commLat: lat,
      commLon: lon,
      commAddress: address,
      commImageUrl: imageUrl,
      commCreatedBy: createdBy,
      commCreatedAt: DateTime.now().toIso8601String(),
      commMemberCount: 1,
    });

    // Auto-join creator as admin
    await joinCommunity(
      communityId: communityId,
      userId: createdBy,
      userName: creatorName,
      role: 'admin',
    );

    return communityId;
  }

  // Get All Communities
  Future<List<Map<String, dynamic>>> getAllCommunities() async {
    final db = await database;
    return await db.query(commTable, orderBy: '$commCreatedAt DESC');
  }

  // Get Community by ID
  Future<Map<String, dynamic>?> getCommunityById(int id) async {
    final db = await database;
    final results = await db.query(
      commTable,
      where: '$commId = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Update Community
  Future<int> updateCommunity({
    required int id,
    required String name,
    required String description,
    String? imageUrl,
  }) async {
    final db = await database;
    return await db.update(
      commTable,
      {
        commName: name,
        commDescription: description,
        if (imageUrl != null) commImageUrl: imageUrl,
      },
      where: '$commId = ?',
      whereArgs: [id],
    );
  }

  // Delete Community
  Future<int> deleteCommunity(int id) async {
    final db = await database;
    return await db.delete(commTable, where: '$commId = ?', whereArgs: [id]);
  }

  // ========== COMMUNITY MEMBERS OPERATIONS ==========

  // Join Community
  Future<int> joinCommunity({
    required int communityId,
    required String userId,
    required String userName,
    String role = 'member',
  }) async {
    final db = await database;

    try {
      final memberId = await db.insert(memberTable, {
        memberCommunityId: communityId,
        memberUserId: userId,
        memberUserName: userName,
        memberJoinedAt: DateTime.now().toIso8601String(),
        memberRole: role,
      });

      if (role != 'admin') {
        await db.rawUpdate(
          '''
          UPDATE $commTable 
          SET $commMemberCount = $commMemberCount + 1 
          WHERE $commId = ?
        ''',
          [communityId],
        );
      }

      return memberId;
    } catch (e) {
      print('Error joining community: $e');
      return -1;
    }
  }

  // Leave Community
  Future<bool> leaveCommunity({
    required int communityId,
    required String userId,
  }) async {
    final db = await database;

    final deleted = await db.delete(
      memberTable,
      where: '$memberCommunityId = ? AND $memberUserId = ?',
      whereArgs: [communityId, userId],
    );

    if (deleted > 0) {
      // Update member count
      await db.rawUpdate(
        '''
        UPDATE $commTable 
        SET $commMemberCount = $commMemberCount - 1 
        WHERE $commId = ? AND $commMemberCount > 0
      ''',
        [communityId],
      );
      return true;
    }

    return false;
  }

  // Check if user is member
  Future<bool> isCommunityMember({
    required int communityId,
    required String userId,
  }) async {
    final db = await database;
    final results = await db.query(
      memberTable,
      where: '$memberCommunityId = ? AND $memberUserId = ?',
      whereArgs: [communityId, userId],
    );
    return results.isNotEmpty;
  }

  // Get member role
  Future<String?> getMemberRole({
    required int communityId,
    required String userId,
  }) async {
    final db = await database;
    final results = await db.query(
      memberTable,
      columns: [memberRole],
      where: '$memberCommunityId = ? AND $memberUserId = ?',
      whereArgs: [communityId, userId],
    );
    return results.isNotEmpty ? results.first[memberRole] as String : null;
  }

  // Get Community Members
  Future<List<Map<String, dynamic>>> getCommunityMembers(
    int communityId,
  ) async {
    final db = await database;
    return await db.query(
      memberTable,
      where: '$memberCommunityId = ?',
      whereArgs: [communityId],
      orderBy: '$memberJoinedAt DESC',
    );
  }

  // Get User's Communities
  Future<List<Map<String, dynamic>>> getUserCommunities(String userId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT c.* FROM $commTable c
      INNER JOIN $memberTable m ON c.$commId = m.$memberCommunityId
      WHERE m.$memberUserId = ?
      ORDER BY m.$memberJoinedAt DESC
    ''',
      [userId],
    );
  }

  // ========== COMMUNITY POSTS OPERATIONS ==========

  Future<int> createCommunityPost({
    required int communityId,
    required String userId,
    required String userName,
    required String content,
    String? imageUrl,
  }) async {
    final db = await database;

    return await db.insert(postTable, {
      postCommunityId: communityId,
      postUserId: userId,
      postUserName: userName,
      postContent: content,
      postImageUrl: imageUrl,
      postCreatedAt: DateTime.now().toIso8601String(),
      postLikeCount: 0,
    });
  }

  Future<List<Map<String, dynamic>>> getCommunityPosts(int communityId) async {
    final db = await database;
    return await db.query(
      postTable,
      where: '$postCommunityId = ?',
      whereArgs: [communityId],
      orderBy: '$postCreatedAt DESC',
    );
  }

  Future<int> deleteCommunityPost(int postId) async {
    final db = await database;
    return await db.delete(
      postTable,
      where: '$postId = ?',
      whereArgs: [postId],
    );
  }

  Future<void> likeCommunityPost(int postId) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE $postTable 
      SET $postLikeCount = $postLikeCount + 1 
      WHERE $postId = ?
    ''',
      [postId],
    );
  }
}
