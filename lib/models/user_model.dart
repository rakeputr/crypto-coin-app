class User {
  int? id;
  String fullName;
  String email;
  String password;

  User({
    this.id,
    required this.fullName,
    required this.email,
    required this.password,
  });

  // Convert User object to Map (untuk menyimpan ke DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'password': password,
    };
  }

  // Convert Map to User object (untuk mengambil dari DB)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      fullName: map['fullName'],
      email: map['email'],
      password: map['password'],
    );
  }
}
