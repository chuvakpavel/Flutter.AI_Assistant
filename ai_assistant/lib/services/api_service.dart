import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ApiService {
  static Future<http.Response> get({
    required String uri,
    Map<String, String>? headers,
  }) async {
    http.Response response = await http.get(
      Uri.parse(uri),
      headers: headers,
    );
    if(response.statusCode == 200){
      return response;
    } else {
      throw Exception("Failed to get connection with client\n"
          "Status code: ${response.statusCode}\n");
    }

  }
}