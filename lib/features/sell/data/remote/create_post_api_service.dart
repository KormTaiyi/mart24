import 'package:dio/dio.dart';
import 'package:mart24/core/network/api_client.dart';
import 'package:mart24/core/network/api_endpoints.dart';
import 'package:mart24/core/network/api_exception.dart';

class CreatePostApiService {
  CreatePostApiService({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<Map<String, dynamic>> createPost({
    required String title,
    required String description,
    required double price,
    required int categoryId,
    String status = 'active',
    String? location,
    double? latitude,
    double? longitude,
    String? condition,
    List<String> imagePaths = const <String>[],
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'price': price,
      'status': status.trim().isEmpty ? 'active' : status.trim(),
      'category_id': categoryId,
      if (location case final String value when value.trim().isNotEmpty)
        'location': value.trim(),
      if (latitude case final double value) 'latitude': value,
      if (longitude case final double value) 'longitude': value,
      if (condition case final String value when value.trim().isNotEmpty)
        'condition': value.trim(),
    };

    try {
      if (imagePaths.isNotEmpty) {
        final FormData formData = FormData();
        for (final MapEntry<String, dynamic> entry in payload.entries) {
          formData.fields.add(MapEntry(entry.key, entry.value.toString()));
        }

        for (final String path in imagePaths) {
          final String trimmed = path.trim();
          if (trimmed.isEmpty) {
            continue;
          }
          formData.files.add(
            MapEntry(
              'images',
              await MultipartFile.fromFile(
                trimmed,
                filename: _fileName(trimmed),
              ),
            ),
          );
        }

        final Response<dynamic> response = await _client.dio.post<dynamic>(
          ApiEndpoints.createPost,
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
        return _extractMap(response.data);
      }

      final dynamic response = await _client.post<dynamic>(
        ApiEndpoints.createPost,
        data: payload,
      );
      return _extractMap(response);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return <String, dynamic>{};
  }

  String _fileName(String path) {
    final int slashIndex = path.lastIndexOf('/');
    if (slashIndex < 0 || slashIndex == path.length - 1) {
      return 'image.jpg';
    }
    return path.substring(slashIndex + 1);
  }
}
