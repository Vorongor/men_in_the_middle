import '../models/hardware_item.dart';
import '../models/news_article.dart';
import '../models/software_item.dart';

/// Typed route arguments for screens that need a target index / id.
///
/// Used until Step 06 introduces a real [Target] model from the DB.
class TargetDetailArgs {
  final int contractId;
  const TargetDetailArgs({required this.contractId});
}

/// Typed route arguments for Store item detail screen.
class StoreItemArgs {
  final SoftwareItem item;
  const StoreItemArgs({required this.item});
}

/// Typed route arguments for Market item detail screen.
class MarketItemArgs {
  final HardwareItem item;
  const MarketItemArgs({required this.item});
}

/// Typed route arguments for Workshop item detail screen.
class WorkshopItemArgs {
  final String itemType; // 'software' or 'hardware'
  final int id; // DB primary key in user_software / user_hardware
  const WorkshopItemArgs({required this.itemType, required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkshopItemArgs &&
          runtimeType == other.runtimeType &&
          itemType == other.itemType &&
          id == other.id;

  @override
  int get hashCode => itemType.hashCode ^ id.hashCode;
}

/// Typed route arguments for News item detail screen.
class NewsItemArgs {
  const NewsItemArgs({required this.article});
  final NewsArticle article;
}

/// Typed route arguments for Attack Prep screen.
class AttackPrepArgs {
  final int contractId;
  const AttackPrepArgs({required this.contractId});
}
