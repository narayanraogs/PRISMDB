import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:prism_db_editor/structures.dart';
import 'package:prism_db_editor/variables.dart';
import 'package:http/http.dart' as http;

void showMessage(String message, bool error) {
  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
      ),
      backgroundColor: error ? Colors.redAccent : Colors.greenAccent,
    ),
  );
}

Tables getTableSelected(String tableName) {
  switch (tableName.toLowerCase()) {
    case 'transmitter':
      return Tables.specTx;
    case 'txharmonics':
      return Tables.specTxHarmonics;
    case 'txsubcarriers':
      return Tables.specTxSubCarriers;
    case 'receiver':
      return Tables.specRx;
    case 'receivertm':
      return Tables.specRxTM;
    case 'transponder':
      return Tables.specTransponder;
    case 'tpranging':
      return Tables.specTransponderRanging;
    case 'testphase':
      return Tables.testPhases;
    case 'downlinkloss':
      return Tables.downLinkLoss;
    case 'uplinkloss':
      return Tables.uplinkLoss;
    case 'devices':
      return Tables.devices;
    case 'obwpower':
      return Tables.obwPowerProfile;
    case 'frequencyprofile':
      return Tables.frequencyProfile;
    case 'powerprofile':
      return Tables.powerProfile;
    case 'spectrumsettings':
      return Tables.spectrumSettings;
    case 'tmprofile':
      return Tables.tmProfile;
    case 'deviceprofile':
      return Tables.deviceProfile;
    case 'tsmconfigurations':
      return Tables.tsmConfigurations;
    case 'configurations':
      return Tables.configurations;
    case 'tests':
      return Tables.tests;
    case 'cablecalibration':
      return Tables.cableCalibrationFrequencies;
    case 'updownconverter':
      return Tables.upDownConverter;
    case 'specpl':
      return Tables.specPL;
    case 'downlinkpowerprofile':
      return Tables.downLinkPowerProfile;
    case 'pulseprofile':
      return Tables.pulseProfile;
    case 'trmprofile':
      return Tables.trmProfile;
    case 'spectrumprofile':
      return Tables.spectrumProfile;
    case 'lossmeasurementfrequencies':
      return Tables.lossMeasurementFrequencies;
    default:
      return Tables.noTable;
  }
}

String getTableName(Tables tableName) {
  switch (tableName) {
    case Tables.cableCalibrationFrequencies:
      return 'CableCalibrationFrequencies';
    case Tables.obwPowerProfile:
      return 'OBWPowerProfile';
    case Tables.configurations:
      return 'Configurations';
    case Tables.deviceProfile:
      return 'DeviceProfile';
    case Tables.devices:
      return 'Devices';
    case Tables.downLinkLoss:
      return 'DownlinkLoss';
    case Tables.frequencyProfile:
      return 'FrequencyProfile';
    case Tables.powerProfile:
      return 'PowerProfile';
    case Tables.specRx:
      return 'SpecRx';
    case Tables.specRxTM:
      return 'SpecRxTM';
    case Tables.specTransponder:
      return 'SpecTp';
    case Tables.specTransponderRanging:
      return 'SpecTpRanging';
    case Tables.specTx:
      return 'SpecTx';
    case Tables.specTxHarmonics:
      return 'SpecTxHarmonics';
    case Tables.specTxSubCarriers:
      return 'SpecTxSubCarriers';
    case Tables.spectrumSettings:
      return 'SpectrumSettings';
    case Tables.tmProfile:
      return 'TMProfile';
    case Tables.tsmConfigurations:
      return 'TSMConfigurations';
    case Tables.testPhases:
      return 'TestPhases';
    case Tables.tests:
      return 'Tests';
    case Tables.upDownConverter:
      return 'UpDownConverter';
    case Tables.uplinkLoss:
      return 'UplinkLoss';
    case Tables.specPL:
      return 'SpecPL';
    case Tables.downLinkPowerProfile:
      return 'DownlinkPowerProfile';
    case Tables.pulseProfile:
      return 'PulseProfile';
    case Tables.trmProfile:
      return 'TRMProfile';
    case Tables.spectrumProfile:
      return 'SpectrumProfile';
    case Tables.lossMeasurementFrequencies:
      return 'LossMeasurementFrequencies';
    case Tables.noTable:
      return '';
  }
}

TableRow getTableRow(Widget child) {
  var tableRow = TableRow(
    children: [child],
  );
  return tableRow;
}

TableRow getTableRowMulti(List<Widget> children) {
  var table = Table(
    children: [
      TableRow(
        children: children,
      ),
    ],
  );
  return TableRow(
    children: [table],
  );
}

double getFrequency(String frequency, String resolution) {
  try {
    var freq = double.parse(frequency);
    switch (resolution.toLowerCase()) {
      case 'khz':
        freq = freq * 1000;
      case 'mhz':
        freq = freq * 1000 * 1000;
      case 'ghz':
        freq = freq = freq * 1000 * 1000 * 1000;
    }
    return freq;
  } catch (e) {
    return 0.0;
  }
}

Future<bool> sendAddRequest(
    String clientID, String tableName, List<String> values) async {
  UpdateRequest req = UpdateRequest();
  req.id = clientID;
  req.tableName = tableName;
  req.values.addAll(values);
  try {
    final response = await http.post(
      Uri.parse('http://localhost:8085/addRow'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(req.toJSON()),
    );
    if (response.statusCode == 200) {
      var ack = Ack.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      showMessage(ack.message, !ack.ok);
      return ack.ok;
    } else {
      showMessage("Request Error to server", true);
      return false;
    }
  } catch (e) {
    showMessage("Server Request Failed", true);
    return false;
  }
}

Future<bool> sendUpdateRequest(
    String clientID, String tableName, List<String> values,
    {String primaryKey = ""}) async {
  UpdateRequest req = UpdateRequest();
  req.id = clientID;
  req.tableName = tableName;
  req.primaryKey = primaryKey;
  req.values.addAll(values);
  try {
    final response = await http.post(
      Uri.parse('http://localhost:8085/updateRow'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(req.toJSON()),
    );
    if (response.statusCode == 200) {
      var ack = Ack.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      showMessage(ack.message, !ack.ok);
      return ack.ok;
    } else {
      showMessage("Request Error to server", true);
      return false;
    }
  } catch (e) {
    showMessage("Server Request Failed", true);
    return false;
  }
}

Future<bool> sendDeleteRequest(
    String clientID, String tableName, String primaryKey) async {
  RowDisplayRequest req = RowDisplayRequest();
  req.id = clientID;
  req.tableName = tableName;
  req.primaryKey = primaryKey;
  try {
    final response = await http.post(
      Uri.parse('http://localhost:8085/deleteRow'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(req.toJSON()),
    );
    if (response.statusCode == 200) {
      var ack = Ack.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      showMessage(ack.message, !ack.ok);
      return ack.ok;
    } else {
      showMessage("Request Error to server", true);
      return false;
    }
  } catch (e) {
    showMessage("Server Request Failed", true);
    return false;
  }
}

String getDouble(String value) {
  var d = 0.0;
  try {
    d = double.parse(value);
  } catch (e) {
    d = 0.0;
  }
  return '$d';
}

String getInt(String value) {
  var d = 0;
  try {
    d = int.parse(value);
  } catch (e) {
    d = 0;
  }
  return '$d';
}


String getLossStringFromBytes(Uint8List bytes) {
  var excel = Excel.decodeBytes(bytes);
  String lossString = "";
  for (var table in excel.tables.keys) {
    if (excel.tables[table] == null) continue;
    for (var row in excel.tables[table]!.rows) {
      for (int i = 0; i < row.length; i++) {
        var cell = row[i];
        if (cell != null) {
          lossString += "\${cell.value},";
        } else {
          lossString += ",";
        }
      }
      if (lossString.endsWith(",")) {
        lossString = lossString.substring(0, lossString.length - 1);
      }
      lossString += "\n";
    }
  }
  return lossString;
}
