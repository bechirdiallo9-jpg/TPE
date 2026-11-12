import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/settings_screen.dart';
import '../state/demo_store.dart';
import 'photo_view.dart';

/// Interrupteur Agent / Gérant, affiché sous la barre du haut.
class RoleSwitch extends StatelessWidget implements PreferredSizeWidget {
  const RoleSwitch({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DemoStore>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: SegmentedButton<bool>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            backgroundColor: Colors.white,
            selectedBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          segments: const [
            ButtonSegment(value: false, label: Text('Agent'), icon: Icon(Icons.person)),
            ButtonSegment(value: true, label: Text('Gérant'), icon: Icon(Icons.dashboard)),
          ],
          selected: {store.isManager},
          onSelectionChanged: (s) => store.setManager(s.first),
        ),
      ),
    );
  }
}

/// Barre du haut des écrans principaux : logo + nom de l'entreprise.
/// Un appui long sur le logo ouvre les réglages cachés de rebranding.
AppBar brandAppBar(BuildContext context) {
  final store = context.watch<DemoStore>();
  return AppBar(
    toolbarHeight: 64,
    title: Row(
      children: [
        GestureDetector(
          onLongPress: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Colors.white,
              width: 44,
              height: 44,
              child: LogoImage(path: store.config.logoPath),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            store.companyName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
      ],
    ),
    bottom: const RoleSwitch(),
  );
}
