import 'package:app_links/app_links.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  Stream<Uri> get linkStream => _appLinks.uriLinkStream;

  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();
}
