import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';
import '../structures.dart';

const String _baseUrl = 'http://localhost:8085';

class ApiService {
  Future<bool> registerClient(String id, String dbName, bool fromConfig) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ID': id,
        'DBName': dbName,
        'Create': false,
        'FromConfig': fromConfig,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['OK'] == true;
    }
    return false;
  }

  Future<List<Category>> getCategories(String id) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/getCategories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ID': id,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['OK'] == true && data['SingleCategories'] != null) {
        final List categories = data['SingleCategories'];
        return categories.map((e) => Category(
          name: e['CategoryName'],
          itemCount: e['Items'],
        )).toList();
      }
    }
    return [];
  }

  Future<TableData?> getTableData(String id, String tableName) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/getTables'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ID': id,
        'TableName': tableName,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['OK'] == true) {
        // Parse rows from List<Row> where Row is { "Details": ["val1", "val2"] }
        List<List<String>> rows = [];
        if (data['Rows'] != null) {
          for (var r in data['Rows']) {
            if (r['Details'] != null) {
              rows.add(List<String>.from(r['Details']));
            }
          }
        }
        
        return TableData(
          tableName: data['TableName'],
          headers: List<String>.from(data['Header'] ?? []),
          rows: rows,
        );
      }
    }
    return null;
  }
  Future<bool> updateRow(String id, String tableName, String primaryKey, List<String> values) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/updateRow'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ID': id,
        'TableName': tableName,
        'PrimaryKey': primaryKey,
        'Values': values,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['OK'] == true;
    }
    return false;
  }

  Future<bool> addRow(String id, String tableName, List<String> values) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/addRow'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ID': id,
        'TableName': tableName,
        'Values': values,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['OK'] == true;
    }
    return false;
  }

  Future<bool> deleteRow(String id, String tableName, String primaryKey) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/deleteRow'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ID': id,
        'TableName': tableName,
        'PrimaryKey': primaryKey,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['OK'] == true;
    }
    return false;
  }

  Future<ValidationResult?> getValidationResults(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/validate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ID': id}),
      );
      if (response.statusCode == 200) {
        return ValidationResult.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
