import 'dart:convert';
import 'dart:typed_data';

import 'package:dynamic_table/dynamic_table.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class UpLinkLosses extends StatefulWidget {
  final Global global;
  final VoidCallback callback;
  final bool isCopyMode;

  const UpLinkLosses(this.global, this.callback, {this.isCopyMode = false, super.key});

  @override
  State<UpLinkLosses> createState() => StateUpLinkLosses();
}

class StateUpLinkLosses extends State<UpLinkLosses> {
  final _formKey = GlobalKey<FormState>();
  final _tableKey = GlobalKey<DynamicTableState>();
  final _rowNoController = TextEditingController();
  final _tpController = TextEditingController();
  List<List<String>> _tableData = [];
  String _configSelected = '';
  String _testPhaseSelected = '';
  List<String> _configNames = [];
  List<String> _testPhases = [];
  String _sourceTestPhaseSelected = '';
  
  List<String> _selectedConfigs = [];
  Map<String, List<List<String>>> _multiTableData = {};
  Map<String, GlobalKey<DynamicTableState>> _multiTableKeys = {};
  Map<String, TextEditingController> _multiRowNoControllers = {};
  
  String? _editingTableCfg;
  int? _editingRow;
  int? _editingCol;

  void sendRequest() async {
    try {
      ValueRequest txReq = ValueRequest();
      txReq.id = widget.global.clientID;
      txReq.key = widget.global.tableSelected == Tables.uplinkLoss ? "UplinkConfigs" : "DownlinkConfigs";
      final txResp = await http.post(
        Uri.parse('http://127.0.0.1:8085/getValues'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(txReq.toJSON()),
      );
      if (txResp.statusCode == 200) {
        var temp = ValueResponse.fromJson(
            jsonDecode(txResp.body) as Map<String, dynamic>);
        if (temp.ok) {
          _configNames = [];
          _configNames.addAll(temp.values);
          _configSelected = _configNames.isNotEmpty ? _configNames.first : "";
          if (widget.isCopyMode) {
            _selectedConfigs = [];
          }
        } else {
          showMessage(temp.message, true);
          return;
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
        return;
      }
      ValueRequest rxReq = ValueRequest();
      rxReq.id = widget.global.clientID;
      rxReq.key = "TestPhases";
      final rxResp = await http.post(
        Uri.parse('http://127.0.0.1:8085/getValues'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(rxReq.toJSON()),
      );
      if (rxResp.statusCode == 200) {
        var temp = ValueResponse.fromJson(
            jsonDecode(rxResp.body) as Map<String, dynamic>);
        if (temp.ok) {
          _testPhases = [];
          _testPhases.addAll(temp.values);
          _testPhaseSelected = _testPhases.isNotEmpty ? _testPhases.first : "";
          _tpController.text = _testPhaseSelected;
          if (widget.isCopyMode) {
            _sourceTestPhaseSelected = _testPhases.isNotEmpty ? _testPhases.first : "";
          }
        } else {
          showMessage(temp.message, true);
          return;
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
        return;
      }
      RowDisplayRequest req = RowDisplayRequest();
      req.id = widget.global.clientID;
      var tableName = getTableName(widget.global.tableSelected);
      req.tableName = tableName;
      req.primaryKey = widget.global.rowSelected;

      if (widget.global.rowSelected == '') {
        if (mounted) setState(() {});
        if (widget.isCopyMode) _fetchSourceLossMulti();
        return;
      }

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8085/getRows'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(req.toJSON()),
      );

      if (response.statusCode == 200) {
        var temp = RowDisplayDetails.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
        if (temp.ok) {
          _configSelected = temp.values[0];
          _testPhaseSelected = temp.values[1];
          _tpController.text = _testPhaseSelected;
          _tableData.clear();
          if (temp.values.length > 2 && temp.values[2].isNotEmpty) {
            var lines = temp.values[2].split('\n');
            for (var line in lines) {
              var cols = line.split(',');
              if (cols.length >= 4) {
                _tableData.add([cols[0], cols[1], cols[2], cols[3]]);
              }
            }
          }
          setState(() {});
        } else {
          showMessage(temp.message, true);
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
      }
    } on Exception catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
    }
  }

  @override
  void initState() {
    super.initState();
    sendRequest();
  }

  void downloadAsExcel() {
    if (_tableData.isEmpty) {
      showMessage("No data to export", true);
      return;
    }
    Excel excel = Excel.createExcel();
    var sheet1 = excel['Sheet1'];
    // Only Profile fields
    for (int i = 0; i < _tableData.length; i++) {
      List<CellValue> row = [];
      for (int j = 0; j < _tableData[i].length; j++) {
        row.add(TextCellValue(_tableData[i][j]));
      }
      sheet1.appendRow(row);
    }
    var fileName = '${_configSelected}_${_testPhaseSelected}.xlsx';
    var dataBytes = excel.save(fileName: fileName) ?? [];
    FileSaver.instance.saveFile(name: fileName, bytes: Uint8List.fromList(dataBytes));
  }

  Widget getButton(BuildContext context) {
    bool isNew = widget.global.rowSelected.trim().isEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                widget.global.subMode = SubModes.showTables;
                widget.callback();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Cancel", style: TextStyle(color: Colors.black87)),
            ),
          ),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: downloadAsExcel,
              icon: const Icon(Icons.download, size: 20, color: Colors.green),
              label: const Text("Export Excel", style: TextStyle(color: Colors.green)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                if (!_formKey.currentState!.validate()) {
                  showMessage("Please check the inputs", true);
                  return;
                }
                update(!isNew);
              },
              icon: Icon(isNew ? Icons.add : Icons.save, size: 20),
              label: Text(isNew ? "Insert" : "Save Changes"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableForConfig(String cfg, List<List<String>> data, GlobalKey<DynamicTableState> tKey, TextEditingController tController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: tController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Serial No',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () {
                  var rowNo = tController.text;
                  int row = 0;
                  try {
                    row = int.parse(rowNo);
                    if (row > 0) row = row - 1; // 1-indexed to 0-indexed
                  } on Exception {
                    row = data.length;
                  }
                  if (row > data.length) row = data.length;
                  data.insert(row, ['', '', '', '']);
                  setState(() {});
                },
                label: const Text("Add Row"),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Sl. No")),
              DataColumn(label: Text("Description")),
              DataColumn(label: Text("Loss (dB)")),
              DataColumn(label: Text("Category")),
              DataColumn(label: Text("Delete")),
            ],
            rows: data.asMap().entries.map((entry) {
              int rowIndex = entry.key;
              List<String> row = entry.value;
              row[0] = '${rowIndex + 1}';
              return DataRow(
                cells: [
                  DataCell(Text(row[0])),
                  _buildDataCell(cfg, data, rowIndex, 1, row[1]),
                  _buildDataCell(cfg, data, rowIndex, 2, row[2]),
                  _buildDataCell(cfg, data, rowIndex, 3, row[3], isDropdown: true),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          data.removeAt(rowIndex);
                        });
                      },
                    )
                  )
                ]
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  DataCell _buildDataCell(String cfg, List<List<String>> data, int rowIndex, int colIndex, String value, {bool isDropdown = false}) {
    bool isEditing = _editingTableCfg == cfg && _editingRow == rowIndex && _editingCol == colIndex;
    if (isEditing) {
      if (isDropdown) {
        return DataCell(
          DropdownButtonFormField<String>(
            value: value.isEmpty ? null : (['SA', 'Common', 'PM', 'Sc'].contains(value) ? value : null),
            items: ['SA', 'Common', 'PM', 'Sc'].map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(val),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                data[rowIndex][colIndex] = val ?? '';
                _editingTableCfg = null;
                _editingRow = null;
                _editingCol = null;
              });
            },
          )
        );
      } else {
        return DataCell(
          TextFormField(
            initialValue: value,
            autofocus: true,
            onChanged: (val) {
               data[rowIndex][colIndex] = val;
            },
            onFieldSubmitted: (val) {
              setState(() {
                _editingTableCfg = null;
                _editingRow = null;
                _editingCol = null;
              });
            },
          )
        );
      }
    } else {
      return DataCell(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: () {
            setState(() {
              _editingTableCfg = cfg;
              _editingRow = rowIndex;
              _editingCol = colIndex;
            });
          },
          child: Container(
             padding: const EdgeInsets.symmetric(vertical: 8),
             constraints: const BoxConstraints(minWidth: 80, minHeight: 40),
             alignment: Alignment.centerLeft,
             child: Text(value.isEmpty ? 'DoubleClick to edit' : value, style: TextStyle(color: value.isEmpty ? Colors.grey.shade400 : Colors.black87)),
          )
        )
      );
    }
  }

  List<Widget> getChildren(BuildContext context) {
    List<Widget> children = [];

    if (widget.global.rowSelected.isEmpty) {
      if (widget.isCopyMode) {
        children.add(Column(
          children: [
            Row(
              children: [
                Expanded(child: _getTPDD()),
                const SizedBox(width: 16),
                Expanded(child: _getSourceTPDD()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _getMultiConfigSelector()),
              ],
            ),
          ],
        ));
      } else {
        children.add(Row(
          children: [
            Expanded(child: _getTPDD()),
            const SizedBox(width: 16),
            Expanded(child: _getConfigDD()),
          ],
        ));
      }
    } else {
      children.add(Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.indigo.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Test Phase", style: TextStyle(fontSize: 12, color: Colors.indigo)),
                Text(_testPhaseSelected, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Container(width: 1, height: 30, color: Colors.grey.shade300),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Configuration", style: TextStyle(fontSize: 12, color: Colors.indigo)),
                Text(_configSelected, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ));
    }

    if (widget.global.rowSelected.isEmpty && widget.isCopyMode) {
      for (String cfg in _selectedConfigs) {
        if (!_multiTableData.containsKey(cfg)) continue;
        var cData = _multiTableData[cfg]!;

        if (!_multiTableKeys.containsKey(cfg)) {
          _multiTableKeys[cfg] = GlobalKey<DynamicTableState>();
          _multiRowNoControllers[cfg] = TextEditingController();
        }
        var table = _buildTableForConfig(cfg, cData, _multiTableKeys[cfg]!, _multiRowNoControllers[cfg]!);
        
        children.add(const SizedBox(height: 24));
        children.add(Text("Loss Profile: $cfg", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)));
        children.add(const SizedBox(height: 8));
        children.add(Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
          child: table,
        ));
      }
    } else {
      children.add(const SizedBox(height: 24));
      var table = _buildTableForConfig(_configSelected, _tableData, _tableKey, _rowNoController);
      children.add(Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
        child: table,
      ));
    }

    return children;
  }

  void update(bool edit) async {
    var clientID = widget.global.clientID;
    var tableName = getTableName(widget.global.tableSelected);
    
    if (widget.isCopyMode) {
      bool allOk = true;
      for (String cfg in _selectedConfigs) {
        List<String> values = [cfg, _testPhaseSelected];
        var loss = "";
        if (_multiTableData[cfg] != null) {
          for (var line in _multiTableData[cfg]!) {
            for (var col in line) loss += "$col,";
            loss = loss.substring(0, loss.length - 1) + "\n";
          }
        }
        if (loss.isNotEmpty) loss = loss.substring(0, loss.length - 1);
        
        values.add(loss);
        
        var okReq = await sendAddRequest(clientID, tableName, values);
        if (!okReq) allOk = false;
      }
      if (allOk) {
        widget.global.subMode = SubModes.showTables;
        widget.callback();
      }
      return;
    }

    List<String> values = [];

    values.add(_configSelected);
    values.add(_testPhaseSelected);
    var loss = "";
    for (var line in _tableData) {
      for (var col in line) {
        loss = "$loss$col,";
      }
      loss = loss.substring(0, loss.length - 1);
      loss = "$loss\n";
    }
    if (loss.isNotEmpty) loss = loss.substring(0, loss.length - 1);
    values.add(loss);
    if (edit) {
      var ok = await sendUpdateRequest(clientID, tableName, values,
          primaryKey: widget.global.rowSelected);
      if (ok) {
        widget.global.subMode = SubModes.showTables;
        widget.callback();
      }
    } else {
      var ok = await sendAddRequest(clientID, tableName, values);
      if (ok) {
        widget.global.subMode = SubModes.showTables;
        widget.callback();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var children = getChildren(context);
    var button = getButton(context);
    
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
             decoration: BoxDecoration(
               color: Colors.white,
               border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
             ),
             child: Text(
               widget.isCopyMode ? "Copy Loss Profile" : (widget.global.rowSelected.isEmpty ? "Create Loss Profile" : "Edit Loss Profile"), 
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
             ),
          ),
          
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ),
          
          Container(
             decoration: BoxDecoration(
               color: Colors.grey.shade50,
               border: Border(top: BorderSide(color: Colors.grey.shade200)),
             ),
             child: button
          ),
        ],
      ),
    );
  }

  Widget _getTPDD() {
    return TextFormField(
      controller: _tpController,
      onChanged: (val) {
        _testPhaseSelected = val;
      },
      decoration: InputDecoration(
        labelText: "Test Phase",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down),
          onSelected: (String value) {
            _tpController.text = value;
            _testPhaseSelected = value;
            setState(() {});
          },
          itemBuilder: (BuildContext context) {
            return _testPhases.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _getConfigDD() {
    List<DropdownMenuItem<String>> items = [];
    for (String cfg in _configNames) {
      items.add(DropdownMenuItem(value: cfg, child: Text(cfg)));
    }
    return DropdownButtonFormField<String>(
      items: items,
      value: _configSelected.isEmpty && _configNames.isNotEmpty ? _configNames.first : _configSelected,
      onChanged: (value) {
        _configSelected = value ?? "";
        setState(() {});
      },
      decoration: InputDecoration(
        labelText: "Configuration",
        filled: true,
        fillColor: Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _getSourceTPDD() {
    List<DropdownMenuItem<String>> items = [];
    for (String tp in _testPhases) {
      items.add(DropdownMenuItem(value: tp, child: Text(tp)));
    }
    return DropdownButtonFormField<String>(
      items: items,
      value: _sourceTestPhaseSelected.isEmpty && _testPhases.isNotEmpty ? _testPhases.first : _sourceTestPhaseSelected,
      onChanged: (value) {
        _sourceTestPhaseSelected = value ?? "";
        _multiTableData.clear();
        _fetchSourceLossMulti();
        setState(() {});
      },
      decoration: InputDecoration(
        labelText: "Source Test Phase (To Copy From)",
        filled: true,
        fillColor: Colors.blue.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _getMultiConfigSelector() {
    return InkWell(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  title: const Text("Select Configurations"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _configNames.map((cfg) {
                        return CheckboxListTile(
                          title: Text(cfg),
                          value: _selectedConfigs.contains(cfg),
                          onChanged: (val) {
                            setStateDialog(() {
                              if (val == true) {
                                _selectedConfigs.add(cfg);
                              } else {
                                _selectedConfigs.remove(cfg);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Done"),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                );
              },
            );
          },
        );
        setState(() {});
        _fetchSourceLossMulti();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.04),
          border: Border.all(color: Colors.blue.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(_selectedConfigs.isEmpty ? "Select Configs" : "\${_selectedConfigs.length} Selected"),
             const Icon(Icons.arrow_drop_down, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  void _fetchSourceLossMulti() async {
    if (_sourceTestPhaseSelected.isEmpty) return;

    for (String cfg in _selectedConfigs) {
      if (!_multiTableData.containsKey(cfg)) {
        _multiTableData[cfg] = [];
        RowDisplayRequest req = RowDisplayRequest();
        req.id = widget.global.clientID;
        req.tableName = getTableName(widget.global.tableSelected);
        req.primaryKey = '$cfg:::$_sourceTestPhaseSelected';

        try {
          final response = await http.post(
            Uri.parse('http://127.0.0.1:8085/getRows'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(req.toJSON()),
          );

          if (response.statusCode == 200) {
            var temp = RowDisplayDetails.fromJson(jsonDecode(response.body));
            if (temp.ok) {
              if (temp.values.length > 2 && temp.values[2].isNotEmpty) {
                var lines = temp.values[2].split('\n');
                for (var line in lines) {
                  var cols = line.split(',');
                  if (cols.length >= 4) {
                    _multiTableData[cfg]!.add([cols[0], cols[1], cols[2], cols[3]]);
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('$e');
        }
      }
    }
    // Remove if unchecked
    _multiTableData.removeWhere((k, v) => !_selectedConfigs.contains(k));

    if (mounted) setState(() {});
  }
}
