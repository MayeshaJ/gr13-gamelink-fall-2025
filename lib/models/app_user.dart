class AppUser {
  final String uid;
  final String email;
  final String name;
  final String photoUrl;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
    );
  }
}
