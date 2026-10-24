enum UserRole {
  customer,
  admin;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.customer;
    switch (role.toLowerCase().trim()) {
      case 'admin':
        return UserRole.admin;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  String toDbString() {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.customer:
        return 'customer';
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isCustomer => this == UserRole.customer;
}
