import 'package:url_launcher/url_launcher.dart';

class LauncherService {
  Uri _resolveWebUri({required String packageName, String? playUrl}) {
    final fallback =
        'https://play.google.com/store/apps/details?id=$packageName';
    if (playUrl == null || playUrl.isEmpty) {
      return Uri.parse(fallback);
    }
    return Uri.parse(playUrl);
  }

  Future<bool> openPlayStore({
    required String packageName,
    String? playUrl,
  }) async {
    final marketUri = Uri.parse('market://details?id=$packageName');
    final webUri = _resolveWebUri(
      packageName: packageName,
      playUrl: playUrl,
    );

    final openedMarket = await launchUrl(
      marketUri,
      mode: LaunchMode.externalApplication,
    );
    if (openedMarket) {
      return true;
    }

    final openedWebExternal = await launchUrl(
      webUri,
      mode: LaunchMode.externalApplication,
    );
    if (openedWebExternal) {
      return true;
    }

    return await launchUrl(
      webUri,
      mode: LaunchMode.platformDefault,
    );
  }

  Future<bool> openInstalledOrStore({
    required String packageName,
    String? playUrl,
  }) async {
    if (packageName.isNotEmpty) {
      final appUri = Uri.parse('android-app://$packageName');
      if (await canLaunchUrl(appUri)) {
        final openedApp = await launchUrl(
          appUri,
          mode: LaunchMode.externalApplication,
        );
        if (openedApp) {
          return true;
        }
      }
    }

    return openPlayStore(
      packageName: packageName,
      playUrl: playUrl,
    );
  }

  Future<bool> openWebUrl({
    required String packageName,
    String? playUrl,
  }) async {
    final webUri = _resolveWebUri(
      packageName: packageName,
      playUrl: playUrl,
    );

    final openedExternal = await launchUrl(
      webUri,
      mode: LaunchMode.externalApplication,
    );
    if (openedExternal) {
      return true;
    }

    final openedDefault = await launchUrl(
      webUri,
      mode: LaunchMode.platformDefault,
    );
    if (openedDefault) {
      return true;
    }

    return await launchUrl(
      webUri,
      mode: LaunchMode.inAppBrowserView,
    );
  }
}
