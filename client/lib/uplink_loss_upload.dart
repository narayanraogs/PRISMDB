import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:prism_db_editor/helper_functions.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

class UpLinkLossUpload extends StatefulWidget {
  final Global global;
  final VoidCallback callback;

  const UpLinkLossUpload(this.global, this.callback, {super.key});

  @override
  State<UpLinkLossUpload> createState() => StateUpLinkLossUpload();
}

class StateUpLinkLossUpload extends State<UpLinkLossUpload> {
  final _uploadPathController = TextEditingController();
  List<String> _uplinkConfigs = [];
  Map<String, bool> _uplinksSelected = {};
  String _testPhaseSelected = '';
  String _lossFromExcel = "";
  List<List<String>> _loss = [];

  void sendRequest() async {
    try {
      ValueRequest valReq = ValueRequest();
      valReq.id = widget.global.clientID;
      valReq.key = "UplinkConfigs";
      final resp = await http.post(
        Uri.parse('http://127.0.0.1:8085/getValues'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(valReq.toJSON()),
      );
      if (resp.statusCode == 200) {
        var temp = ValueResponse.fromJson(
            jsonDecode(resp.body) as Map<String, dynamic>);
        if (temp.ok) {
          _uplinkConfigs = [];
          _uplinkConfigs.addAll(temp.values);
          _uplinksSelected = {};
          for (String config in _uplinkConfigs) {
            _uplinksSelected[config] = false;
          }
        } else {
          showMessage(temp.message, true);
          return;
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
        return;
      }

      ValueRequest valReqTP = ValueRequest();
      valReqTP.id = widget.global.clientID;
      valReqTP.key = "SelectedTestPhase";
      final respTp = await http.post(
        Uri.parse('http://127.0.0.1:8085/getSingleValue'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(valReqTP.toJSON()),
      );
      if (respTp.statusCode == 200) {
        var temp = SingleValueResponse.fromJson(
            jsonDecode(respTp.body) as Map<String, dynamic>);
        if (temp.ok) {
          _testPhaseSelected = temp.value;
        } else {
          showMessage(temp.message, true);
          return;
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
        return;
      }
    } on Exception catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
    }
    setState(() {});
  }

  Future<bool> getLoss(String config) async {
    RowDisplayRequest req = RowDisplayRequest();
    req.id = widget.global.clientID;
    var tableName = "UplinkLoss";
    req.tableName = tableName;
    req.primaryKey = '$config:::$_testPhaseSelected';

    try {
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
          _loss = [];
          for (int i = 2; i < temp.values.length; i += 4) {
            List<String> row = [];
            row.add(temp.values[i]);
            row.add(temp.values[i + 1]);
            row.add(temp.values[i + 2]);
            row.add(temp.values[i + 3]);
            _loss.add(row);
          }
        } else {
          showMessage(temp.message, true);
          return false;
        }
      } else {
        showMessage("Server Returned Negative ACK", true);
        return false;
      }
    } on Exception catch (e) {
      debugPrint('$e');
      showMessage("Server Failed", true);
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    sendRequest();
  }

  void downloadAsExcel() async{

    var configSelected = '';
    for (int i = 0; i < _uplinkConfigs.length; i++) {
      if (_uplinksSelected[_uplinkConfigs[i]] ?? false) {
        configSelected = _uplinkConfigs[i];
        break;
      }
    }
    var ok = await getLoss(configSelected);
    if (!ok){
      return;
    }
    Excel excel = Excel.createExcel();
    var sheet1 = excel['Sheet1'];
    for (int i = 0; i < _loss.length; i++) {
      List<CellValue> row = [];
      for (int j = 0; j < _loss[i].length; j++) {
        CellValue val = TextCellValue(_loss[i][j]);
        row.add(val);
      }
      sheet1.appendRow(row);
    }
    var fileName = '${configSelected}_$_testPhaseSelected.xlsx';
    var data = excel.save(fileName: fileName) ?? [];
    FileSaver.instance
        .saveFile(name: fileName, bytes: Uint8List.fromList(data));
  }

  List<TableRow> getChildren(BuildContext context) {
    List<TableRow> children = [];

    int noOfConfigsSelected = 0;
    for (int i = 0; i < _uplinkConfigs.length; i++) {
      String config = _uplinkConfigs[i];
      if (_uplinksSelected[config] ?? false) {
        noOfConfigsSelected++;
      }
    }
    var header = Text(
      'Uplink Loss',
      style: Theme.of(context).textTheme.displaySmall,
      textAlign: TextAlign.center,
    );
    children.add(getTableRow(header));
    children.add(getTableRow(Text('')));
    var tp = Text(
      'Test Phase: $_testPhaseSelected',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    );
    children.add(getTableRow(tp));
    children.add(getTableRow(Text('')));
    var downloadBtn = ElevatedButton.icon(
        onPressed: (noOfConfigsSelected == 1) ? downloadAsExcel : null,
        label: const Text("Download Loss as Excel"),
        icon: const Icon(Icons.download));
    children.add(getTableRow(downloadBtn));

    var path = TextFormField(
      controller: _uploadPathController,
      decoration:
          const InputDecoration(hintText: "Click Browse to Upload Loss"),
    );
    var browse = ElevatedButton.icon(
      onPressed: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
            withData: true,
            type: FileType.custom,
            allowedExtensions: ['xlsx', 'xls']);
        if (result != null) {
          _uploadPathController.text = result.files.single.name;
          var data = result.files.single.bytes;
          if (data == null) {
            showMessage("Unable to read the file", true);
            return;
          }
          _lossFromExcel = getLossStringFromBytes(data);
        }
      },
      label: const Text("Browse"),
      icon: const Icon(Icons.upload_file_outlined),
    );
    children.add(getTableRowMulti([path, browse]));

    for (int i = 0; i < _uplinkConfigs.length; i++) {
      String config = _uplinkConfigs[i];
      var first = CheckboxListTile(
        value: _uplinksSelected[config],
        onChanged: (value) {
          _uplinksSelected[config] = value ?? false;
          setState(() {});
        },
        title: Text(config),
        controlAffinity: ListTileControlAffinity.leading,
      );
      i++;
      Widget second = Text('');
      if (i < _uplinkConfigs.length) {
        String config = _uplinkConfigs[i];
        second = CheckboxListTile(
          value: _uplinksSelected[config],
          onChanged: (value) {
            _uplinksSelected[config] = value ?? false;
            setState(() {});
          },
          title: Text(config),
          controlAffinity: ListTileControlAffinity.leading,
        );
      }
      children.add(getTableRowMulti([first, second]));
    }

    return children;
  }

  void update() async {
    var clientID = widget.global.clientID;
    var tableName = "UplinkLossExcel";
    List<String> values = [];
    var dataUpdated = true;
    for (var config in _uplinksSelected.keys) {
      if (!(_uplinksSelected[config] ?? false)) {
        continue;
      }
      values = [];
      values.add(config);
      values.add(_testPhaseSelected);
      values.add(_lossFromExcel);
      var primaryKey = '$config:::$_testPhaseSelected';
      debugPrint(primaryKey);
      var ok = await sendUpdateRequest(clientID, tableName, values,
          primaryKey: primaryKey);
      dataUpdated = dataUpdated && ok;
      if (!ok) {
       break;
      }
    }
    if (dataUpdated){
      showMessage("Losses Updated", false);
    }else{
      showMessage("Losses Cannot be Updated", true);
    }
  }

  @override
  Widget build(BuildContext context) {
    var children = getChildren(context);
    return SizedBox(
      width: 800,
      child: Card(
        child: Column(
          children: [
            Expanded(
              flex: 10,
              child: SingleChildScrollView(
                child: Table(
                  border: const TableBorder.symmetric(),
                  children: children,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: update,
              label: const Text('Submit'),
              icon: const Icon(Icons.check_box),
            ),
          ],
        ),
      ),
    );
  }
}
