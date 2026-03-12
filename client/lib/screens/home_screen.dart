import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/app_models.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../structures.dart';
import 'package:flutter/gestures.dart';
import 'table_detail_screen.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:prism_db_editor/create.dart';

// Singleton for simplicity in this small app
final ApiService _apiService = ApiService();
final String _clientID = "client_1";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isConnected = false;
  
  // Track selected table to show detailed view inside the content area
  String? _selectedTableName;

  final List<String> _menuItems = [
    'Connect',
    'Create',
    'Bookmark',
    'Tables',
    'Validate',
    'Backup',
  ];

  final List<IconData> _menuIcons = [
    Icons.link,
    Icons.add_circle_outline,
    Icons.bookmark_border,
    Icons.table_chart_outlined,
    Icons.check_circle_outline,
    Icons.backup_outlined,
  ];

  void _onConnectSuccess(bool success, String message) {
    if (success) {
      setState(() {
        _isConnected = true;
        _selectedIndex = 3; // Navigate to Tables/Overview after connection
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Successfully connected to database!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to connect: $message"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onDisconnect() {
    setState(() {
      _isConnected = false;
      _selectedIndex = 0;
      _selectedTableName = null;
    });
  }

  void _onTableSelected(String tableName) {
    setState(() {
      _selectedTableName = tableName;
    });
  }

  void _onBackToTables() {
    setState(() {
      _selectedTableName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          VerticalDivider(thickness: 1, width: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.layers, color: Theme.of(context).colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Text(
                  "PRISM DB",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: ListView.separated(
              itemCount: _menuItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final isEnabled = index <= 1 || _isConnected; // Connect(0) & Create(1) always enabled
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: isEnabled
                          ? () {
                              setState(() {
                                _selectedIndex = index;
                                // Reset table selection when changing tabs
                                _selectedTableName = null; 
                              });
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                              : Theme.of(context).cardTheme.color?.withOpacity(0.5), // Subtle background for unselected tabs
                          border: isSelected
                              ? Border(
                                  left: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 4, // Thicker border
                                  ),
                                )
                              : null,
                          boxShadow: isSelected 
                              ? [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _menuIcons[index],
                              color: isEnabled
                                  ? (isSelected ? Theme.of(context).colorScheme.primary : Colors.grey)
                                  : Colors.grey.withOpacity(0.3),
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _menuItems[index],
                                style: TextStyle(
                                color: isEnabled
                                    ? (isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface)
                                    : Colors.grey.withOpacity(0.5),
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, // Make text bolder
                                fontSize: 15,
                              ),
                            ),
                            if (!isEnabled) ...[
                              const Spacer(),
                              Icon(Icons.lock_outline, size: 14, color: Colors.grey.withOpacity(0.3)),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isConnected)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _onDisconnect,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.brown,
                  side: const BorderSide(color: Colors.brown),
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text("Disconnect"),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return ConnectView(onConnect: _onConnectSuccess);
      case 1:
        return Create(
          Global(), // You will need to import variables.dart for Global, or pass a suitable global context. Based on other tabs, we will create a dummy Global or use a proper one.
          () {} // Empty callback, or trigger something here
        );
      case 2:
        return const _PlaceholderView(title: "Bookmarks", icon: Icons.bookmark_border);
      case 3:
        // If a table is selected, show detail view within the content area
        if (_selectedTableName != null) {
          return TableDetailView(
            tableName: _selectedTableName!, 
            onBack: _onBackToTables
          );
        }
        return TablesView(onTableTap: _onTableSelected); 
      case 4:
        return const ValidationView();
      case 5:
        return const _PlaceholderView(title: "Backup", icon: Icons.backup_outlined);
      default:
        return const Center(child: Text("Unknown Page"));
    }
  }
}

// ---------------- VIEWS ----------------

class ConnectView extends StatefulWidget {
  final Function(bool, String) onConnect;
  const ConnectView({super.key, required this.onConnect});

  @override
  State<ConnectView> createState() => _ConnectViewState();
}

class _ConnectViewState extends State<ConnectView> {
  String _connectionType = 'config'; // 'config' or 'manual'
  final TextEditingController _pathController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleConnect() async {
    setState(() => _isLoading = true);
    
    // Call API
    try {
      final success = await _apiService.registerClient(
        _clientID, 
        _connectionType == 'manual' ? _pathController.text : "",
        _connectionType == 'config'
      ); // Assume registerClient returns Map or Bool

      if (success) {
        widget.onConnect(true, "Success");
      } else {
        widget.onConnect(false, "Could not register database. Ensure server is running and config/path is valid.");
      }
    } catch (e) {
      widget.onConnect(false, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Connect to Database",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Toggle
            Row(
              children: [
                 Expanded(
                   child: _SelectionCard(
                     title: "Use Config",
                     subtitle: "~/prism/config/config.json",
                     isSelected: _connectionType == 'config',
                     icon: Icons.settings,
                     onTap: () => setState(() => _connectionType = 'config'),
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: _SelectionCard(
                     title: "Manual Path",
                     subtitle: "Select .db file",
                     isSelected: _connectionType == 'manual',
                     icon: Icons.folder_open,
                     onTap: () => setState(() => _connectionType = 'manual'),
                   ),
                 ),
              ],
            ),
            
            const SizedBox(height: 32),

            if (_connectionType == 'manual')
              TextField(
                controller: _pathController,
                decoration: InputDecoration(
                  labelText: "Database Path",
                  hintText: "/path/to/database.db",
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              
             if (_connectionType == 'config')
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                 ),
                 child: Row(
                   children: [
                     const Icon(Icons.info_outline, color: Colors.blueAccent),
                     const SizedBox(width: 12),
                     const Expanded(child: Text("Will look for config.json in basefolder/config/")),
                   ],
                 ),
               ),

            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _handleConnect,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Connect", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateView extends StatelessWidget {
  final Function(bool, String) onCreate;
  const CreateView({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Create New Database",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Placeholder for create logic
             FilledButton.icon(
              onPressed: () => onCreate(true, "Created (Simulated)"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.teal,
              ),
              icon: const Icon(Icons.add),
              label: const Text("Create Database", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class TablesView extends StatefulWidget {
  final Function(String) onTableTap;
  const TablesView({super.key, required this.onTableTap});

  @override
  State<TablesView> createState() => _TablesViewState();
}

class _TablesViewState extends State<TablesView> {
  List<Category> _tables = [];
  bool _isLoading = true;
  String? _error;
  
  // Track expanded category
  String? _expandedCategory;

  // Category definitions
  final Map<String, List<String>> _definedCategories = {
    'Specifications': ['SpecTx', 'SpecTxHarmonics', 'SpecTxSubCarriers', 'SpecRx','SpecRxTMTC','SpecTp','SpecTpRanging','SpecPL'],
    'Configurations': ['Configurations', 'TSMConfigurations', 'Devices','LossMeasurementFrequencies','UpDownConverter'],
    'Tests': ['Tests', 'TestPhases', 'DownlinkLoss', 'UplinkLoss'],
    'Profiles': ['DeviceProfile', 'DownlinkPowerProfile', 'FrequencyProfile', 'PowerProfile', 'PulseProfile', 'SpectrumProfile','TMProfile', 'TRMProfile'],
  };

  @override
  void initState() {
    super.initState();
    _fetchTables();
    _expandedCategory = 'Specifications';
  }

  Future<void> _fetchTables() async {
    setState(() {
       _isLoading = true; 
       _error = null;
    });
    try {
      final tables = await _apiService.getCategories(_clientID);
      setState(() {
        _tables = tables;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getCategoryForTable(String tableName) {
    for (var entry in _definedCategories.entries) {
      if (entry.value.any((t) => t.toLowerCase() == tableName.toLowerCase())) {
        return entry.key;
      }
    }
    return 'Others';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Transmitter': return Icons.settings_input_antenna;
      case 'Receiver': return Icons.radar;
      case 'Payloads': return Icons.layers;
      case 'Configurations': return Icons.tune;
      case 'Profiles': return Icons.account_tree;
      case 'Tests': return Icons.science;
      default: return Icons.folder_open;
    }
  }

  Map<String, List<Category>> _groupTables() {
    final Map<String, List<Category>> grouped = {};
    for (var key in _definedCategories.keys) {
      grouped[key] = [];
    }
    grouped['Others'] = [];

    for (var table in _tables) {
      String cat = _getCategoryForTable(table.name);
      if (grouped.containsKey(cat)) {
        grouped[cat]!.add(table);
      } else {
        grouped['Others']!.add(table);
      }
    }
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }
  
  void _toggleCategory(String category) {
    setState(() {
      if (_expandedCategory == category) {
        _expandedCategory = null;
      } else {
        _expandedCategory = category;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.red)));

    final groupedTables = _groupTables();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Database Tables", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(onPressed: _fetchTables, icon: const Icon(Icons.refresh))
            ],
          ),
          const SizedBox(height: 8),
          const Text("Manage and view content for all tables in the connected database.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: groupedTables.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                String category = groupedTables.keys.elementAt(index);
                List<Category> categoryTables = groupedTables[category]!;
                bool isExpanded = _expandedCategory == category;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _toggleCategory(category),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isExpanded 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isExpanded 
                                ? Theme.of(context).colorScheme.primary 
                                : Theme.of(context).dividerColor,
                          ),
                          boxShadow: isExpanded 
                              ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isExpanded ? Colors.white.withOpacity(0.2) : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(category), 
                                    color: isExpanded ? Colors.white : Theme.of(context).colorScheme.primary, 
                                    size: 24
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isExpanded ? Colors.white : const Color(0xFF3E2723),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isExpanded ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                  child: Text(
                                    "${categoryTables.length}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isExpanded ? Colors.white : Colors.grey[700]
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: isExpanded ? Colors.white : Colors.grey,
                                )
                              ],
                            ),
                            
                            // Show minimalist table names ONLY if collapsed
                            if (!isExpanded && categoryTables.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: categoryTables.map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey.withOpacity(0.2))
                                  ),
                                  child: Text(
                                    t.name, 
                                    style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500)
                                  ),
                                )).toList(),
                              )
                            ]
                          ],
                        ),
                      ),
                    ),
                    
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: isExpanded 
                          ? Padding(
                              padding: const EdgeInsets.only(top: 16.0, left: 8.0, right: 8.0),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5, 
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.6,
                                ),
                                itemCount: categoryTables.length,
                                itemBuilder: (context, idx) {
                                  final table = categoryTables[idx];
                                  return _TableCard(
                                    name: table.name, 
                                    rows: table.itemCount, 
                                    color: Colors.blue,
                                    onTap: () => widget.onTableTap(table.name),
                                  );
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _TableCard extends StatefulWidget {
  final String name;
  final int rows;
  final Color color;
  final VoidCallback onTap;

  const _TableCard({
    required this.name,
    required this.rows,
    required this.color,
    required this.onTap,
  });

  @override
  State<_TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<_TableCard> {
  bool _isHovered = false;
  List<String>? _headers;
  bool _isLoadingHeaders = false;

  void _onEnter(PointerEnterEvent event) {
    setState(() => _isHovered = true);
    if (_headers == null && !_isLoadingHeaders) {
      _fetchHeaders();
    }
  }

  void _onExit(PointerExitEvent event) {
    setState(() => _isHovered = false);
  }

  Future<void> _fetchHeaders() async {
    if (!mounted) return;
    setState(() => _isLoadingHeaders = true);
    try {
      // Use the global _apiService and _clientID defined in home_screen.dart
      final data = await _apiService.getTableData(_clientID, widget.name);
      if (mounted && data != null) {
        setState(() {
          _headers = data.headers;
          _isLoadingHeaders = false;
        });
      } else {
         if (mounted) setState(() => _isLoadingHeaders = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHeaders = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5), // Light theme-matching background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? widget.color : Colors.grey.withOpacity(0.2),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              if (_isHovered)
                BoxShadow(
                  color: widget.color.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: widget.color,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.table_chart_outlined, color: widget.color, size: 18),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          // Stats / Footer
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${widget.rows}",
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2D3748),
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  "records",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Clean Slide-up Overlay for Attributes
              if (_isHovered)
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    height: 120, // Expanded height for more attribute space (adapted for rectangular card)
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      border: Border(top: BorderSide(color: widget.color.withOpacity(0.1))),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [const Color(0xFFF5F5F5), const Color(0xFFF5F5F5).withOpacity(0.95)],
                      )
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text("Attributes".toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                         const SizedBox(height: 6),
                         Expanded(
                           child: _isLoadingHeaders
                            ? Align(alignment: Alignment.centerLeft, child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: widget.color)))
                            : _headers == null || _headers!.isEmpty 
                                ? Text("No columns", style: TextStyle(color: Colors.grey[400], fontSize: 11))
                                : SingleChildScrollView(
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: _headers!.map((h) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.grey[300]!)
                                        ),
                                        child: Text(
                                          h, 
                                          style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                                        ),
                                      )).toList(),
                                    ),
                                  ),
                         )
                      ],
                    ),
                  )
                )
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderView({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          const Text("Feature available when connected.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title, 
    required this.subtitle, 
    required this.isSelected, 
    required this.icon,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87
            )),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(
              fontSize: 12,
              color: Colors.grey.withOpacity(0.7)
            ), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class ValidationView extends StatefulWidget {
  const ValidationView({super.key});
  @override
  State<ValidationView> createState() => _ValidationViewState();
}

class _ValidationViewState extends State<ValidationView> {
  bool _isLoading = true;
  ValidationResult? _result;

  @override
  void initState() {
    super.initState();
    _fetchValidation();
  }

  Future<void> _fetchValidation() async {
    setState(() => _isLoading = true);
    final res = await _apiService.getValidationResults(_clientID);
    if (mounted) {
      setState(() {
        _result = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_result == null || !_result!.ok) {
      return Center(child: Text("Validation failed: ${_result?.message ?? 'Unknown error'}", style: const TextStyle(color: Colors.red)));
    }
    
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Database Validation", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              FilledButton.icon(onPressed: _fetchValidation, icon: const Icon(Icons.refresh), label: const Text("Re-Validate"))
            ],
          ),
          const SizedBox(height: 8),
          const Text("Click any card below to flip it and view specific errors or warnings.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: _result!.singleTables.length,
              itemBuilder: (context, index) {
                return _ValidationCard(table: _result!.singleTables[index]);
              },
            ),
          )
        ],
      ),
    );
  }
}

class _ValidationCard extends StatefulWidget {
  final SingleTableDetails table;
  const _ValidationCard({required this.table});
  @override
  State<_ValidationCard> createState() => _ValidationCardState();
}

class _ValidationCardState extends State<_ValidationCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  Color _getColor() {
    if (widget.table.errors > 0) return Colors.red;
    if (widget.table.warnings > 0) return Colors.orange;
    return Colors.green;
  }
  
  IconData _getIcon() {
    if (widget.table.errors > 0) return Icons.error_outline;
    if (widget.table.warnings > 0) return Icons.warning_amber_rounded;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_animation.value * math.pi);
          
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: _animation.value < 0.5 
              ? _buildFront() 
              : Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _buildBack()
                ),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getColor().withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(color: _getColor().withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getIcon(), size: 48, color: _getColor()),
          const SizedBox(height: 12),
          Text(
            widget.table.tableName, 
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text("${widget.table.items} Items", style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          if (widget.table.errors > 0 || widget.table.warnings > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.table.errors > 0)
                  Text("${widget.table.errors} E", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                if (widget.table.errors > 0 && widget.table.warnings > 0)
                  const Text(" | ", style: TextStyle(color: Colors.grey)),
                if (widget.table.warnings > 0)
                  Text("${widget.table.warnings} W", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildBack() {
    final List<String> issues = [];
    if (widget.table.errorList.isNotEmpty) issues.addAll(widget.table.errorList);
    if (widget.table.warningList.isNotEmpty) issues.addAll(widget.table.warningList);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getColor().withOpacity(0.5), width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.table.tableName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _getColor()), maxLines: 1, overflow: TextOverflow.ellipsis),
          const Divider(),
          if (issues.isEmpty)
            const Expanded(child: Center(child: Text("Validated perfectly.\nNo errors or warnings.", textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontSize: 13))))
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: issues.length,
                itemBuilder: (context, index) {
                  bool isError = index < widget.table.errorList.length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Icon(
                           isError ? Icons.error : Icons.warning, 
                           size: 14, 
                           color: isError ? Colors.red : Colors.orange
                         ),
                         const SizedBox(width: 6),
                         Expanded(child: Text(issues[index], style: const TextStyle(fontSize: 11, height: 1.2))),
                      ],
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
