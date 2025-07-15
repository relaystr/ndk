import '../../../domain_layer/repositories/cashu_repo.dart';
import '../../data_sources/http_request.dart';

class CashuRepoImpl implements CashuRepo {
  final HttpRequestDS client;

  CashuRepoImpl({
    required this.client,
  });
  @override
  Future swap() {}
}
