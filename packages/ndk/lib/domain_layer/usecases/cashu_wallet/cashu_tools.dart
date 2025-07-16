import '../../../config/cashu_config.dart';

class CashuTools {
  static String composeUrl(
      {required String mintUrl,
      required String path,
      String version = '${CashuConfig.NUT_VERSION}/'}) {
    return '$mintUrl/$version$path';
  }
}
