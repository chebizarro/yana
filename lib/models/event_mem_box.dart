import 'package:dart_ndk/nips/nip01/event.dart';

import '../nostr/relay.dart';
import '../utils/find_event_interface.dart';

/// a memory event box
/// use to hold event received from relay and offer event List to ui
class EventMemBox implements FindEventInterface {
  List<Nip01Event> _eventList = [];

  Map<String, Nip01Event> _idMap = {};

  bool sortAfterAdd;

  EventMemBox({this.sortAfterAdd = true}) {}

  @override
  List<Nip01Event> findEvent(String str, {int? limit = 5}) {
    List<Nip01Event> list = [];
    for (var event in _eventList) {
      if (event.content.contains(str)) {
        list.add(event);

        if (limit != null && list.length >= limit) {
          break;
        }
      }
    }
    return list;
  }

  Nip01Event? get newestEvent {
    if (_eventList.isEmpty) {
      return null;
    }
    return _eventList.first;
  }

  Nip01Event? get oldestEvent {
    if (_eventList.isEmpty) {
      return null;
    }
    return _eventList.last;
  }

  // find event oldest createdAt by relay
  OldestCreatedAtByRelayResult oldestCreatedAtByRelay(List<Relay> relays,
      [int? initTime]) {
    OldestCreatedAtByRelayResult result = OldestCreatedAtByRelayResult();
    Map<String, Relay> relayMap = {};
    for (var relay in relays) {
      relayMap[relay.url] = relay;
    }

    var length = _eventList.length;
    for (var index = length - 1; index > -1; index--) {
      var event = _eventList[index];
      for (var source in event.sources) {
        if (relayMap[source] != null) {
          // log("$source findCreatedAt $length $index ${length - index}");
          result.createdAtMap[source] = event.createdAt;
          relayMap.remove(source);
        }
      }

      if (relayMap.isEmpty) {
        break;
      }
    }

    if (relayMap.isNotEmpty && initTime != null) {
      for (var relay in relayMap.values) {
        result.createdAtMap[relay.url] = initTime;
      }
    }

    // count av createdAt
    var it = result.createdAtMap.values;
    var relayNum = it.length;
    double counter = 0;
    for (var value in it) {
      counter += value;
    }
    result.avCreatedAt = relayNum>0 ? counter ~/ relayNum : 0;

    return result;
  }

  void sort() {
    _eventList.sort((event1, event2) {
      return event2.createdAt - event1.createdAt;
    });
  }

  bool delete(String id) {
    if (_idMap[id] == null) {
      return false;
    }

    _idMap.remove(id);
    _eventList.removeWhere((element) => element.id == id);

    return true;
  }

  bool add(Nip01Event event) {
    var oldEvent = _idMap[event.id];

    if (oldEvent != null) {
      if (event.sources.isNotEmpty &&
          !oldEvent.sources.contains(event.sources[0])) {
        oldEvent.sources.add(event.sources[0]);
        return true;
      }
    }

    _idMap[event.id] = event;
    _eventList.add(event);
    if (sortAfterAdd) {
      sort();
    }
    return true;
  }

  bool addList(List<Nip01Event> list) {
    bool added = false;
    for (var event in list) {
      var oldEvent = _idMap[event.id];
      if (oldEvent == null) {
        _idMap[event.id] = event;
        _eventList.add(event);
        added = true;
      } else {
        if (event.sources.isNotEmpty &&
            !oldEvent.sources.contains(event.sources[0])) {
          oldEvent.sources.add(event.sources[0]);
        }
      }
    }

    if (added && sortAfterAdd) {
      sort();
    }

    return added;
  }

  void addBox(EventMemBox b) {
    var all = b.all();
    addList(all);
  }

  bool isEmpty() {
    return _eventList.isEmpty;
  }

  int length() {
    return _eventList.length;
  }

  List<Nip01Event> all() {
    return _eventList;
  }

  bool containsId(String id) {
    return _idMap.containsKey(id);
  }

  List<Nip01Event> listByPubkey(String pubkey) {
    List<Nip01Event> list = [];
    for (var event in _eventList) {
      if (event.pubKey == pubkey) {
        list.add(event);
      }
    }
    return list;
  }

  List<Nip01Event> suList(int start, int limit) {
    var length = _eventList.length;
    if (start > length) {
      return [];
    }
    if (start + limit > length) {
      return _eventList.sublist(start, length);
    }
    return _eventList.sublist(start, limit);
  }

  Nip01Event? get(int index) {
    if (_eventList.length < index) {
      return null;
    }

    return _eventList[index];
  }

  void clear() {
    _eventList.clear();
    _idMap.clear();
  }
}

class OldestCreatedAtByRelayResult {
  Map<String, int> createdAtMap = {};

  int avCreatedAt = 0;
}
