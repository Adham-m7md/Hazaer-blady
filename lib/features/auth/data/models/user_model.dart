import 'package:firebase_auth/firebase_auth.dart';
import 'package:hadaer_blady/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.name,
    required super.phone,
    required super.email,
    required super.jopTitel,

    required super.uId,
  });
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      name: user.displayName ?? '',
      phone: user.phoneNumber ?? '',
      email: user.email ?? '',
      jopTitel: '',
      uId: user.uid,
    );
  }
}
