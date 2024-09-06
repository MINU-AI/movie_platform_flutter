import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'logger.dart';

mixin NetworkService {
  Future<dynamic> get(String url, { Map<String, String>? headers, Map<String, String>? params, parseResponseBody = true }) async {
    var combineUrl = Uri.parse(url).replace(queryParameters: params).toString();
    _logRequest(combineUrl, headers: headers);
    final response = await http.get(Uri.parse(combineUrl), headers: headers);
    if (parseResponseBody) {
      return _parseBody(response);
    }
    return response.body;
  }

  Future<dynamic> post(String url, { Map<String, String>? headers, dynamic body, parseBodyToJson = true }) async {
    _logRequest(url, headers: headers, body: body);

    var jsonBody = body != null ? (parseBodyToJson ? jsonEncode(body) : body) : null;
    if(parseBodyToJson) {
      headers?.addAll({ "Content-Type" : "application/json"});
    }

    final response = await http.post(Uri.parse(url), headers: headers, body: jsonBody);
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