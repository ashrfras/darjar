import 'dart:typed_data';

import 'package:protobuf/protobuf.dart';

/// The before/after Firestore documents carried by a direct Eventarc event.
class FirestoreDocumentChange {
  const FirestoreDocumentChange({required this.value, required this.oldValue});

  const FirestoreDocumentChange.empty() : value = const {}, oldValue = const {};

  final Map<String, Object?> value;
  final Map<String, Object?> oldValue;

  factory FirestoreDocumentChange.fromBuffer(Uint8List bytes) {
    var value = const <String, Object?>{};
    var oldValue = const <String, Object?>{};
    final reader = CodedBufferReader(bytes);
    while (!reader.isAtEnd()) {
      final tag = reader.readTag();
      switch (tag >>> 3) {
        case 1:
          value = _document(reader.readBytes());
        case 2:
          oldValue = _document(reader.readBytes());
        default:
          reader.skipField(tag);
      }
    }
    return FirestoreDocumentChange(value: value, oldValue: oldValue);
  }
}

Map<String, Object?> _document(Uint8List bytes) {
  final fields = <String, Object?>{};
  final reader = CodedBufferReader(bytes);
  while (!reader.isAtEnd()) {
    final tag = reader.readTag();
    if (tag >>> 3 == 2) {
      final entry = _mapEntry(reader.readBytes());
      if (entry.$1.isNotEmpty) fields[entry.$1] = entry.$2;
    } else {
      reader.skipField(tag);
    }
  }
  return fields;
}

(String, Object?) _mapEntry(Uint8List bytes) {
  var key = '';
  Object? value;
  final reader = CodedBufferReader(bytes);
  while (!reader.isAtEnd()) {
    final tag = reader.readTag();
    switch (tag >>> 3) {
      case 1:
        key = reader.readString();
      case 2:
        value = _value(reader.readBytes());
      default:
        reader.skipField(tag);
    }
  }
  return (key, value);
}

Object? _value(Uint8List bytes) {
  final reader = CodedBufferReader(bytes);
  while (!reader.isAtEnd()) {
    final tag = reader.readTag();
    switch (tag >>> 3) {
      case 1:
        return reader.readBool();
      case 2:
        return reader.readInt64().toInt();
      case 3:
        return reader.readDouble();
      case 6:
        return _map(reader.readBytes());
      case 17:
        return reader.readString();
      case 9:
        return _array(reader.readBytes());
      case 10:
        return _timestamp(reader.readBytes());
      case 11:
        reader.readEnum();
        return null;
      default:
        reader.skipField(tag);
    }
  }
  return null;
}

Map<String, Object?> _map(Uint8List bytes) {
  final fields = <String, Object?>{};
  final reader = CodedBufferReader(bytes);
  while (!reader.isAtEnd()) {
    final tag = reader.readTag();
    if (tag >>> 3 == 1) {
      final entry = _mapEntry(reader.readBytes());
      if (entry.$1.isNotEmpty) fields[entry.$1] = entry.$2;
    } else {
      reader.skipField(tag);
    }
  }
  return fields;
}

DateTime _timestamp(Uint8List bytes) {
  var seconds = 0;
  var nanos = 0;
  final reader = CodedBufferReader(bytes);
  while (!reader.isAtEnd()) {
    final tag = reader.readTag();
    switch (tag >>> 3) {
      case 1:
        seconds = reader.readInt64().toInt();
      case 2:
        nanos = reader.readInt32();
      default:
        reader.skipField(tag);
    }
  }
  return DateTime.fromMicrosecondsSinceEpoch(
    seconds * Duration.microsecondsPerSecond + nanos ~/ 1000,
    isUtc: true,
  );
}

List<Object?> _array(Uint8List bytes) {
  final values = <Object?>[];
  final reader = CodedBufferReader(bytes);
  while (!reader.isAtEnd()) {
    final tag = reader.readTag();
    if (tag >>> 3 == 1) {
      values.add(_value(reader.readBytes()));
    } else {
      reader.skipField(tag);
    }
  }
  return values;
}
