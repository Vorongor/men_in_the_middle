import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_hardware.dart';
import '../models/user_software.dart';
import '../repos/inventory_repository.dart';
import '../state/player_session.dart';
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
              indicatorColor: Colors.greenAccent,
              labelColor: Colors.greenAccent,
              unselectedLabelColor: Colors.white38,
              labelStyle: GoogleFonts.shareTechMono(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              tabs: const [
                Tab(text: 'SOFTWARE TOOLS'),
                Tab(text: 'HARDWARE MODULES'),
              ],
            ),
            const Divider(color: Color(0xFF111111), height: 1),
            Expanded(
              child: FutureBuilder<(List<OwnedSoftware>, List<OwnedHardware>)>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.green));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading inventory: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
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
                                style: GoogleFonts.shareTechMono(color: Colors.white24),
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
                                style: GoogleFonts.shareTechMono(color: Colors.white24),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF111111))),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0C160C),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF1E351E)),
              ),
              child: Icon(icon, color: Colors.greenAccent, size: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subText,
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white30,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              lvlText,
              style: GoogleFonts.shareTechMono(
                color: isMax ? Colors.amberAccent : Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white10, size: 16),
          ],
        ),
      ),
    );
  }
}
