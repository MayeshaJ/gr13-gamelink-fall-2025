class AppUser {
  final String uid;
  final String email;
  final String name;
  final String photoUrl;
  final String primarySport;
  final String skillLevel;
  final String bio;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.photoUrl,
    this.primarySport = '',
    this.skillLevel = '',
    this.bio = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'primarySport': primarySport,
      'skillLevel': skillLevel,
      'bio': bio,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      primarySport: data['primarySport'] ?? '',
      skillLevel: data['skillLevel'] ?? '',
      bio: data['bio'] ?? '',
    );
  }
}
