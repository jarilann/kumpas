/// A stand-in for Firebase's `User` object. Represents whoever is
/// currently "signed in" locally on this device — either a real
/// local account (email + password stored in SharedPreferences) or
/// a guest session (isAnonymous == true, nothing persisted).
class LocalUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  const LocalUser({
    required this.uid,
    required this.isAnonymous,
    this.email,
    this.displayName,
  });

  LocalUser copyWith({String? displayName}) => LocalUser(
    uid: uid,
    email: email,
    isAnonymous: isAnonymous,
    displayName: displayName ?? this.displayName,
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'isAnonymous': isAnonymous,
  };

  factory LocalUser.fromMap(Map<String, dynamic> map) => LocalUser(
    uid: map['uid'] as String,
    email: map['email'] as String?,
    displayName: map['displayName'] as String?,
    isAnonymous: map['isAnonymous'] == true,
  );
}
