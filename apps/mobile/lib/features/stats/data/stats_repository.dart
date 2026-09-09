import 'package:albab_core/albab_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One day of `GET /me/listings/stats/`'s `series` (docs/API.md).
class DailyStat {
  const DailyStat({required this.date, required this.views, required this.contacts});

  factory DailyStat.fromJson(Map<String, dynamic> json) => DailyStat(
    date: DateTime.parse(json['date'] as String),
    views: json['views'] as int,
    contacts: json['contacts'] as int,
  );

  final DateTime date;
  final int views;
  final int contacts;
}

/// `totals.by_channel` — call/whatsapp/message counts over the same window (P10 addition,
/// docs/API.md — `ListingDailyStat` itself has no per-kind breakdown, only `ListingEvent`
/// does, so the backend computes this straight from events rather than the daily rollup).
class ContactsByChannel {
  const ContactsByChannel({required this.call, required this.whatsapp, required this.message});

  factory ContactsByChannel.fromJson(Map<String, dynamic> json) => ContactsByChannel(
    call: json['call'] as int? ?? 0,
    whatsapp: json['whatsapp'] as int? ?? 0,
    message: json['message'] as int? ?? 0,
  );

  final int call;
  final int whatsapp;
  final int message;
}

/// `GET /me/listings/stats/?days=` — brief P10 item 3's 30-day chart + totals.
class OwnerStats {
  const OwnerStats({
    required this.series,
    required this.totalViews,
    required this.totalContacts,
    required this.byChannel,
  });

  factory OwnerStats.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>;
    return OwnerStats(
      series: (json['series'] as List)
          .map((e) => DailyStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalViews: totals['views'] as int,
      totalContacts: totals['contacts'] as int,
      byChannel: ContactsByChannel.fromJson(totals['by_channel'] as Map<String, dynamic>),
    );
  }

  final List<DailyStat> series;
  final int totalViews;
  final int totalContacts;
  final ContactsByChannel byChannel;
}

/// UC-37 — brief P10 item 3. The chart/totals come from `/me/listings/stats/`; the
/// per-listing breakdown reuses `MyListingSerializer`'s `views_count`/`contacts_count`
/// (`/me/listings/`) rather than a second stats endpoint, since P10 already added those
/// fields for the "عقاراتي" screen — see PROGRESS.md.
class StatsRepository {
  StatsRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<OwnerStats> fetchOwnerStats({int days = 30}) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/me/listings/stats/',
        queryParameters: {'days': days},
      );
      return OwnerStats.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// The per-listing breakdown — every one of the owner's listings, most-viewed first, one
  /// page (`page_size` at the API's own max of 50, brief §8) since this is a summary screen,
  /// not a paginated list in its own right.
  Future<List<Listing>> fetchPerListingBreakdown() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/me/listings/',
        queryParameters: const {'page_size': 50},
      );
      final paginated = Paginated<Listing>.fromJson(
        response.data!,
        (json) => Listing.fromJson(json! as Map<String, dynamic>),
      );
      final results = [...paginated.results]
        ..sort((a, b) => (b.viewsCount ?? 0).compareTo(a.viewsCount ?? 0));
      return results;
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }
}

final statsRepositoryProvider = Provider<StatsRepository>((ref) => StatsRepository(ref));
