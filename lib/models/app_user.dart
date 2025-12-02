class AppUser {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String photoUrl;
  final String primarySport;
  final String skillLevel;
  final String bio;
  final bool notifyGameUpdates;   // joins/leaves, reschedules, cancellations
  final bool notifyChatMessages;  // new chat messages
  final bool notifyReminders;     // 1-hour before game, etc.

  AppUser({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.photoUrl,
    this.primarySport = '',
    this.skillLevel = '',
    this.bio = '',
    this.notifyGameUpdates = true,
    this.notifyChatMessages = true, 
    this.notifyReminders = true,  
  });

  // Helper getter for full name
  String get fullName {
    if (firstName.isEmpty && lastName.isEmpty) {
      return '';
    }
    if (firstName.isEmpty) {
      return lastName;
    }
    if (lastName.isEmpty) {
      return firstName;
    }
    return '$firstName $lastName';
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'primarySport': primarySport,
      'skillLevel': skillLevel,
      'bio': bio,
      'notifyGameUpdates': notifyGameUpdates,
      'notifyChatMessages': notifyChatMessages,
      'notifyReminders': notifyReminders,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> data) {
    // Support legacy 'name' field for backward compatibility
    String firstName = data['firstName'] ?? '';
    String lastName = data['lastName'] ?? '';
    
    // If firstName/lastName not found, try to split the legacy 'name' field
    if (firstName.isEmpty && lastName.isEmpty && data['name'] != null) {
      final nameParts = (data['name'] as String).trim().split(' ');
      if (nameParts.isNotEmpty) {
        firstName = nameParts.first;
        if (nameParts.length > 1) {
          lastName = nameParts.sublist(1).join(' ');
        }
      }
    }
    
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      firstName: firstName,
      lastName: lastName,
      photoUrl: data['photoUrl'] ?? '',
      primarySport: data['primarySport'] ?? '',
      skillLevel: data['skillLevel'] ?? '',
      bio: data['bio'] ?? '',
      notifyGameUpdates: data['notifyGameUpdates'] as bool? ?? true,
      notifyChatMessages: data['notifyChatMessages'] as bool? ?? true,
      notifyReminders: data['notifyReminders'] as bool? ?? true,
    );
  }
}
