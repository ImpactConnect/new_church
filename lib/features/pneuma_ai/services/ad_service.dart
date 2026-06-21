/// Stub AdService — ads not yet integrated in this app build.
class AdService {
  static Future<void> initialize() async {}
  static String get bannerAdUnitId => '';
  static String get interstitialAdUnitId => '';

  static bool shouldShowAds({required bool isPremiumUser}) {
    return false;
  }

  static Future<void> loadRewarded({
    required Function(dynamic) onLoaded,
    required Function(dynamic) onFailedToLoad,
  }) async {
    onFailedToLoad(null);
  }
}
