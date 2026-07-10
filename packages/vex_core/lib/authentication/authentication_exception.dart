import '../shared/vex_exception.dart';

final class AuthenticationException extends VexException {
  const AuthenticationException(super.message, {super.code, super.cause});
}
