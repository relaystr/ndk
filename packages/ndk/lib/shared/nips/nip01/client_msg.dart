import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/filter.dart';

/// this class is used to send messages from the client to the relay
///
/// "EVENT", <event JSON as defined above>
/// "REQ", <subscription_id>, <filters1>, <filters2>, ...
/// "CLOSE", <subscription_id>
///
///
class ClientMsg {
  String type;
  String? id;
  List<Filter>? filters;
  Nip01Event? event;

  ClientMsg(
    this.type, {
    this.id,
    this.event,
    this.filters,
  }) {
    // verify based on type
    if (type == ClientMsgType.EVENT) {
      if (event == null) {
        throw Exception("event is required for type EVENT");
      }
    }

    if (type == ClientMsgType.REQ) {
      if (filters == null) {
        throw Exception("filters are required for type REQ");
      }

      if (filters!.isEmpty) {
        throw Exception("filters are required for type REQ");
      }
      if (id == null) {
        throw Exception("id is required for type REQ");
      }
    }

    if (type == ClientMsgType.CLOSE) {
      if (id == null) {
        throw Exception("id is required for type CLOSE");
      }
    }
    if (type == ClientMsgType.COUNT) {
      throw Exception("COUNT is not implemented yet");
    }
    if (type == ClientMsgType.AUTH) {
      if (event == null) {
        throw Exception("event is required for type AUTH");
      }
    }
  }

  _eventToJson() {
    return [type, event!.toJson()];
  }

  _reqToJson() {
    List<dynamic> json = [type, id];
    for (var filter in filters!) {
      json.add(filter.toMap());
    }
    return json;
  }

  _closeToJson() {
    return [type, id];
  }

  toJson() {
    switch (type) {
      case ClientMsgType.EVENT:
        return _eventToJson();
      case ClientMsgType.REQ:
        return _reqToJson();
      case ClientMsgType.CLOSE:
        return _closeToJson();
      case ClientMsgType.AUTH:
        return _eventToJson();
      case ClientMsgType.COUNT:
        throw Exception("COUNT is not implemented yet");
    }
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

class ClientMsgType {
  static const String REQ = "REQ";
  static const String CLOSE = "CLOSE";
  static const String EVENT = "EVENT";
  static const String COUNT = "COUNT";
  static const String AUTH = "AUTH";
}
