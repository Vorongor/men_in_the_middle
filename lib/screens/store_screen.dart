import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/software_item.dart';
import '../models/user_software.dart';
import '../repos/catalog_repository.dart';
import '../repos/inventory_repository.dart';
import '../state/player_session.dart';
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
  late Future<(List<SoftwareItem>, List<OwnedSoftware>)> _loadFuture;

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
        _loadFuture = Future.value((<SoftwareItem>[], <OwnedSoftware>[]));
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
        screenNum: '6.1',
        screenName: 'GREY STORE',
        body: Center(
          child: Text('Not authenticated', style: TextStyle(color: Colors.white60)),
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
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading catalog: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final (catalog, owned) = snapshot.data ?? (<SoftwareItem>[], <OwnedSoftware>[]);

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
                  // Navigate to detail page and wait to refresh list if user buys it
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
                  isLocked ? Icons.lock_outline : Icons.terminal,
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
                      typeName.toUpperCase(),
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
