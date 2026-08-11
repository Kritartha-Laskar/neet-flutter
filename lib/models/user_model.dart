class UserModel {
  final int id;
  final String name;
  final String userName;
  final String gmail;
  final String? phoneNo;
  final String userType;

  const UserModel({
    required this.id,
    required this.name,
    required this.userName,
    required this.gmail,
    this.phoneNo,
    required this.userType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        userName: json['user_name']?.toString() ?? '',
        gmail: json['gmail']?.toString() ?? '',
        phoneNo: json['phone_no']?.toString(),
        userType: json['user_type']?.toString() ?? 'user',
      );

  /// Initials for avatar.
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isEmpty ? 'U' : name[0].toUpperCase();
  }
}
