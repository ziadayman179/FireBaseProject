class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String password;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phoneNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email':email,
      'password':password,
      'phoneNumber':phoneNumber,
    };
  }
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      phoneNumber: map['phoneNumber']?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email':email,
      'password':password,
      'phoneNumber':phoneNumber,
    };
  }
}
