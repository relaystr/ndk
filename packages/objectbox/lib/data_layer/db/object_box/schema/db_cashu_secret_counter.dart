import 'package:objectbox/objectbox.dart';

@Entity()
class DbCashuSecretCounter {
  @Id()
  int dbId = 0;

  @Unique()
  @Index()
  @Property()
  final String mintUrl;

  @Unique()
  @Index()
  @Property()
  final String keysetId;

  @Property(signed: true)
  final int counter;

  DbCashuSecretCounter({
    required this.mintUrl,
    required this.keysetId,
    required this.counter,
  });
}
