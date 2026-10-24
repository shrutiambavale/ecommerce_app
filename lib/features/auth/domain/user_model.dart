import '../../../core/utils/parse_helpers.dart';
import 'user_role.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final UserRole role;
  final DateTime createdAt;
  final String? defaultAddressId;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber = '',
    this.role = UserRole.customer,
    required this.createdAt,
    this.defaultAddressId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: ParseHelpers.parseString(map['email']),
      fullName: ParseHelpers.parseString(map['fullName']),
      phoneNumber: ParseHelpers.parseString(map['phoneNumber']),
      role: UserRole.fromString(map['role']?.toString()),
      createdAt: ParseHelpers.parseDateTime(map['createdAt']),
      defaultAddressId: map['defaultAddressId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role.toDbString(),
      'createdAt': createdAt.toIso8601String(),
      'defaultAddressId': defaultAddressId,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    String? defaultAddressId,
  }) {
    return UserModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt,
      defaultAddressId: defaultAddressId ?? this.defaultAddressId,
    );
  }
}
