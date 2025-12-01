import 'package:latlong2/latlong.dart';

// Model untuk Komunitas
class CommunityModel {
  final int? id;
  final String name;
  final String description;
  final LatLng location;
  final String address;
  final String? imageUrl;
  final String createdBy;
  final DateTime createdAt;
  final int memberCount;

  CommunityModel({
    this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.address,
    this.imageUrl,
    required this.createdBy,
    required this.createdAt,
    this.memberCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'address': address,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'memberCount': memberCount,
    };
  }

  factory CommunityModel.fromMap(Map<String, dynamic> map) {
    return CommunityModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      location: LatLng(map['latitude'] as double, map['longitude'] as double),
      address: map['address'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      createdBy: map['createdBy'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      memberCount: map['memberCount'] as int? ?? 0,
    );
  }
}

// Model untuk Member Komunitas
class CommunityMemberModel {
  final int? id;
  final int communityId;
  final String userId;
  final String userName;
  final DateTime joinedAt;
  final String role; // 'admin', 'moderator', 'member'

  CommunityMemberModel({
    this.id,
    required this.communityId,
    required this.userId,
    required this.userName,
    required this.joinedAt,
    this.role = 'member',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'communityId': communityId,
      'userId': userId,
      'userName': userName,
      'joinedAt': joinedAt.toIso8601String(),
      'role': role,
    };
  }

  factory CommunityMemberModel.fromMap(Map<String, dynamic> map) {
    return CommunityMemberModel(
      id: map['id'] as int?,
      communityId: map['communityId'] as int,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      joinedAt: DateTime.parse(map['joinedAt'] as String),
      role: map['role'] as String? ?? 'member',
    );
  }
}

// Model untuk Post/Aktivitas Komunitas
class CommunityPostModel {
  final int? id;
  final int communityId;
  final String userId;
  final String userName;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final int likeCount;

  CommunityPostModel({
    this.id,
    required this.communityId,
    required this.userId,
    required this.userName,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.likeCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'communityId': communityId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
    };
  }

  factory CommunityPostModel.fromMap(Map<String, dynamic> map) {
    return CommunityPostModel(
      id: map['id'] as int?,
      communityId: map['communityId'] as int,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      content: map['content'] as String,
      imageUrl: map['imageUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      likeCount: map['likeCount'] as int? ?? 0,
    );
  }
}
