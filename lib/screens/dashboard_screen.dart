import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/account_with_profile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)!.settings.arguments as AccountWithProfile;
    final a = data.account;
    final p = data.profile;
    final l = data.level;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Section('AGENT PROFILE'),
              _Row('ID', '#${a.id}'),
              _Row('Handle', a.pseudo),
              _Row('Rank', '${l.name}  ·  Lv.${l.id}'),
              _Row('Experience', '${p.experience} XP'),
              const SizedBox(height: 8),
              _Section('CAPABILITIES'),
              _Row('Software Power', '${p.softwarePower}'),
              _Row('Hardware Power', '${p.hardwarePower}'),
              const SizedBox(height: 8),
              _Section('REPUTATION'),
              _Row('Rating', '${p.rating}'),
              _Row('Karma', '${p.karma} / 100'),
              _Row('Wanted', '${p.wanted} / 100'),
              _Row('Popularity', '${p.popularity}'),
              _Row('Black Trust', '${p.blackTrust} / 100'),
              const SizedBox(height: 8),
              _Section('LEGEND'),
              const SizedBox(height: 8),
              Text(
                p.legend,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l.description,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cinzel(
              fontSize: 11,
              color: Colors.white54,
              letterSpacing: 3,
            ),
          ),
          const Divider(color: Colors.white12, height: 8),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
