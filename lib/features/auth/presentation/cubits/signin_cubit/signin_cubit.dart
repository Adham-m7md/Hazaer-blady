import 'package:bloc/bloc.dart';
import 'package:hadaer_blady/features/auth/domain/entities/user_entity.dart';
import 'package:hadaer_blady/features/auth/domain/repos/auth_repo.dart';
import 'package:meta/meta.dart';

part 'signin_state.dart';

class SigninCubit extends Cubit<SigninState> {
  final AuthRepo authRepo;
  SigninCubit(this.authRepo) : super(SigninInitial());

  Future<void> signIn(String email, String password) async {
    emit(SigninLoading());

    var result = await authRepo.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    result.fold(
      (l) => emit(SigninFailure(message: l.message)),
      (r) => emit(SigninSuccess(userEntity: r)),
    );
  }
}
