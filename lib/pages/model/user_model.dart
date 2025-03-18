class User {
  final String? id;
  final String? username;
  final String? email;
  final String? fcmToken;
  final int? version;

  // Constructor
  User({
     this.id,
     this.username,
     this.email,
     this.fcmToken,
     this.version,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      username: json['username'],
      email: json['email'],
      fcmToken: json['fcmToken'],
      version: json['__v'],
    );
  }
}