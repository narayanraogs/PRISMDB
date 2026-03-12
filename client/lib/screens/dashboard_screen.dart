import 'package:flutter/material.dart';
import '../models/app_models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Theme.of(context).colorScheme.surface,
            indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.table_chart_outlined),
                selectedIcon: Icon(Icons.table_chart),
                label: Text('Data'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                DashboardView(),
                DataTableView(),
                Center(child: Text("Settings Placeholder")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Overview",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            "Database Categories",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: DummyData.categories.map((cat) {
              return _StatCard(
                title: cat.name,
                value: cat.itemCount.toString(),
                icon: Icons.folder_open,
                color: Colors.blueAccent,
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text(
            "Validation Health",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: DummyData.validationResults.length,
              itemBuilder: (context, index) {
                final item = DummyData.validationResults[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.errors > 0
                          ? Colors.red.withOpacity(0.2)
                          : item.warnings > 0
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                      child: Icon(
                        item.errors > 0
                            ? Icons.error_outline
                            : item.warnings > 0
                                ? Icons.warning_amber
                                : Icons.check_circle_outline,
                        color: item.errors > 0
                            ? Colors.red
                            : item.warnings > 0
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                    title: Text(item.tableName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${item.items} Items"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.errors > 0)
                          Chip(
                            label: Text("${item.errors} Errors"),
                            backgroundColor: Colors.red.withOpacity(0.1),
                            labelStyle: const TextStyle(color: Colors.red),
                            side: BorderSide.none,
                          ),
                        if (item.warnings > 0) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: Text("${item.warnings} Warnings"),
                            backgroundColor: Colors.orange.withOpacity(0.1),
                            labelStyle: const TextStyle(color: Colors.orange),
                            side: BorderSide.none,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}

class DataTableView extends StatelessWidget {
  const DataTableView({super.key});

  @override
  Widget build(BuildContext context) {
    final table = DummyData.tableDisplay;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                table.tableName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text("Add New"),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  columns: table.headers
                      .map((h) => DataColumn(
                            label: Text(
                              h,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ))
                      .toList(),
                  rows: table.rows.map((row) {
                    return DataRow(
                      cells: row.map((cell) => DataCell(Text(cell))).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
