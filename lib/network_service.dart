import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'logger.dart';

mixin NetworkService {
  Future<dynamic> get(String url, { Map<String, String>? headers }) async {
    _logRequest(url, headers: headers);
    final response = await http.get(Uri.parse(url), headers: headers);
    return _parseBody(response);
  }

  Future<dynamic> post(String url, { Map<String, String>? headers, dynamic body }) async {
    _logRequest(url, headers: headers, body: body);

    var modifiedBody = body != null ? jsonEncode(body) : null;

    final response = await http.post(Uri.parse(url), headers: headers, body: modifiedBody);
    return _parseBody(response);
  }

  dynamic _parseBody(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;
    if (statusCode case 200 || 201 || 202) {
      dynamic responseJson = jsonDecode(body);
      return responseJson;
    }

    throw "Unsuccessful response - $statusCode: $body";
  }

  void _logRequest(String url, { Map<String, dynamic>? headers, dynamic body }) {
    logger.i("Rquest to: $url\n$headers\n$body");
  }


}