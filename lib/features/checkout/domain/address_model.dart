import '../../../core/utils/parse_helpers.dart';

class AddressModel {
  final String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String streetAddress;
  final String landmark;
  final String city;
  final String state;
  final String pinCode;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.streetAddress,
    this.landmark = '',
    required this.city,
    required this.state,
    required this.pinCode,
    this.isDefault = false,
  });

  String get fullAddress {
    final parts = [
      streetAddress,
      if (landmark.isNotEmpty) 'Near $landmark',
      '$city, $state - $pinCode',
    ];
    return parts.join('\n');
  }

  factory AddressModel.fromMap(Map<String, dynamic> map, String id) {
    return AddressModel(
      id: id,
      userId: ParseHelpers.parseString(map['userId']),
      fullName: ParseHelpers.parseString(map['fullName']),
      phoneNumber: ParseHelpers.parseString(map['phoneNumber']),
      streetAddress: ParseHelpers.parseString(map['streetAddress']),
      landmark: ParseHelpers.parseString(map['landmark']),
      city: ParseHelpers.parseString(map['city']),
      state: ParseHelpers.parseString(map['state']),
      pinCode: ParseHelpers.parseString(map['pinCode']),
      isDefault: ParseHelpers.parseBool(map['isDefault'], false),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'streetAddress': streetAddress,
      'landmark': landmark,
      'city': city,
      'state': state,
      'pinCode': pinCode,
      'isDefault': isDefault,
    };
  }

  AddressModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? streetAddress,
    String? landmark,
    String? city,
    String? state,
    String? pinCode,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id,
      userId: userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      streetAddress: streetAddress ?? this.streetAddress,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
