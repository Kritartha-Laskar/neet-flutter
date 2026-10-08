import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/resource_model.dart';
import 'auth_service.dart';

class ResourceService {
  static Future<List<ResourceModel>> fetchResources({
    required String token,
    String? type,
  }) async {
    final queryParams = <String, String>{
      if (type != null && type.isNotEmpty) 'type': type,
    };
    final uri = Uri.parse(ApiConfig.resources).replace(queryParameters: queryParams);
    final response = await http
        .get(uri, headers: ApiConfig.authHeaders(token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['data'] as List<dynamic>? ?? [])
          .map((e) => ResourceModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    }
    throw ApiException('Failed to load resources (${response.statusCode})');
  }
}
