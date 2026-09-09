import 'package:freezed_annotation/freezed_annotation.dart';

import 'message.dart';
import 'user.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

/// The nested `listing` block on a [Conversation] — `ConversationListingSerializer` on the
/// backend, deliberately smaller than the full [Listing] model.
@freezed
abstract class ConversationListing with _$ConversationListing {
  const factory ConversationListing({
    required int id,
    required String title,
    String? coverThumbnail,
  }) = _ConversationListing;

  factory ConversationListing.fromJson(Map<String, dynamic> json) =>
      _$ConversationListingFromJson(json);
}

@freezed
abstract class Conversation with _$Conversation {
  const factory Conversation({
    required int id,
    required ConversationListing listing,
    required User counterpart,
    Message? lastMessage,
    @Default(0) int unreadCount,
    DateTime? lastMessageAt,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);
}
