import 'package:dartz/dartz.dart';
import 'package:hadaer_blady/core/errors/failures.dart';
import 'package:hadaer_blady/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepo {
  Future<Either<Failure, UserEntity>> createUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String jopTitle,
  });

  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
}
