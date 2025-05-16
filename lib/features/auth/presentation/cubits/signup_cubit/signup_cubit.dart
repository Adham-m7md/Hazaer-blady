// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/features/auth/domain/entities/user_entity.dart';
import 'package:hadaer_blady/features/auth/domain/repos/auth_repo.dart';

part 'signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  SignupCubit(this.authRepo) : super(SignupInitial());

  final AuthRepo authRepo;

  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String jopTitle,
  }) async {
    emit(SignupLoading());
    final resut = await authRepo.createUser(
      email: email,
      password: password,
      name: name,
      phone: phone,
      jopTitle: jopTitle,
    );

    resut.fold(
      (l) => emit(SignupFailure(message: l.message)),
      (r) => emit(SignupSuccess(userEntity: r)),
    );
  }
}
