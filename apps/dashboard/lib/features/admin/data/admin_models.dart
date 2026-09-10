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

/// One row of `/admin/neighborhoods/` (UC-59) — unlike the public `Neighborhood` model
/// (`albab_core`, active-only), this also carries `isActive`/`sortOrder`, which only the
/// admin ever sees or edits.
class AdminNeighborhood {
  const AdminNeighborhood({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.slug,
    required this.centerLat,
    required this.centerLng,
    required this.isActive,
    required this.sortOrder,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String slug;
  final String centerLat;
  final String centerLng;
  final bool isActive;
  final int sortOrder;

  factory AdminNeighborhood.fromJson(Map<String, dynamic> json) => AdminNeighborhood(
    id: json['id'] as int,
    nameAr: json['name_ar'] as String,
    nameEn: json['name_en'] as String? ?? '',
    slug: json['slug'] as String,
    centerLat: '${json['center_lat']}',
    centerLng: '${json['center_lng']}',
    isActive: json['is_active'] as bool,
    sortOrder: json['sort_order'] as int,
  );

  Map<String, dynamic> toJson() => {
    'name_ar': nameAr,
    'name_en': nameEn,
    'slug': slug,
    'center_lat': centerLat,
    'center_lng': centerLng,
    'is_active': isActive,
    'sort_order': sortOrder,
  };
}

/// `GET`/`PATCH /admin/settings/quotas/` (UC-59) — max *active* listings per role, read live
/// by the backend's `services/quota.py` (no longer a hardcoded constant as of P11).
class QuotaSettings {
  const QuotaSettings({required this.seeker, required this.owner, required this.agency});

  final int seeker;
  final int owner;
  final int agency;

  factory QuotaSettings.fromJson(Map<String, dynamic> json) => QuotaSettings(
    seeker: json['seeker'] as int,
    owner: json['owner'] as int,
    agency: json['agency'] as int,
  );
}

/// One row of `/admin/settings/pages/` (UC-59) — generic static content (about/terms/...).
class AdminStaticPage {
  const AdminStaticPage({
    required this.id,
    required this.slug,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
  });

  final int id;
  final String slug;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;

  factory AdminStaticPage.fromJson(Map<String, dynamic> json) => AdminStaticPage(
    id: json['id'] as int,
    slug: json['slug'] as String,
    titleAr: json['title_ar'] as String,
    titleEn: json['title_en'] as String? ?? '',
    bodyAr: json['body_ar'] as String? ?? '',
    bodyEn: json['body_en'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'title_ar': titleAr,
    'title_en': titleEn,
    'body_ar': bodyAr,
    'body_en': bodyEn,
  };
}
