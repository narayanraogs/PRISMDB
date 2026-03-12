import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/app_models.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:prism_db_editor/spec_transmitter.dart';
import 'package:prism_db_editor/spec_receiver.dart';
import 'package:prism_db_editor/widgets/edit_row_panel.dart';

final ApiService _apiService = ApiService();
final String _clientID = "client_1";

class TableDetailView extends StatefulWidget {
  final String tableName;
  final VoidCallback onBack;

  const TableDetailView({super.key, required this.tableName, required this.onBack});

  @override
  State<TableDetailView> createState() => _TableDetailViewState();
}

class _TableDetailViewState extends State<TableDetailView> {
  bool _isLoading = true;
  TableData? _tableData;
  String? _error;
  final ScrollController _horizontalScrollController = ScrollController();
  late ScrollController _verticalMain;
  late ScrollController _verticalLeft;
  late ScrollController _verticalRight;
  bool _isSyncing = false;
  
  // Map column index to filter text
  final Map<int, String> _columnFilters = {};
  // Map column index to controller for inline filtering
  final Map<int, TextEditingController> _filterControllers = {};
  bool _showFilterRow = false;
  
  // Row editing state
  List<String>? _editingRow;
  bool _showEditPanel = false;
  bool _isCopy = false;
  
  // Local filtered data cache to avoid re-filtering on every build if not needed, 
  // but for simplicity we will filter in build or just memoize if perf is an issue.
  // For small tables, filtering in build is fine.

  @override
  void initState() {
    super.initState();
    _verticalMain = ScrollController();
    _verticalLeft = ScrollController();
    _verticalRight = ScrollController();

    _verticalMain.addListener(() => _syncScroll(_verticalMain, [_verticalLeft, _verticalRight]));
    _verticalLeft.addListener(() => _syncScroll(_verticalLeft, [_verticalMain, _verticalRight]));
    _verticalRight.addListener(() => _syncScroll(_verticalRight, [_verticalMain, _verticalLeft]));
    
    _fetchData();
  }

  void _syncScroll(ScrollController source, List<ScrollController> targets) {
    if (_isSyncing) return;
    _isSyncing = true;
    for (var target in targets) {
      if (target.hasClients && target.offset != source.offset) {
        target.jumpTo(source.offset);
      }
    }
    _isSyncing = false;
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalMain.dispose();
    _verticalLeft.dispose();
    _verticalRight.dispose();
    for (var controller in _filterControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getTableData(_clientID, widget.tableName);
      setState(() {
        _tableData = data;
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

  void _showEditRowDialog(List<String> rowData) {
    setState(() {
      _editingRow = rowData;
      _isCopy = false;
      _showEditPanel = true;
    });
  }

  void _showAddRowDialog() {
    if (_tableData == null) return;
    setState(() {
      _editingRow = null; // null signifies new row
      _isCopy = false;
      _showEditPanel = true;
    });
  }

  List<String> _prepareCopiedRow(String tableName, List<String> original) {
    List<String> copied = List.from(original);
    if (copied.isEmpty) return copied;

    if (copied.isNotEmpty) copied[0] = '0'; // Default ID to 0

    String mockSuffix = '_Copy_${DateTime.now().millisecondsSinceEpoch % 10000}';

    switch (tableName.toLowerCase()) {
      // Tables with Composite Keys
      case 'spectxharmonics': // [TxName, HarmonicType, HarmonicsName, ...]
        if (copied.length > 3) {
           copied[2] = '${copied[2]}$mockSuffix';
           copied[3] = '${copied[3]}$mockSuffix';
        }
        break;
      case 'spectxsubcarriers': // [TxName, SubCarrierID, SubCarrierName, ...]
        if (copied.length > 2) copied[2] = '${copied[2]}$mockSuffix';
        break;
      case 'spectpranging': // [TpName, RangingID, RangingName, ...]
        if (copied.length > 2) copied[2] = '${copied[2]}$mockSuffix';
        break;
      case 'tests': // [ID, ConfigName, TestType, TestCategory, ...]
        if (copied.length > 3) {
           copied[2] = '${copied[2]}$mockSuffix';
           copied[3] = '${copied[3]}$mockSuffix';
        }
        break;
      case 'uplinkloss': // [ID, ConfigName, TestPhaseName, Profile]
      case 'downlinkloss':
        if (copied.length > 2) {
           copied[1] = '${copied[1]}$mockSuffix';
           copied[2] = '${copied[2]}$mockSuffix';
        }
        break;

      // Tables with Name at Index 1 (ID as Index 0)
      case 'spectx':
      case 'specrx':
      case 'spectp':
      case 'tmprofile':
      case 'updownconverter':
      case 'testphases':
      case 'devices':
      case 'configurations':
      case 'tsmconfigurations':
      case 'deviceprofile':
      case 'frequencyprofile':
      case 'powerprofile':
      case 'spectrumprofile':
      case 'pulseprofile':
      case 'trmprofile':
      case 'downlinkpowerprofile':
      case 'lossmeasurementfrequencies':
      case 'specpl':
      case 'obwpower':
      case 'cablecalibration':
        if (copied.length > 1) copied[1] = '${copied[1]}$mockSuffix';
        break;
      
      // Tables with Name/Key at Index 0 (No ID or Name is first)
      case 'specrxtmtc':
      case 'specrxtm':
      case 'spectrumsettings':
        copied[0] = '${copied[0]}$mockSuffix';
        break;
        
      default:
        if (copied.length > 1) copied[1] = '${copied[1]}$mockSuffix';
        else copied[0] = '${copied[0]}$mockSuffix';
    }
    return copied;
  }

  Future<void> _copyRow(List<String> rowData) async {
    setState(() => _isLoading = true);
    try {
      List<String> newRow = _prepareCopiedRow(widget.tableName, rowData);
      
      // Remove auto-generated ID columns so it matches backend args explicitly expecting shifted Values
      switch(widget.tableName.toLowerCase()) {
        case 'spectxharmonics':
        case 'spectxsubcarriers':
        case 'spectpranging':
          if (newRow.length > 1) newRow.removeAt(1); // ID is offset at index 1
          break;
        case 'specpl':
        case 'spectp':
        case 'configurations':
        case 'lossmeasurementfrequencies':
        case 'tsmconfigurations':
        case 'downlinkloss':
        case 'testphases':
        case 'testphase':
        case 'tests':
        case 'uplinkloss':
        case 'deviceprofile':
        case 'frequencyprofile':
        case 'pulseprofile':
        case 'powerprofile':
        case 'spectrumprofile':
        case 'trmprofile':
        case 'downlinkpowerprofile':
          if (newRow.isNotEmpty) newRow.removeAt(0); // ID is at index 0 and dropped by backend
          break;
      }

      bool success = await _apiService.addRow(_clientID, widget.tableName, newRow);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Row duplicated successfully"), backgroundColor: Colors.green)
          );
        }
        await _fetchData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to duplicate row"), backgroundColor: Colors.red)
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  TextEditingController _getController(int columnIndex) {
    if (!_filterControllers.containsKey(columnIndex)) {
      _filterControllers[columnIndex] = TextEditingController(text: _columnFilters[columnIndex] ?? "");
    }
    return _filterControllers[columnIndex]!;
  }

  void _applyFilter(int columnIndex, String? value) {
    setState(() {
      if (value == null || value.isEmpty) {
        _columnFilters.remove(columnIndex);
      } else {
        _columnFilters[columnIndex] = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine content based on state
    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
    } else if (_tableData == null) {
      content = const Center(child: Text("No data found."));
    } else {
      // 1. Filter rows based on all active column filters
      List<List<String>> filteredRows = _tableData!.rows;
      if (_columnFilters.isNotEmpty) {
        filteredRows = filteredRows.where((row) {
          for (var entry in _columnFilters.entries) {
            int colIndex = entry.key;
            String filterText = entry.value.toLowerCase();
            if (colIndex < row.length) {
              if (!row[colIndex].toLowerCase().contains(filterText)) {
                return false;
              }
            }
          }
          return true;
        }).toList();
      }

      content = LayoutBuilder(
        builder: (context, constraints) {
          int numCols = _tableData!.headers.length;
          double baseColumnWidth = 180.0;
          double actionsWidth = 120.0;
          double marginWidth = 48.0;
          
          double minimumTableWidth = (numCols * baseColumnWidth) + actionsWidth + marginWidth;
          double totalTableWidth = constraints.maxWidth > minimumTableWidth ? constraints.maxWidth : minimumTableWidth;
          
          double columnWidth = (totalTableWidth - actionsWidth - marginWidth) / numCols;

          return Stack(
            children: [
              // 1. MAIN SCROLLABLE TABLE CONTENT
              Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 8.0,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: totalTableWidth,
                    child: Column(
                      children: [
                        // Header
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                          ),
                          child: _buildDataTable(isFull: true, rows: [], columnWidth: columnWidth, actionsWidth: actionsWidth),
                        ),
                        // Body
                        Expanded(child: _buildDataTableManagedScroll(filteredRows, constraints, _verticalMain, isFull: true, columnWidth: columnWidth, actionsWidth: actionsWidth)),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. LEFT FROZEN COLUMN OVERLAY
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: columnWidth + 24, // width + left margin
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      // Frozen Left Header
                      Container(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        child: _buildDataTable(isLeftFixed: true, rows: [], columnWidth: columnWidth, actionsWidth: actionsWidth),
                      ),
                      // Frozen Left Body
                      Expanded(child: _buildDataTableManagedScroll(filteredRows, constraints, _verticalLeft, isLeftFixed: true, columnWidth: columnWidth, actionsWidth: actionsWidth)),
                    ],
                  ),
                ),
              ),

              // 3. RIGHT FROZEN COLUMN OVERLAY (Actions)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: actionsWidth + 24, // width + right margin
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      // Frozen Right Header
                      Container(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        child: _buildDataTable(isRightFixed: true, rows: [], columnWidth: columnWidth, actionsWidth: actionsWidth),
                      ),
                      // Frozen Right Body
                      Expanded(child: _buildDataTableManagedScroll(filteredRows, constraints, _verticalRight, isRightFixed: true, columnWidth: columnWidth, actionsWidth: actionsWidth)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      );
    }

    // Return structure without Scaffold, fitting into the parent dashboard
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onBack,
                      tooltip: "Back to Tables",
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tableName, 
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3E2723)
                          )
                        ),
                        if (_columnFilters.isNotEmpty)
                          Text(
                            "Filtered by ${_columnFilters.length} column(s)",
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)
                          )
                      ],
                    ),
                    const Spacer(),
                    if (_columnFilters.isNotEmpty || _showFilterRow)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                               _columnFilters.clear();
                               for (var controller in _filterControllers.values) {
                                 controller.clear();
                               }
                            });
                          }, 
                          icon: const Icon(Icons.clear_all), 
                          label: const Text("Clear Filters")
                        ),
                      ),
                    IconButton(
                      icon: Icon(_showFilterRow ? Icons.filter_alt_off : Icons.filter_alt),
                      tooltip: _showFilterRow ? "Hide Filters" : "Show Inline Filters",
                      onPressed: () => setState(() => _showFilterRow = !_showFilterRow),
                      style: IconButton.styleFrom(
                        backgroundColor: _showFilterRow ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
                        foregroundColor: _showFilterRow ? Theme.of(context).colorScheme.primary : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: "Add Row",
                      onPressed: _showAddRowDialog,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: "Refresh",
                      onPressed: _fetchData,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Table Card
                Expanded(
                  child: Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: content,
                  ),
                ),
              ],
            ),
          ),
          
          if (_showEditPanel)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 500,
              margin: const EdgeInsets.only(left: 32),
              child: _buildEditPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildDataTable({
    bool isFull = false,
    bool isLeftFixed = false,
    bool isRightFixed = false,
    required List<List<String>> rows,
    required double columnWidth,
    required double actionsWidth,
  }) {
    
    // Headers logic
    List<DataColumn> columns = [];
    if (isFull || isLeftFixed) {
      columns.add(DataColumn(
        label: SizedBox(
          width: columnWidth,
          child: _buildHeaderContent(0, _tableData!.headers[0]),
        )
      ));
    }
    
    if (isFull) {
      for (int i = 1; i < _tableData!.headers.length; i++) {
        columns.add(DataColumn(
          label: SizedBox(
            width: columnWidth,
            child: _buildHeaderContent(i, _tableData!.headers[i]),
          )
        ));
      }
    }
    
    if (isFull || isRightFixed) {
      columns.add(DataColumn(
        label: SizedBox(
          width: actionsWidth,
          child: const Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))
        )
      ));
    }

    return DataTable(
      headingRowHeight: _showFilterRow ? 100 : 56,
      horizontalMargin: (isFull || isLeftFixed) ? 24 : 0, // Left fixed gets left margin
      columnSpacing: 0,
      columns: columns,
      rows: rows.map((row) {
        List<DataCell> cells = [];
        if (isFull || isLeftFixed) {
          cells.add(DataCell(SizedBox(width: columnWidth, child: Text(row[0], overflow: TextOverflow.ellipsis))));
        }
        if (isFull) {
          for (int i = 1; i < row.length; i++) {
            cells.add(DataCell(SizedBox(width: columnWidth, child: Text(row[i], overflow: TextOverflow.ellipsis))));
          }
        }
        if (isFull || isRightFixed) {
          cells.add(DataCell(
            SizedBox(
              width: actionsWidth,
              child: _buildActions(row),
            )
          ));
        }
        return DataRow(cells: cells);
      }).toList(),
    );
  }

  Widget _buildDataTableManagedScroll(List<List<String>> rows, BoxConstraints constraints, ScrollController controller, {bool isFull = false, bool isLeftFixed = false, bool isRightFixed = false, required double columnWidth, required double actionsWidth}) {
     return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.vertical,
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - (_showFilterRow ? 100 : 56)),
            child: DataTable(
              headingRowHeight: 0,
              horizontalMargin: (isFull || isLeftFixed) ? 24 : 0,
              columnSpacing: 0,
              columns: _buildDummyHeaderColumns(isFull, isLeftFixed, isRightFixed, columnWidth, actionsWidth),
              rows: rows.map((row) => _buildDataRow(row, isFull, isLeftFixed, isRightFixed, columnWidth, actionsWidth)).toList(),
            ),
          ),
        ),
      );
  }

  List<DataColumn> _buildDummyHeaderColumns(bool isFull, bool isLeftFixed, bool isRightFixed, double columnWidth, double actionsWidth) {
    List<DataColumn> cols = [];
    if (isFull || isLeftFixed) cols.add(DataColumn(label: SizedBox(width: columnWidth)));
    if (isFull) {
      for (int i = 1; i < _tableData!.headers.length; i++) {
        cols.add(DataColumn(label: SizedBox(width: columnWidth)));
      }
    }
    if (isFull || isRightFixed) cols.add(DataColumn(label: SizedBox(width: actionsWidth)));
    return cols;
  }

  DataRow _buildDataRow(List<String> row, bool isFull, bool isLeftFixed, bool isRightFixed, double columnWidth, double actionsWidth) {
    List<DataCell> cells = [];
    if (isFull || isLeftFixed) {
      cells.add(DataCell(SizedBox(width: columnWidth, child: Text(row[0], overflow: TextOverflow.ellipsis))));
    }
    if (isFull) {
      for (int i = 1; i < row.length; i++) {
        cells.add(DataCell(SizedBox(width: columnWidth, child: Text(row[i], overflow: TextOverflow.ellipsis))));
      }
    }
    if (isFull || isRightFixed) {
      cells.add(DataCell(SizedBox(width: actionsWidth, child: _buildActions(row))));
    }
    return DataRow(cells: cells);
  }

  Widget _buildHeaderContent(int index, String h) {
    final isFiltered = _columnFilters.containsKey(index);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                h, 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isFiltered ? Theme.of(context).colorScheme.primary : Colors.black87,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isFiltered ? Icons.filter_alt : Icons.filter_list, 
              size: 14, 
              color: isFiltered ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.4)
            ),
          ],
        ),
        if (_showFilterRow) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: TextField(
              controller: _getController(index),
              onChanged: (val) => _applyFilter(index, val),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Filter...",
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1)),
                prefixIcon: const Icon(Icons.search, size: 14),
              ),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildActions(List<String> row) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
          onPressed: () => _showEditRowDialog(row),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.copy, size: 20, color: Colors.green),
          onPressed: () => _copyRow(row),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
          onPressed: () => _handleDeleteRow(row),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildEditPanel() {
    if (_editingRow == null && _showEditPanel == false) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _editingRow == null ? "Add Row" : (_isCopy ? "Copy Row" : "Edit Row"),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _showEditPanel = false),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: EditRowPanel(
              tableName: widget.tableName,
              initialRow: _editingRow,
              headers: _tableData?.headers ?? [],
              isCopy: _isCopy,
              onComplete: () {
                setState(() {
                  _showEditPanel = false;
                  _editingRow = null;
                });
                _fetchData();
              },
              onCancel: () {
                setState(() {
                  _showEditPanel = false;
                  _editingRow = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }


  String _getPrimaryKey(String tableName, List<String> row) {
    if (row.isEmpty) return "";
    switch (tableName.toLowerCase()) {
      // Tables with Composite Keys
      case 'spectxharmonics': // [TxName, HarmonicType, HarmonicsName, ...]
        if (row.length > 3) return "${row[0]}:::${row[2]}:::${row[3]}";
        break;
      case 'spectxsubcarriers': // [TxName, SubCarrierID, SubCarrierName, ...]
        if (row.length > 2) return "${row[0]}:::${row[2]}";
        break;
      case 'spectpranging': // [TpName, RangingID, RangingName, ...]
        if (row.length > 2) return "${row[0]}:::${row[2]}";
        break;
      case 'tests': // [ID, ConfigName, TestType, TestCategory, ...]
        // Backend DeleteTests expects composite key: ConfigName:::TestType:::TestCategory
        if (row.length > 3) return "${row[1]}:::${row[2]}:::${row[3]}";
        break;
      case 'uplinkloss': // [ID, ConfigName, TestPhaseName, Profile]
      case 'downlinkloss':
      case 'specpl': // [ID, ConfigName, ResolutionMode, ...]
        if (row.length > 2) return "${row[1]}:::${row[2]}";
        break;

      // Tables with Name at Index 1 (ID as Index 0)
      case 'spectx':
      case 'specrx':
      case 'spectp':
      case 'tmprofile':
      case 'updownconverter':
      case 'testphases':
      case 'devices':
      case 'configurations':
      case 'tsmconfigurations':
      case 'deviceprofile':
      case 'frequencyprofile':
      case 'powerprofile':
      case 'spectrumprofile':
      case 'pulseprofile':
      case 'trmprofile':
      case 'downlinkpowerprofile':
      case 'lossmeasurementfrequencies':
        if (row.length > 1) return row[1];
        break;
      
      // Tables with Name/Key at Index 0 (No ID or Name is first)
      case 'specrxtmtc':
      case 'specrxtm':
        return row[0];
        
      default:
        // Default behavior (first column)
        return row[0];
    }
    return row[0];
  }

  Future<void> _handleDeleteRow(List<String> row) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Row"),
        content: const Text("Are you sure you want to delete this row?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        String pk = _getPrimaryKey(widget.tableName, row);
        final success = await _apiService.deleteRow(_clientID, widget.tableName, pk);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Deleted Successfully"), backgroundColor: Colors.green)
            );
          }
          await _fetchData();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to delete"), backgroundColor: Colors.red)
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
