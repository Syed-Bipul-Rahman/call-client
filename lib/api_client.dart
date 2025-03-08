/*
*
* Created By Syed Bipul Rahman
* All rights reserved
*
* */

import 'dart:convert';
import 'dart:io';
import 'package:call_agora_lock/enum_file.dart';
import 'package:call_agora_lock/prefs_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime_type/mime_type.dart';

import 'api_constants.dart';

class ApiClient extends GetxService {
  static final _client = http.Client();
  static const _timeout = Duration(seconds: 30);
  static String _bearerToken = "";
  static const _noInternet = "Can't connect to the internet!";

  Future<Response> _makeRequest(
      String url, String method, Map<String, dynamic>? body,
      {Map<String, String>? headers, List<MultipartBody>? files}) async {
    try {
      _bearerToken = await PrefsHelper.getString(AppConstants.BEARER_TOKEN.toString());
      final mainHeaders = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer $_bearerToken',
      };
      final finalHeaders = headers ?? mainHeaders;
      debugPrint('--> $method: $url\nHeaders: $finalHeaders\nBody: $body');
      http.Response response;

      switch (method) {
        case 'GET':
          response = await _client
              .get(Uri.parse(url), headers: finalHeaders)
              .timeout(_timeout);
          break;
        case 'POST':
          if (files != null && files.isNotEmpty) {
            response = await _postMultipart(
                url, body as Map<String, String>?, files, finalHeaders);
          } else {
            response = await _client
                .post(Uri.parse(url), headers: finalHeaders, body: body)
                .timeout(_timeout);
          }
          break;
        case 'PUT':
          response = await _client
              .put(Uri.parse(url),
                  headers: finalHeaders, body: jsonEncode(body))
              .timeout(_timeout);
          break;
        case 'PATCH':
          if (files != null && files.isNotEmpty) {
            response = await _patchMultipart(
                url, body as Map<String, String>?, files, finalHeaders);
          } else {
            response = await _client
                .patch(Uri.parse(url), headers: finalHeaders, body: body)
                .timeout(_timeout);
          }
          break;
        case 'DELETE':
          response = await _client
              .delete(Uri.parse(url), headers: finalHeaders, body: body)
              .timeout(_timeout);
          break;
        default:
          return Response(statusCode: 500, statusText: 'Invalid method');
      }
      return _handleResponse(response, url);
    } catch (e) {
      debugPrint('Error: $e');
      return const Response(statusCode: 0, statusText: _noInternet);
    }
  }

  Future<http.Response> _postMultipart(String url, Map<String, String>? fields,
      List<MultipartBody> files, Map<String, String> headers) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields.addAll(fields ?? {});
    request.headers.addAll(headers);

    for (var file in files) {
      String? mimeType = mime(file.file.path);
      request.files.add(http.MultipartFile(
          file.key, file.file.readAsBytes().asStream(), file.file.lengthSync(),
          filename: file.file.path.split('/').last,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null));
    }
    http.StreamedResponse response = await request.send();
    return await http.Response.fromStream(response);
  }

  Future<http.Response> _patchMultipart(String url, Map<String, String>? fields,
      List<MultipartBody> files, Map<String, String> headers) async {
    var request = http.MultipartRequest('PATCH', Uri.parse(url));
    request.fields.addAll(fields ?? {});
    request.headers.addAll(headers);

    for (var file in files) {
      String? mimeType = mime(file.file.path);
      request.files.add(http.MultipartFile(
          file.key, file.file.readAsBytes().asStream(), file.file.lengthSync(),
          filename: file.file.path.split('/').last,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null));
    }
    http.StreamedResponse response = await request.send();
    return await http.Response.fromStream(response);
  }

  Response _handleResponse(http.Response response, String url) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (e) {
      debugPrint('JSON Decode Error: $e');
    }

    debugPrint('<-- [${response.statusCode}] $url\nBody: ${response.body}');

    return Response(
      statusCode: response.statusCode,
      body: body ?? response.body,
      statusText: response.reasonPhrase,
    );
  }

  // GET
  Future<Response> getData(String uri, {Map<String, String>? headers}) =>
      _makeRequest(ApiConstants.baseUrl + uri, 'GET', null, headers: headers);

  // POST
  Future<Response> postData(String uri, dynamic body,
          {Map<String, String>? headers, List<MultipartBody>? files}) =>
      _makeRequest(ApiConstants.baseUrl + uri, 'POST', body,
          headers: headers, files: files);

  // PUT
  Future<Response> putData(String uri, dynamic body,
          {Map<String, String>? headers, List<MultipartBody>? files}) =>
      _makeRequest(ApiConstants.baseUrl + uri, 'PUT', body,
          headers: headers, files: files);

  //PATCH
  Future<Response> patchData(String uri, dynamic body,
          {Map<String, String>? headers, List<MultipartBody>? files}) =>
      _makeRequest(ApiConstants.baseUrl + uri, 'PATCH', body,
          headers: headers, files: files);

  // DELETE
  Future<Response> deleteData(String uri,
          {Map<String, String>? headers, dynamic body}) =>
      _makeRequest(ApiConstants.baseUrl + uri, 'DELETE', body,
          headers: headers);
}

class MultipartBody {
  String key;
  File file;

  MultipartBody(this.key, this.file);
}
