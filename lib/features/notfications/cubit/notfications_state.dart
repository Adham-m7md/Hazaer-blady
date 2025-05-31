class NotificationsState {
  final bool isLoading;
  final bool hasNotifications;
  final bool hasUnreadNotifications;
  final String? errorMessage;

  NotificationsState({
    required this.isLoading,
    required this.hasNotifications,
    required this.hasUnreadNotifications,
    this.errorMessage,
  });

  factory NotificationsState.initial() {
    return NotificationsState(
      isLoading: false,
      hasNotifications: false,
      hasUnreadNotifications: false,
      errorMessage: null,
    );
  }

  NotificationsState copyWith({
    bool? isLoading,
    bool? hasNotifications,
    bool? hasUnreadNotifications,
    String? errorMessage,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      hasNotifications: hasNotifications ?? this.hasNotifications,
      hasUnreadNotifications: hasUnreadNotifications ?? this.hasUnreadNotifications,
      errorMessage: errorMessage,
    );
  }
}