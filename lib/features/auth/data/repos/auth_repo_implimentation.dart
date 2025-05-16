// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:hadaer_blady/core/errors/exeptions.dart';
import 'package:hadaer_blady/core/errors/failures.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/features/auth/data/models/user_model.dart';
import 'package:hadaer_blady/features/auth/domain/entities/user_entity.dart';
import 'package:hadaer_blady/features/auth/domain/repos/auth_repo.dart';

class AuthRepoImplimentation extends AuthRepo {
  final FirebaseAuthService firebaseAuthService;

  AuthRepoImplimentation({required this.firebaseAuthService});
  @override
  Future<Either<Failure, UserEntity>> createUser({
    required String email,
    required String jopTitle,
    required String name,
    required String password,
    required String phone,
  }) async {
    try {
      var user = await firebaseAuthService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
        jobTitle: jopTitle,
      );
      return Right(UserModel.fromFirebaseUser(user));
    } on CustomException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      log(
        'exeption in AuthRepoImplimentation.createUserWithEmailAndPassword: ${e.toString()}',
      );
      return left(ServerFailure('حدث خطأ ما الرجاء المحاولة مرة أخرى'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      var user = await firebaseAuthService.signInWithEmailOrPhone(
        emailOrPhone: email,
        password: password,
      );
      return Right(UserModel.fromFirebaseUser(user));
    } on CustomException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      log(
        'exeption in AuthRepoImplimentation.signInWithEmailorPhone: ${e.toString()}',
      );
      return left(ServerFailure('حدث خطأ ما الرجاء المحاولة مرة أخرى'));
    }
  }
}
