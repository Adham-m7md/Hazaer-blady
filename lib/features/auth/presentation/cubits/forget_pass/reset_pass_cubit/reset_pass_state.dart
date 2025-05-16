part of 'reset_pass_cubit.dart';

@immutable
sealed class ResetPassState {}

final class ResetPassInitial extends ResetPassState {}

final class ResetPassLoading extends ResetPassState {}

final class ResetPassSuccess extends ResetPassState {}

final class ResetPassFailure extends ResetPassState {
  final String message;

  ResetPassFailure({required this.message});
}
