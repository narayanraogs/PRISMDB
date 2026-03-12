class RegisterRequest {
  String id = '';
  String dbName = '';
  bool create = false;
  bool fromConfig = false;

  RegisterRequest();

  Map<String, dynamic> toJSON() {
    return {
      'ID': id,
      'DBName': dbName,
      'Create': create,
      'FromConfig': fromConfig,
    };
  }
}

class Ack {
  bool ok = false;
  String message = '';

  Ack();

  factory Ack.fromJson(Map<String, dynamic> jsonData) {
    var ack = Ack();
    ack.ok = jsonData['OK'] as bool? ?? false;
    ack.message = jsonData['Message'] as String? ?? '';
    return ack;
  }
}

class ClientID {
  String id = '';

  ClientID();

  Map<String, dynamic> toJSON() {
    return {'ID': id};
  }
}

class SingleCategoryDetails {
  String categoryName = '';
  int items = 0;

  SingleCategoryDetails();

  factory SingleCategoryDetails.fromJson(Map<String, dynamic> jsonData) {
    var single = SingleCategoryDetails();
    single.categoryName = jsonData['CategoryName'] as String;
    single.items = jsonData['Items'] as int;
    return single;
  }
}

class Categories {
  List<SingleCategoryDetails> singleCategories = [];
  bool ok = false;
  String message = '';

  Categories();

  factory Categories.fromJson(Map<String, dynamic> jsonData) {
    var category = Categories();
    var ok = jsonData['OK'] as bool;
    var msg = jsonData['Message'] as String;
    if (ok) {
      var list = jsonData['SingleCategories'] as List;
      category.singleCategories = list
          .map((e) => SingleCategoryDetails.fromJson(e))
          .toList();
    }
    category.ok = ok;
    category.message = msg;
    return category;
  }
}

class TableDisplayDetails {
  String tableName = '';
  List<String> primaryKey = [];
  List<String> header = [];
  List<RowDetails> details = [];
  bool ok = false;
  String message = '';

  TableDisplayDetails();

  factory TableDisplayDetails.fromJson(Map<String, dynamic> jsonData) {
    var single = TableDisplayDetails();
    single.tableName = jsonData['TableName'] as String;
    var listPK = jsonData['PrimaryKey'] as List;
    var pks = listPK.map((e) => e as String);
    single.primaryKey.addAll(pks);
    var listHeader = jsonData['Header'] as List;
    var headers = listHeader.map((e) => e as String);
    single.header.addAll(headers);
    var listDetails = jsonData['Rows'] as List;
    var details = listDetails.map((e) => RowDetails.fromJson(e));
    single.details.addAll(details);
    single.ok = jsonData['OK'] as bool;
    single.message = jsonData['Message'] as String;
    return single;
  }
}

class RowDetails {
  List<String> details = [];

  RowDetails();

  factory RowDetails.fromJson(Map<String, dynamic> jsonData) {
    var row = RowDetails();
    var listDetails = jsonData['Details'] as List;
    var details = listDetails.map((e) => e as String);
    row.details.addAll(details);
    return row;
  }
}

class TableDisplayRequest {
  String id = '';
  String tableName = '';

  TableDisplayRequest();

  Map<String, dynamic> toJSON() {
    return {'ID': id, 'TableName': tableName};
  }
}

class RowDisplayRequest {
  String id = '';
  String tableName = '';
  String primaryKey = '';

  RowDisplayRequest();

  Map<String, dynamic> toJSON() {
    return {'ID': id, 'TableName': tableName, 'PrimaryKey': primaryKey};
  }
}

class RowDisplayDetails {
  List<String> values = [];
  bool ok = false;
  String message = '';

  RowDisplayDetails();

  factory RowDisplayDetails.fromJson(Map<String, dynamic> jsonData) {
    var single = RowDisplayDetails();
    var listValue = jsonData['Values'] as List;
    var val = listValue.map((e) => e as String);
    single.values.addAll(val);
    single.ok = jsonData['OK'] as bool;
    single.message = jsonData['Message'] as String;
    return single;
  }
}

class ValueRequest {
  String id = '';
  String key = '';

  ValueRequest();

  Map<String, dynamic> toJSON() {
    return {'ID': id, 'Key': key};
  }
}

class ValueResponse {
  List<String> values = [];
  bool ok = false;
  String message = '';

  ValueResponse();

  factory ValueResponse.fromJson(Map<String, dynamic> jsonData) {
    var single = ValueResponse();
    var listValue = jsonData['Values'] as List;
    var val = listValue.map((e) => e as String);
    single.values.addAll(val);
    single.ok = jsonData['OK'] as bool;
    single.message = jsonData['Message'] as String;
    return single;
  }
}

class SingleValueResponse {
  String value = "";
  bool ok = false;
  String message = '';

  SingleValueResponse();

  factory SingleValueResponse.fromJson(Map<String, dynamic> jsonData) {
    var single = SingleValueResponse();
    single.value = jsonData['Values'] as String;
    single.ok = jsonData['OK'] as bool;
    single.message = jsonData['Message'] as String;
    return single;
  }
}

class UpdateRequest {
  String id = "";
  String tableName = "";
  String primaryKey = "";
  List<String> values = [];

  Map<String, dynamic> toJSON() {
    return {
      "ID": id,
      "TableName": tableName,
      "PrimaryKey": primaryKey,
      "Values": values,
    };
  }
}

class SingleTableDetails {
  String tableName = '';
  int items = 0;
  int errors = 0;
  int warnings = 0;
  List<String> errorList = [];
  List<String> warningList = [];

  SingleTableDetails();

  factory SingleTableDetails.fromJson(Map<String, dynamic> jsonData) {
    var single = SingleTableDetails();
    single.tableName = jsonData['TableName'] as String;
    single.items = jsonData['Items'] as int;
    single.errors = jsonData['Errors'] as int;
    single.warnings = jsonData['Warnings'] as int;

    if (jsonData['ErrorList'] != null) {
      single.errorList = List<String>.from(jsonData['ErrorList']);
    }
    if (jsonData['WarningList'] != null) {
      single.warningList = List<String>.from(jsonData['WarningList']);
    }

    return single;
  }
}

class ValidationResult {
  List<SingleTableDetails> singleTables = [];
  bool ok = false;
  String message = '';

  ValidationResult();

  factory ValidationResult.fromJson(Map<String, dynamic> jsonData) {
    var val = ValidationResult();
    var ok = jsonData['OK'] as bool;
    var msg = jsonData['Message'] as String;
    if (ok) {
      var list = jsonData['SingleTables'] as List;
      val.singleTables = list
          .map((e) => SingleTableDetails.fromJson(e))
          .toList();
    }
    val.ok = ok;
    val.message = msg;
    return val;
  }
}

class RenameRequest {
  String id = '';
  String operation = '';
  String operationType = '';
  String oldName = '';
  String newName = '';

  RenameRequest();

  Map<String, dynamic> toJSON() {
    return {
      'ID': id,
      'Operation': operation,
      'Type': operationType,
      'OldName': oldName,
      'NewName': newName,
    };
  }
}

class CreateRequest {
  String dbPath = '';

  List<String> rxNames = [];
  List<double> rxFrequencies = [];
  List<String> rxModulation = [];

  List<String> txNames = [];
  List<double> txFrequencies = [];
  List<double> txPowers = [];
  List<String> txModulation = [];

  List<String> tpNames = [];
  List<String> tpRxNames = [];
  List<String> tpTxNames = [];

  List<String> plNames = [];

  List<String> configNames = [];
  List<String> configTypes = [];
  List<String> configRxNames = [];
  List<String> configTxNames = [];
  List<String> configTPNames = [];
  List<String> configPlNames = [];

  bool create = false;
  bool ok = false;
  String message = "";

  CreateRequest();

  Map<String, dynamic> toJSON() {
    return {
      'DBPath': dbPath,
      'RxNames': rxNames,
      'RxFrequencies': rxFrequencies,
      'RxModulation': rxModulation,
      'TxNames': txNames,
      'TxFrequencies': txFrequencies,
      'TxPowers': txPowers,
      'TxModulation': txModulation,
      'TPNames': tpNames,
      'TPRxNames': tpRxNames,
      'TPTxNames': tpTxNames,
      'PlNames': plNames,
      'ConfigNames': configNames,
      'ConfigTypes': configTypes,
      'ConfigRxNames': configRxNames,
      'ConfigTxNames': configTxNames,
      'ConfigTPNames': configTPNames,
      'ConfigPlNames': configPlNames,
      'Create': create,
      'OK': ok,
      'Message': message,
    };
  }

  factory CreateRequest.fromJson(Map<String, dynamic> jsonData) {
    var create = CreateRequest();
    create.dbPath = jsonData['DBPath'] as String;
    var list = jsonData['RxNames'] as List?;
    if (list != null) {
      for (var l in list) {
        String temp = l as String;
        create.rxNames.add(temp);
      }
    }
    list = jsonData['RxFrequencies'] as List?;
    if (list != null) {
      for (var l in list) {
        double temp = 0;
        try {
          temp = l as double;
        } catch (e) {
          int i = l as int;
          temp = i * 1.0;
        }
        create.rxFrequencies.add(temp);
      }
    }
    list = jsonData['RxModulation'] as List?;
    if (list != null) {
      for (var l in list) {
        String temp = l as String;
        create.rxModulation.add(temp);
      }
    }
    list = jsonData['TxNames'] as List?;
    if (list != null) {
      for (var l in list) {
        String temp = l as String;
        create.txNames.add(temp);
      }
    }
    list = jsonData['TxFrequencies'] as List?;
    if (list != null) {
      for (var l in list) {
        double temp = 0;
        try {
          temp = l as double;
        } catch (e) {
          int i = l as int;
          temp = i * 1.0;
        }
        create.txFrequencies.add(temp);
      }
    }
    list = jsonData['TxPowers'] as List?;
    if (list != null) {
      for (var l in list) {
        double temp = 0;
        try {
          temp = l as double;
        } catch (e) {
          int i = l as int;
          temp = i * 1.0;
        }
        create.txPowers.add(temp);
      }
    }
    list = jsonData['TxModulation'] as List?;
    if (list != null) {
      for (var l in list) {
        String temp = l as String;
        create.txModulation.add(temp);
      }
    }
    list = jsonData['TPNames'] as List?;
    if (list != null) {
      for (var l in list) {
        String temp = l as String;
        create.tpNames.add(temp);
      }
    }
    list = jsonData['TPRxNames'] as List?;
    if (list != null) {
      for (var l in list) {
        String temp = l as String;
        create.tpRxNames.add(temp);
      }
    }
    list = jsonData['TPTxNames'] as List?;
    if (list != null) {
      for (var l in list) {
        String temp = l as String;
        create.tpTxNames.add(temp);
      }
    }
    list = jsonData['PlNames'] as List?;
    if (list != null) {
      for (var l in list) {
        String temp = l as String;
        create.plNames.add(temp);
      }
    }
    list = jsonData['ConfigNames'] as List?;
    if (list != null) {
      for (var l in list) {
        String temp = l as String;
        create.configNames.add(temp);
      }
    }
    list = jsonData['ConfigTypes'] as List?;
    if (list != null) {
      for (var l in list) {
        String temp = l as String;
        create.configTypes.add(temp);
      }
    }
    list = jsonData['ConfigRxNames'] as List?;
    if (list != null) {
      for (var l in list) {
        String temp = l as String;
        create.configRxNames.add(temp);
      }
    }
    list = jsonData['ConfigTxNames'] as List?;
    if (list != null) {
      for (var l in list) {
        String temp = l as String;
        create.configTxNames.add(temp);
      }
    }
    list = jsonData['ConfigTPNames'] as List?;
    if (list != null) {
      for (var l in list) {
        String temp = l as String;
        create.configTPNames.add(temp);
      }
    }
    list = jsonData['ConfigPlNames'] as List?;
    if (list != null) {
      for (var l in list) {
        String temp = l as String;
        create.configPlNames.add(temp);
      }
    }

    create.create = jsonData['Create'] as bool;
    create.ok = jsonData['OK'] as bool;
    create.message = jsonData['Message'] as String;

    return create;
  }
}
