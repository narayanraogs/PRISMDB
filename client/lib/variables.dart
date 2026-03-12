import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum Modes {
  connectToDatabase,
  frequentActions,
  showCategories,
  validateDatabase,
  backupDatabase,
  createDatabase,
}

enum SubModes{
  noSubMode,
  showTables,
  insertOrEditRow,
  deleteRow,
  selectTestPhase,
}

enum Tables {
  noTable,
  cableCalibrationFrequencies,
  obwPowerProfile,
  configurations,
  deviceProfile,
  devices,
  downLinkLoss,
  frequencyProfile,
  powerProfile,
  specRx,
  specRxTM,
  specTransponder,
  specTransponderRanging,
  specTx,
  specTxHarmonics,
  specTxSubCarriers,
  spectrumSettings,
  tmProfile,
  tsmConfigurations,
  testPhases,
  tests,
  upDownConverter,
  uplinkLoss,
  specPL,
  downLinkPowerProfile,
  pulseProfile,
  trmProfile,
  spectrumProfile,
  lossMeasurementFrequencies,
}

class Global {
  final String clientID;
  Modes mode = Modes.connectToDatabase;
  SubModes subMode = SubModes.noSubMode;
  Tables tableSelected = Tables.noTable;
  String rowSelected = '';
  List<String> rowValues = [];

  Global({String? clientID}) : clientID = clientID ?? '${DateTime.now().millisecondsSinceEpoch}';
}
