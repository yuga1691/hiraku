import 'package:url_launcher/url_launcher.dart';

class LauncherService {
  Future<void> openPlayStore(String packageName) async {
    final marketUri = Uri.parse('market://details?id=$packageName');
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );

    final openedMarket = await launchUrl(
      marketUri,
      mode: LaunchMode.externalApplication,
    );
    if (!openedMarket) {
      await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
