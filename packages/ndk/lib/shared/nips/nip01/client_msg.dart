import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/filter.dart';

import '../../../data_layer/models/nip_01_event_model.dart';

/// this class is used to send messages from the client to the relay
///
/// "EVENT", &lt;event JSON as defined above&gt;
/// "REQ", &lt;subscription_id&gt;, &lt;filters1&gt;, &lt;filters2&gt;, ...
/// "CLOSE", &lt;subscription_id&gt;
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
    if (type == ClientMsgType.kEvent) {
      if (event == null) {
        throw Exception("event is required for type EVENT");
      }
    }

    if (type == ClientMsgType.kReq) {
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

    if (type == ClientMsgType.kClose) {
      if (id == null) {
        throw Exception("id is required for type CLOSE");
      }
    }
    if (type == ClientMsgType.kCount) {
      throw Exception("COUNT is not implemented yet");
    }
    if (type == ClientMsgType.kAuth) {
      if (event == null) {
        throw Exception("event is required for type AUTH");
      }
    }
  }

  List<Object> _eventToJson() {
    final model = Nip01EventModel.fromEntity(event!);
    return [type, model.toJson()];
  }

  List _reqToJson() {
    List<dynamic> json = [type, id];
    for (var filter in filters!) {
      json.add(filter.toMap());
    }
    return json;
  }

  List<String?> _closeToJson() {
    return [type, id];
  }

  dynamic toJson() {
    switch (type) {
      case ClientMsgType.kEvent:
        return _eventToJson();
      case ClientMsgType.kReq:
        return _reqToJson();
      case ClientMsgType.kClose:
        return _closeToJson();
      case ClientMsgType.kAuth:
        return _eventToJson();
      case ClientMsgType.kCount:
        throw Exception("COUNT is not implemented yet");
    }
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

class ClientMsgType {
  static const String kReq = "REQ";
  static const String kClose = "CLOSE";
  static const String kEvent = "EVENT";
  static const String kCount = "COUNT";
  static const String kAuth = "AUTH";
  static const String kNegOpen = "NEG-OPEN";
  static const String kNegMsg = "NEG-MSG";
  static const String kNegClose = "NEG-CLOSE";
}
