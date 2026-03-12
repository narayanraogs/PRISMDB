class Category {
  final String name;
  final int itemCount;

  const Category({required this.name, required this.itemCount});
  
  Map<String, dynamic> toJson() => {
    'CategoryName': name,
    'Items': itemCount,
  };
}

class TableData {
  final String tableName;
  final List<String> headers;
  final List<List<String>> rows;

  const TableData({
    required this.tableName,
    required this.headers,
    required this.rows,
  });
}

class ValidationSummary {
  final String tableName;
  final int items;
  final int errors;
  final int warnings;

  const ValidationSummary({
    required this.tableName,
    required this.items,
    required this.errors,
    required this.warnings,
  });
}
