import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/user_settings_repository.dart';

part 'settings_providers.g.dart';

/// Application-wide settings for the Bible AI feature.
class AppSettings {
  final String bibleVersion;
  const AppSettings({this.bibleVersion = 'KJV'});
}

/// Provides the [UserSettingsRepository] backed by SharedPreferences.
@Riverpod(keepAlive: true)
Future<UserSettingsRepository> userSettingsRepository(
  UserSettingsRepositoryRef ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  return UserSettingsRepository(prefs);
}

/// Notifier for app-level settings (bible version selection, etc.).
@riverpod
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings();

  Future<void> setBibleVersion(String version) async {
    state = AppSettings(bibleVersion: version);
    final repo = await ref.read(userSettingsRepositoryProvider.future);
    await repo.setBibleVersion(version);
  }
}
