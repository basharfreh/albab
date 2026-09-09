import 'package:albab_core/albab_core.dart';

/// `{total, delta_30d}` — one line of `GET /admin/kpis/` (docs/API.md). Plain classes, not
/// freezed: these are dashboard-only DTOs, never shared with `apps/mobile`, so the extra
/// build_runner step `albab_core`'s shared models pay for buys nothing here.
class AdminKpi {
  const AdminKpi({required this.total, required this.delta30d});

  final int total;
  final int delta30d;

  factory AdminKpi.fromJson(Map<String, dynamic> json) =>
      AdminKpi(total: json['total'] as int, delta30d: json['delta_30d'] as int);
}

/// `GET /admin/kpis/` (UC-50).
class AdminKpis {
  const AdminKpis({
    required this.totalUsers,
    required this.totalListings,
    required this.forSale,
    required this.forRent,
  });

  final AdminKpi totalUsers;
  final AdminKpi totalListings;
  final AdminKpi forSale;
  final AdminKpi forRent;

  factory AdminKpis.fromJson(Map<String, dynamic> json) => AdminKpis(
    totalUsers: AdminKpi.fromJson(json['total_users'] as Map<String, dynamic>),
    totalListings: AdminKpi.fromJson(json['total_listings'] as Map<String, dynamic>),
    forSale: AdminKpi.fromJson(json['for_sale'] as Map<String, dynamic>),
    forRent: AdminKpi.fromJson(json['for_rent'] as Map<String, dynamic>),
  );
}

/// One day of `GET /admin/analytics/visits/` (UC-51).
class VisitsPoint {
  const VisitsPoint({required this.date, required this.views, required this.contacts});

  final DateTime date;
  final int views;
  final int contacts;

  factory VisitsPoint.fromJson(Map<String, dynamic> json) => VisitsPoint(
    date: DateTime.parse(json['date'] as String),
    views: json['views'] as int,
    contacts: json['contacts'] as int,
  );
}

/// One slice of `GET /admin/analytics/by-type/` (UC-52) — pin/pie colors come from
/// [AppPropertyTypeColors] via [propertyType], never a separate palette.
class ByTypeSlice {
  const ByTypeSlice({required this.propertyType, required this.count});

  final PropertyType propertyType;
  final int count;

  factory ByTypeSlice.fromJson(Map<String, dynamic> json) => ByTypeSlice(
    propertyType: PropertyType.values.byName(json['property_type'] as String),
    count: json['count'] as int,
  );
}

/// One row of `GET /admin/reports/` (UC-58) — only the fields التقارير's table/actions
/// need, not the full nested `listing`/`reporter` objects the backend actually returns.
class AdminReport {
  const AdminReport({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.reporterName,
    required this.reason,
    required this.note,
    required this.isOpen,
    required this.createdAt,
  });

  final int id;
  final int listingId;
  final String listingTitle;
  final String reporterName;
  final String reason;
  final String note;
  final bool isOpen;
  final DateTime createdAt;

  factory AdminReport.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'] as Map<String, dynamic>;
    final reporter = json['reporter'] as Map<String, dynamic>;
    return AdminReport(
      id: json['id'] as int,
      listingId: listing['id'] as int,
      listingTitle: listing['title'] as String,
      reporterName: reporter['name'] as String,
      reason: json['reason'] as String,
      note: json['note'] as String? ?? '',
      isOpen: json['status'] == 'open',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
