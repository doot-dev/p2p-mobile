import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/data.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../ui/icons.dart';
import '../ui/kit.dart';
import 'auth/session.dart';
import 'home/home_screen.dart';
import 'inbox/inbox_screen.dart';
import 'people/creators_screen.dart';
import 'people/profile_screens.dart';
import 'projects/projects_screen.dart';

/// The five primary tabs (the website's navbar: Projects, Creators, Inbox, Profile — plus Home).
final tabs = <({String path, String label, IconData icon, Widget screen})>[
  (path: '/home', label: 'Home', icon: PhosphorIconsFill.house, screen: const HomeScreen()),
  (path: '/projects', label: 'Projects', icon: PhosphorIconsFill.filmSlate, screen: const ProjectsScreen()),
  (path: '/creators', label: 'Creators', icon: PhosphorIconsFill.usersThree, screen: const CreatorsScreen()),
  (path: '/inbox', label: 'Inbox', icon: PhosphorIconsFill.chatCircleDots, screen: const InboxScreen()),
  (path: '/me', label: 'Profile', icon: PhosphorIconsFill.user, screen: const MeScreen()),
];

/// Unread messages + unread incoming applications (the Inbox tab badge). 0 when signed out.
final inboxBadgeProvider = Provider.autoDispose<int>((ref) {
  if (!ref.watch(sessionProvider.select((s) => s.signedIn))) return 0;
  final threads = ref.watch(apiGet('$ptp/messages/threads')).value as Json?;
  final incoming = ref.watch(apiGet('$ptp/applications/incoming')).value as Json?;
  var n = 0;
  for (final t in (threads?['threads'] as List? ?? const [])) {
    n += ((t as Json)['unread'] as num? ?? 0).toInt();
  }
  for (final a in (incoming?['applications'] as List? ?? const [])) {
    if ((a as Json)['creatorRead'] != true) n++;
  }
  return n;
});

Widget _icon(IconData icon, int badge) => badge == 0 ? Icon(icon) : Badge(label: Text(badge > 99 ? '99+' : '$badge'), backgroundColor: C.brand, textColor: C.onBrand, child: Icon(icon));

/// Bottom tabs on phones; a side rail on wide screens (web, tablets).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _go(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = ref.watch(inboxBadgeProvider);
    Widget iconFor(int i) => _icon(tabs[i].icon, tabs[i].path == '/inbox' ? badge : 0);
    if (MediaQuery.sizeOf(context).width >= 840) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _go,
            labelType: NavigationRailLabelType.all,
            leading: const Padding(padding: EdgeInsets.symmetric(vertical: S.lg), child: BrandMark(size: 36)),
            destinations: [for (var i = 0; i < tabs.length; i++) NavigationRailDestination(icon: iconFor(i), label: Text(tabs[i].label))],
          ),
          const VerticalDivider(width: 0.5, thickness: 0.5),
          Expanded(child: shell),
        ]),
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.divider, width: 0.5))),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _go,
          destinations: [for (var i = 0; i < tabs.length; i++) NavigationDestination(icon: iconFor(i), label: tabs[i].label)],
        ),
      ),
    );
  }
}
