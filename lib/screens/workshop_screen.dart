import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_hardware.dart';
import '../models/user_software.dart';
import '../repos/inventory_repository.dart';
import '../state/player_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/async_value_ext.dart';
import '../utils/route_args.dart';
import '../utils/routes.dart';
import '../widgets/game_scaffold.dart';

class WorkshopScreen extends ConsumerStatefulWidget {
  const WorkshopScreen({super.key});

  @override
  ConsumerState<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends ConsumerState<WorkshopScreen> {
  late Future<(List<OwnedSoftware>, List<OwnedHardware>)> _loadFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final profile = ref.read(playerSessionProvider).valueOrNull?.profile;
    if (profile != null) {
      final repo = ref.read(inventoryRepositoryProvider);
      setState(() {
        _loadFuture = Future.wait([
          repo.fetchOwnedSoftware(profile.id!),
          repo.fetchOwnedHardware(profile.id!),
        ]).then((res) => (res[0] as List<OwnedSoftware>, res[1] as List<OwnedHardware>));
      });
    } else {
      setState(() {
        _loadFuture = Future.value((<OwnedSoftware>[], <OwnedHardware>[]));
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
      return const GameScaffold(
        screenNum: '9.1',
        screenName: 'WORKSHOP',
        body: Center(
          child: Text('Not authenticated', style: TextStyle(color: Colors.white60)),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: GameScaffold(
        screenNum: '9.1',
        screenName: 'WORKSHOP',
        body: Column(
          children: [
            TabBar(
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: AppTextStyles.button().copyWith(fontSize: 12, letterSpacing: 1),
              tabs: const [
                Tab(text: 'SOFTWARE TOOLS'),
                Tab(text: 'HARDWARE MODULES'),
              ],
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<(List<OwnedSoftware>, List<OwnedHardware>)>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading inventory: ${snapshot.error}',
                        style: AppTextStyles.body(color: AppColors.alert),
                      ),
                    );
                  }

                  final (software, hardware) = snapshot.data ?? (<OwnedSoftware>[], <OwnedHardware>[]);

                  return TabBarView(
                    children: [
                      // Software Tab
                      software.isEmpty
                          ? Center(
                              child: Text(
                                'NO SOFTWARE INSTALLED',
                                style: AppTextStyles.body(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.builder(
                              itemCount: software.length,
                              itemBuilder: (context, i) {
                                final s = software[i];
                                final isMax = s.userSoftware.currentLevel >= s.catalogItem.initMaxLevel;
                                final lvlText = isMax
                                    ? 'Lv ${s.userSoftware.currentLevel}/${s.catalogItem.initMaxLevel} (MAX)'
                                    : 'Lv ${s.userSoftware.currentLevel}/${s.catalogItem.initMaxLevel}';

                                return _InventoryRow(
                                  name: s.catalogItem.name,
                                  subText: _getSoftTypeName(s.catalogItem.softTypeId).toUpperCase(),
                                  lvlText: lvlText,
                                  isMax: isMax,
                                  icon: Icons.terminal,
                                  onTap: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      Routes.workshopItem,
                                      arguments: WorkshopItemArgs(
                                        itemType: 'software',
                                        id: s.userSoftware.id!,
                                      ),
                                    );
                                    _refreshData();
                                  },
                                );
                              },
                            ),

                      // Hardware Tab
                      hardware.isEmpty
                          ? Center(
                              child: Text(
                                'NO HARDWARE MODULES OWNED',
                                style: AppTextStyles.body(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.builder(
                              itemCount: hardware.length,
                              itemBuilder: (context, i) {
                                final h = hardware[i];
                                const maxLvl = 5;
                                final isMax = h.userHardware.currentLevel >= maxLvl;
                                final lvlText = isMax
                                    ? 'Lv ${h.userHardware.currentLevel}/$maxLvl (MAX)'
                                    : 'Lv ${h.userHardware.currentLevel}/$maxLvl';

                                return _InventoryRow(
                                  name: h.catalogItem.name,
                                  subText: '${h.catalogItem.hwType}  ·  POWER: +${h.userHardware.computePower} FLOPS',
                                  lvlText: lvlText,
                                  isMax: isMax,
                                  icon: Icons.dns,
                                  onTap: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      Routes.workshopItem,
                                      arguments: WorkshopItemArgs(
                                        itemType: 'hardware',
                                        id: h.userHardware.id!,
                                      ),
                                    );
                                    _refreshData();
                                  },
                                );
                              },
                            ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({
    required this.name,
    required this.subText,
    required this.lvlText,
    required this.isMax,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final String subText;
  final String lvlText;
  final bool isMax;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceSuccess,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.borderSuccess),
              ),
              child: Icon(icon, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.dataMono(color: AppColors.text).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subText,
                    style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              lvlText,
              style: AppTextStyles.dataMono(
                color: isMax ? AppColors.warning : AppColors.primary,
              ).copyWith(
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.iconLow, size: 16),
          ],
        ),
      ),
    );
  }
}
