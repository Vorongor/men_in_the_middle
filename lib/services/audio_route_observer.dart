import 'dart:async';

import 'package:flutter/widgets.dart';

import '../utils/constants.dart';
import '../utils/routes.dart';
import 'audio_service.dart';

/// Drives audio from navigation, so neither the click sound nor the music mode
/// has to be wired into individual screens.
///
/// Two responsibilities, both keyed off the destination route:
///  * a click SFX on every push/pop — one hook instead of ~50 call sites;
///  * switching between the menu theme and the hub playlist.
class AudioRouteObserver extends NavigatorObserver {
  /// Routes that live outside the game session and keep the main theme.
  /// Settings is deliberately absent: it is reachable from both sides and
  /// should not interrupt whatever is already playing.
  static const _menuRoutes = {Routes.home, Routes.login};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _onRouteChanged(route, isPush: true);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // On pop the screen being *revealed* is what matters for the music.
    _onRouteChanged(previousRoute, isPush: false);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _onRouteChanged(newRoute, isPush: false);
  }

  void _onRouteChanged(Route<dynamic>? route, {required bool isPush}) {
    final name = route?.settings.name;

    // Only user-driven navigation clicks; a replace (e.g. the session-expired
    // redirect) is not something the player pressed.
    if (isPush && name != null) {
      unawaited(AudioService.instance.playSfx(AppAudio.sfxClick));
    }

    if (name == null || name == Routes.settings) return;

    final audio = AudioService.instance;
    if (_menuRoutes.contains(name)) {
      unawaited(audio.playMenuTheme());
    } else {
      unawaited(audio.playHubPlaylist());
    }
  }
}
