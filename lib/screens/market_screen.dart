import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/hardware_item.dart';
import '../models/user_hardware.dart';
import '../repos/catalog_repository.dart';
import '../repos/inventory_repository.dart';
import '../state/player_session.dart';
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
            color: const Color(0xFF070707),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _types.length,
              itemBuilder: (context, i) {
                final type = _types[i];
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: ChoiceChip(
                    label: Text(
                      type,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.white60,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.greenAccent,
                    backgroundColor: const Color(0xFF141414),
                    side: BorderSide(
                      color: isSelected ? Colors.greenAccent : const Color(0xFF222222),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
          const Divider(color: Color(0xFF111111), height: 1),

          Expanded(
            child: FutureBuilder<(List<HardwareItem>, List<OwnedHardware>)>(
              future: _loadFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading market: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
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
                      style: GoogleFonts.shareTechMono(color: Colors.white24),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF111111))),
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
                  color: isLocked ? const Color(0xFF160A0A) : const Color(0xFF0C160C),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isLocked ? const Color(0xFF2D1414) : const Color(0xFF1E351E),
                  ),
                ),
                child: Icon(
                  isLocked ? Icons.lock_outline : Icons.dns,
                  color: isLocked ? Colors.redAccent : Colors.greenAccent,
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
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.hwType}  ·  COMPUTE POWER: +${item.initComputePower}',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white30,
                        fontSize: 11,
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
                    color: const Color(0xFF240C0C),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFF4C1414)),
                  ),
                  child: Text(
                    lockReason.toUpperCase(),
                    style: GoogleFonts.shareTechMono(
                      color: Colors.redAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (isOwned)
                Text(
                  'OWNED',
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white30,
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
                      style: GoogleFonts.shareTechMono(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isRiskTaxed)
                      Text(
                        'RISK TAX',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.orangeAccent,
                          fontSize: 8,
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white10, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
