class UserModel {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  // onboarding/profile fields
  final List<String>? motivations;
  final int? dailyIntake;
  final int? cigarettesPerPack;
  final double? packCost;
  final bool? notificationsEnabled;

  // metadata
  final bool? isFullyOnboarded;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.motivations,
    this.dailyIntake,
    this.cigarettesPerPack,
    this.packCost,
    this.notificationsEnabled,
    this.isFullyOnboarded,
    this.createdAt,
    this.updatedAt,
  });

  bool get fullyOnboarded => isFullyOnboarded ?? false;

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    List<String>? motivations,
    int? dailyIntake,
    int? cigarettesPerPack,
    double? packCost,
    bool? notificationsEnabled,
    bool? isFullyOnboarded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      motivations: motivations ?? this.motivations,
      dailyIntake: dailyIntake ?? this.dailyIntake,
      cigarettesPerPack: cigarettesPerPack ?? this.cigarettesPerPack,
      packCost: packCost ?? this.packCost,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isFullyOnboarded: isFullyOnboarded ?? this.isFullyOnboarded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toCreationMap() {
    final now = DateTime.now().toIso8601String();
    final map = <String, dynamic>{
      'uid': uid,
      'createdAt': now,
      'updatedAt': now,
      'isFullyOnboarded': isFullyOnboarded ?? false,
    };
    if (displayName != null) map['displayName'] = displayName;
    if (email != null) map['email'] = email;
    if (photoUrl != null) map['photoUrl'] = photoUrl;
    if (motivations != null) map['motivations'] = motivations;
    if (dailyIntake != null) map['dailyIntake'] = dailyIntake;
    if (cigarettesPerPack != null) map['cigarettesPerPack'] = cigarettesPerPack;
    if (packCost != null) map['packCost'] = packCost;
    if (notificationsEnabled != null)
      map['notificationsEnabled'] = notificationsEnabled;

    if (packCost != null &&
        cigarettesPerPack != null &&
        cigarettesPerPack! > 0) {
      final costPerCig = packCost! / cigarettesPerPack!;
      map['costPerCigarette'] = costPerCig;
      if (dailyIntake != null) map['dailySpending'] = costPerCig * dailyIntake!;
    }

    return map;
  }

  Map<String, dynamic> toUpdateMap({bool markOnboarded = false}) {
    final map = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (displayName != null) map['displayName'] = displayName;
    if (email != null) map['email'] = email;
    if (photoUrl != null) map['photoUrl'] = photoUrl;
    if (motivations != null) map['motivations'] = motivations;
    if (dailyIntake != null) map['dailyIntake'] = dailyIntake;
    if (cigarettesPerPack != null) map['cigarettesPerPack'] = cigarettesPerPack;
    if (packCost != null) map['packCost'] = packCost;
    if (notificationsEnabled != null)
      map['notificationsEnabled'] = notificationsEnabled;
    if (markOnboarded) map['isFullyOnboarded'] = true;

    if (packCost != null &&
        cigarettesPerPack != null &&
        cigarettesPerPack! > 0) {
      final costPerCig = packCost! / cigarettesPerPack!;
      map['costPerCigarette'] = costPerCig;
      if (dailyIntake != null) map['dailySpending'] = costPerCig * dailyIntake!;
    }

    return map;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? map['id'] ?? '',
      displayName: map['displayName'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      motivations: map['motivations'] != null
          ? List<String>.from(map['motivations'])
          : null,
      dailyIntake: map['dailyIntake'] != null
          ? (map['dailyIntake'] as num).toInt()
          : null,
      cigarettesPerPack: map['cigarettesPerPack'] != null
          ? (map['cigarettesPerPack'] as num).toInt()
          : null,
      packCost: map['packCost'] != null
          ? (map['packCost'] as num).toDouble()
          : null,
      notificationsEnabled: map['notificationsEnabled'] as bool?,
      isFullyOnboarded: map['isFullyOnboarded'] as bool?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'])
          : null,
    );
  }

  factory UserModel.fromFirebaseUser(dynamic u) {
    return UserModel(
      uid: u.uid,
      displayName: u.displayName,
      email: u.email,
      photoUrl: u.photoURL,
      isFullyOnboarded: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
