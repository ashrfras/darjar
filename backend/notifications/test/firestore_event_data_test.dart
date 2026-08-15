import 'dart:convert';
import 'dart:typed_data';

import 'package:darjar_notifications/src/firestore_event_data.dart';
import 'package:test/test.dart';

void main() {
  test('decodes string and string-array fields from Firestore event data', () {
    final oldDocument = _document({
      'likedBy': _arrayValue(['neighbor-a']),
      'status': _stringValue('partial'),
    });
    final currentDocument = _document({
      'likedBy': _arrayValue(['neighbor-a', 'neighbor-b']),
      'status': _stringValue('paid'),
    });
    final event = Uint8List.fromList([
      ..._messageField(1, currentDocument),
      ..._messageField(2, oldDocument),
    ]);

    final change = FirestoreDocumentChange.fromBuffer(event);

    expect(change.oldValue['likedBy'], ['neighbor-a']);
    expect(change.value['likedBy'], ['neighbor-a', 'neighbor-b']);
    expect(change.oldValue['status'], 'partial');
    expect(change.value['status'], 'paid');
  });

  test('decodes numeric, timestamp, and map activity payload fields', () {
    final currentDocument = _document({
      'amount': _integerValue(450),
      'createdAt': _timestampValue(1723723200),
      'payload': _mapValue({'title': _stringValue('التنظيف')}),
    });
    final event = Uint8List.fromList(_messageField(1, currentDocument));

    final change = FirestoreDocumentChange.fromBuffer(event);

    expect(change.value['amount'], 450);
    expect(change.value['createdAt'], DateTime.utc(2024, 8, 15, 12));
    expect(change.value['payload'], {'title': 'التنظيف'});
  });
}

List<int> _document(Map<String, List<int>> fields) {
  return [
    for (final field in fields.entries)
      ..._messageField(2, [
        ..._stringField(1, field.key),
        ..._messageField(2, field.value),
      ]),
  ];
}

List<int> _stringValue(String value) => _stringField(17, value);

List<int> _integerValue(int value) => [..._varint(2 << 3), ..._varint(value)];

List<int> _timestampValue(int seconds) {
  return _messageField(10, [..._varint(1 << 3), ..._varint(seconds)]);
}

List<int> _mapValue(Map<String, List<int>> values) {
  return _messageField(6, [
    for (final entry in values.entries)
      ..._messageField(1, [
        ..._stringField(1, entry.key),
        ..._messageField(2, entry.value),
      ]),
  ]);
}

List<int> _arrayValue(List<String> values) {
  return _messageField(9, [
    for (final value in values) ..._messageField(1, _stringValue(value)),
  ]);
}

List<int> _stringField(int number, String value) {
  return _messageField(number, utf8.encode(value));
}

List<int> _messageField(int number, List<int> value) {
  return [..._varint((number << 3) | 2), ..._varint(value.length), ...value];
}

List<int> _varint(int value) {
  final bytes = <int>[];
  var remaining = value;
  do {
    var byte = remaining & 0x7f;
    remaining >>= 7;
    if (remaining != 0) byte |= 0x80;
    bytes.add(byte);
  } while (remaining != 0);
  return bytes;
}
