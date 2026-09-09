import 'package:freezed_annotation/freezed_annotation.dart';

import 'user.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
abstract class Message with _$Message {
  const factory Message({
    required int id,
    required int conversation,
    required User sender,
    required String body,
    DateTime? readAt,
    required DateTime createdAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}
