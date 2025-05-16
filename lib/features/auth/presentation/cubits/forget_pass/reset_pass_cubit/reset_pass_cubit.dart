import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:hadaer_blady/core/errors/exeptions.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:meta/meta.dart';

part 'reset_pass_state.dart';

class ResetPassCubit extends Cubit<ResetPassState> {
  final FirebaseAuthService authService;

  ResetPassCubit(this.authService) : super(ResetPassInitial());

  Future<void> resetPassword({required String email}) async {
    if (email.isEmpty) {
      emit(ResetPassFailure(message: 'يرجى إدخال البريد الإلكتروني'));
      return;
    }

    emit(ResetPassLoading());

    try {
      log('Attempting to reset password for: $email');
      // استدعاء دالة إعادة تعيين كلمة المرور من خدمة Firebase
      await authService.resetPassword(email: email);
      // في حالة النجاح
      log('Password reset successful');
      emit(ResetPassSuccess());
    } on CustomException catch (e) {
      // في حالة حدوث استثناء معروف
      log('CustomException in resetPassword Cubit: ${e.message}');
      emit(ResetPassFailure(message: e.message));
    } catch (e) {
      // في حالة حدوث استثناء غير متوقع
      log('Unexpected error in resetPassword Cubit: ${e.toString()}');
      emit(ResetPassFailure(message: 'حدث خطأ ما، الرجاء المحاولة مرة أخرى'));
    }
  }
}
