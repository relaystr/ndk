import 'package:objectbox/objectbox.dart';

@Entity()
class DbKeyValue {
  @Id()
  int dbId = 0;

  String key;

  String? value;

  DbKeyValue({required this.key, this.value});
}
