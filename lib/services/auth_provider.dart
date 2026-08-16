import 'package:flutter_riverpod/legacy.dart';
import 'auth_service.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  AuthState({this.isLoading = false, this.error, this.isLoggedIn = false});

  AuthState copyWith({bool? isLoading, String? error, bool? isLoggedIn}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AuthService.login(email, password);

    if (result["success"] == true) {
      state = state.copyWith(isLoading: false, isLoggedIn: true);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result["message"]);
      return false;
    }
  }

  Future<bool> register(
      String fullName, String email, String password, String role) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AuthService.register(fullName, email, password, role);

    if (result["success"] == true) {
      state = state.copyWith(isLoading: false);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result["message"]);
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});