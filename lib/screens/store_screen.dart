import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/software_item.dart';
import '../models/user_software.dart';
import '../repos/catalog_repository.dart';
import '../repos/inventory_repository.dart';
import '../state/player_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/async_value_ext.dart';
import '../utils/route_args.dart';
import '../utils/routes.dart';
import '../utils/wanted_effects.dart';
import '../widgets/game_scaffold.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  late final Future<(List<SoftwareItem>, List<OwnedSoftware>)> _loadFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final profile = ref.read(playerSessionProvider).valueOrNull?.profile;
    if (profile != null) {
      final catalogRepo = ref.read(catalogRepositoryProvider);
      final inventoryRepo = ref.read(inventoryRepositoryProvider);
      setState(() {
        _loadFuture = Future.wait([
          catalogRepo.allSoftwareItems(),
          inventoryRepo.fetchOwnedSoftware(profile.id!),
        ]).then((res) => (res[0] as List<SoftwareItem>, res[1] as List<OwnedSoftware>));
      });
    } else {
      setState(() {
        _loadFuture = Future.value((const <SoftwareItem>[], const <OwnedSoftware>[]));
      });
    }
  }

  String _getSoftTypeName(int typeId) {
    switch (typeId) {
      case 1:
        return 'Phishing';
      case 2:
        return 'Bruteforce';
      case 3:
        return 'DDoS';
      case 4:
        return 'Exploit';
      default:
        return 'Utility';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(playerSessionProvider);
    final profile = sessionState.valueOrNull?.profile;

    if (profile == null) {
      return GameScaffold(
        screenNum: '6.1',
        screenName: 'GREY STORE',
        body: Center(
          child: Text(
            'Not authenticated',
            style: AppTextStyles.body(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return GameScaffold(
      screenNum: '6.1',
      screenName: 'GREY STORE',
      body: FutureBuilder<(List<SoftwareItem>, List<OwnedSoftware>)>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading catalog: ${snapshot.error}',
                style: AppTextStyles.body(color: AppColors.alert),
              ),
            );
          }

          final (catalog, owned) = snapshot.data ?? (const <SoftwareItem>[], const <OwnedSoftware>[]);

          return ListView.builder(
            itemCount: catalog.length,
            itemBuilder: (context, i) {
              final item = catalog[i];
              final isOwned = owned.any((o) => o.catalogItem.id == item.id);
              final levelLocked = profile.levelId < item.reqLevel;
              final trustLocked = profile.blackTrust < item.reqBlackTrust;
              final isLocked = levelLocked || trustLocked;

              String lockReason = '';
              if (levelLocked) {
                lockReason = 'Lvl ${item.reqLevel} req.';
              } else if (trustLocked) {
                lockReason = 'Black market · Trust ${item.reqBlackTrust} req.';
              }

              return _StoreRow(
                item: item,
                typeName: _getSoftTypeName(item.softTypeId),
                isOwned: isOwned,
                isLocked: isLocked,
                lockReason: lockReason,
                effectivePrice: WantedEffects.effectivePrice(item.basePrice, profile.wanted),
                isRiskTaxed: WantedEffects.isRiskTaxed(profile.wanted),
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    Routes.storeItem,
                    arguments: StoreItemArgs(item: item),
                  );
                  _refreshData();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.item,
    required this.typeName,
    required this.isOwned,
    required this.isLocked,
    required this.lockReason,
    required this.effectivePrice,
    required this.isRiskTaxed,
    required this.onTap,
  });

  final SoftwareItem item;
  final String typeName;
  final bool isOwned;
  final bool isLocked;
  final String lockReason;
  final int effectivePrice;
  final bool isRiskTaxed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final opacity = isLocked ? 0.35 : 1.0;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Opacity(
          opacity: opacity,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isLocked ? AppColors.surfaceError : AppColors.surfaceSuccess,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isLocked ? AppColors.alert.withValues(alpha: 0.2) : AppColors.borderSuccess,
                  ),
                ),
                child: Icon(
                  isLocked ? Icons.lock_outline : Icons.terminal,
                  color: isLocked ? AppColors.alert : AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.dataMono(color: AppColors.text).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      typeName.toUpperCase(),
                      style: AppTextStyles.caption(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceError,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppColors.alert.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    lockReason.toUpperCase(),
                    style: AppTextStyles.caption(color: AppColors.alert).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                )
              else if (isOwned)
                Text(
                  'OWNED',
                  style: AppTextStyles.dataMono(color: AppColors.textMuted).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$effectivePrice EPTS',
                      style: AppTextStyles.dataMono(color: AppColors.primary),
                    ),
                    if (isRiskTaxed)
                      Text(
                        'RISK TAX',
                        style: AppTextStyles.caption(color: AppColors.warning).copyWith(
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppColors.iconLow, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
