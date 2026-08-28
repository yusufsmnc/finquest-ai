enum AuthStatus { authenticated, unauthenticated }

/// Auth session state exposed by [authProvider].
class AuthState {
  final AuthStatus status;
  final String? email;

  const AuthState(this.status, {this.email});

  const AuthState.authenticated({String? email})
      : this(AuthStatus.authenticated, email: email);

  const AuthState.unauthenticated() : this(AuthStatus.unauthenticated);

  bool get isAuthenticated => status == AuthStatus.authenticated;
}
