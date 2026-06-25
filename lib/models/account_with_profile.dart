import 'account.dart';
import 'profile.dart';
import 'level.dart';

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
