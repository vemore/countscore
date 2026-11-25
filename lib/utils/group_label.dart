import '../l10n/app_localizations.dart';
import '../providers/group_provider.dart';

/// How a group is named on screen: its name, or its invite code when the name
/// is not known (a membership recorded before names were kept), or the word
/// "Group" when neither is.
String groupLabel(AppLocalizations l10n, GroupSession s) {
  final name = s.groupName.trim();
  if (name.isNotEmpty) return name;
  final code = s.shareToken;
  return code == null ? l10n.groupSection : l10n.replaceConfigInvite(code);
}
