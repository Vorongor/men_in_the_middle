import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hardware_item.dart';
import '../models/user_hardware.dart';
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

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  late Future<(List<HardwareItem>, List<OwnedHardware>)> _loadFuture;
  String _selectedType = 'ALL';

  final List<String> _types = ['ALL', 'CPU', 'RAM', 'NET', 'GPU'];

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
          catalogRepo.allHardwareItems(),
          inventoryRepo.fetchOwnedHardware(profile.id!),
        ]).then((res) => (res[0] as List<HardwareItem>, res[1] as List<OwnedHardware>));
      });
    } else {
      setState(() {
        _loadFuture = Future.value((<HardwareItem>[], <OwnedHardware>[]));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(playerSessionProvider);
    final profile = sessionState.valueOrNull?.profile;

    if (profile == null) {
      return const GameScaffold(
        screenNum: '8.1',
        screenName: 'BLACK MARKET',
        body: Center(
          child: Text('Not authenticated', style: TextStyle(color: Colors.white60)),
        ),
      );
    }

    return GameScaffold(
      screenNum: '8.1',
      screenName: 'BLACK MARKET',
      body: Column(
        children: [
          // Filter chips header
          Container(
            height: 48,
            color: AppColors.surface,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _types.length,
              itemBuilder: (context, i) {
                final type = _types[i];
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(
                      type,
                      style: AppTextStyles.caption().copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.bg : AppColors.textHigh,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.bg,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = type);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(),

          Expanded(
            child: FutureBuilder<(List<HardwareItem>, List<OwnedHardware>)>(
              future: _loadFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading market: ${snapshot.error}',
                      style: AppTextStyles.body(color: AppColors.alert),
                    ),
                  );
                }

                var (catalog, owned) = snapshot.data ?? (<HardwareItem>[], <OwnedHardware>[]);

                // Apply type filter
                if (_selectedType != 'ALL') {
                  catalog = catalog.where((i) => i.hwType == _selectedType).toList();
                }

                if (catalog.isEmpty) {
                  return Center(
                    child: Text(
                      'NO HARDWARE REGISTERED',
                      style: AppTextStyles.body(color: AppColors.textMuted),
                    ),
                  );
                }

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

                    return _MarketRow(
                      item: item,
                      isOwned: isOwned,
                      isLocked: isLocked,
                      lockReason: lockReason,
                      effectivePrice: WantedEffects.effectivePrice(item.basePrice, profile.wanted),
                      isRiskTaxed: WantedEffects.isRiskTaxed(profile.wanted),
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          Routes.marketItem,
                          arguments: MarketItemArgs(item: item),
                        );
                        _refreshData();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketRow extends StatelessWidget {
  const _MarketRow({
    required this.item,
    required this.isOwned,
    required this.isLocked,
    required this.lockReason,
    required this.effectivePrice,
    required this.isRiskTaxed,
    required this.onTap,
  });

  final HardwareItem item;
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
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
                    color: isLocked ? AppColors.alert.withValues(alpha: 0.3) : AppColors.borderSuccess,
                  ),
                ),
                child: Icon(
                  isLocked ? Icons.lock_outline : Icons.dns,
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
                      '${item.hwType}  ·  COMPUTE POWER: +${item.initComputePower}',
                      style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceError,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.alert.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    lockReason.toUpperCase(),
                    style: AppTextStyles.caption(color: AppColors.alert).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (isOwned)
                Text(
                  'OWNED',
                  style: AppTextStyles.dataMono(color: AppColors.textMuted).copyWith(
                    fontSize: 12,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$effectivePrice EPTS',
                      style: AppTextStyles.dataMono(color: AppColors.primary).copyWith(
                        fontSize: 13,
                      ),
                    ),
                    if (isRiskTaxed)
                      Text(
                        'RISK TAX',
                        style: AppTextStyles.caption(color: AppColors.warning).copyWith(
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
