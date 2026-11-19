/// TLV (Type-Length-Value) parsing for NIP-19
class Nip19TLV {
  final int type;
  final int length;
  final List<int> value;

  Nip19TLV(this.type, this.length, this.value);

  static List<Nip19TLV> parseTLV(List<int> data) {
    List<Nip19TLV> result = [];
    int index = 0;

    while (index < data.length) {
      // Check if we have enough bytes for type and length
      if (index + 2 > data.length) {
        throw FormatException('Incomplete TLV data');
      }

      // Read type (1 byte)
      int type = data[index];
      index++;

      // Read length (1 byte)
      int length = data[index];
      index++;

      // Check if we have enough bytes for value
      if (index + length > data.length) {
        throw FormatException('TLV value length exceeds available data');
      }

      // Read value
      List<int> value = data.sublist(index, index + length);
      index += length;

      result.add(Nip19TLV(type, length, value));
    }

    return result;
  }
}
