class LoginEventBus {
  LoginEventType type;
  LoginEventBus(this.type);
}

enum LoginEventType { login, logout }
