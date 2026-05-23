import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_ui.dart';
import 'inbox_screen.dart';
import 'templates_screen.dart';
import 'workers_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _index = 0;

  static const _titles = ['Рабочие', 'Входящие', 'Шаблоны ИИ'];
  static const _subtitles = [
    'Команда и статистика',
    'Отчёты на проверку',
    'Инструкции для GigaChat',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          AuroraHeader(
            title: _titles[_index],
            subtitle: _subtitles[_index],
            compact: true,
            trailing: HeaderIconButton(
              tooltip: 'Выйти',
              icon: Icons.logout_rounded,
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                WorkersScreen(),
                InboxScreen(),
                TemplatesScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: 'Рабочие',
              ),
              NavigationDestination(
                icon: Icon(Icons.inbox_outlined),
                selectedIcon: Icon(Icons.inbox_rounded),
                label: 'Входящие',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Шаблоны',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
