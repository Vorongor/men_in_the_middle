import 'account.dart';
import 'level.dart';
import 'profile.dart';

class AccountWithProfile {
  final Account account;
  final Profile profile;
  final Level level;

  const AccountWithProfile({
    required this.account,
    required this.profile,
    required this.level,
  });
}
