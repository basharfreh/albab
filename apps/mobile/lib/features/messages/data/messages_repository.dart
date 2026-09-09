import 'package:albab_core/albab_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UC-40 — conversations and their messages. Both list endpoints are paginated envelopes on
/// the backend (docs/API.md), but neither this screen nor the chat view implements infinite
/// scroll — a single `page_size` at the API's own max of 50 (brief §8) covers a
/// single-city marketplace's conversation/message volumes, matching the same "one page is
/// enough for a summary list" call P10's stats screen makes for its per-listing breakdown.
class MessagesRepository {
  MessagesRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<List<Conversation>> fetchConversations() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/conversations/',
        queryParameters: const {'page_size': 50},
      );
      final paginated = Paginated<Conversation>.fromJson(
        response.data!,
        (json) => Conversation.fromJson(json! as Map<String, dynamic>),
      );
      return paginated.results;
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// `GET /conversations/{id}/messages/` also marks the counterpart's unread messages read
  /// as a side effect (docs/API.md) — every poll/open of this screen clears the unread badge
  /// for this conversation, matching UC-40's "unread badge" being per-conversation, not
  /// per-message.
  Future<List<Message>> fetchMessages(int conversationId) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/conversations/$conversationId/messages/',
        queryParameters: const {'page_size': 50},
      );
      final paginated = Paginated<Message>.fromJson(
        response.data!,
        (json) => Message.fromJson(json! as Map<String, dynamic>),
      );
      return paginated.results;
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<Message> sendMessage(int conversationId, String body) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/conversations/$conversationId/messages/',
        data: {'body': body},
      );
      return Message.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }
}

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) => MessagesRepository(ref));
