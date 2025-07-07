import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  // ค่าต่างๆ จาก Cloudinary Dashboard
  static const String cloudName = 'YOUR_CLOUD_NAME'; // เปลี่ยนเป็นของคุณ
  static const String apiKey = 'YOUR_API_KEY';       // เปลี่ยนเป็นของคุณ
  static const String apiSecret = 'YOUR_API_SECRET'; // เปลี่ยนเป็นของคุณ
  
  static const String baseUrl = 'https://api.cloudinary.com/v1_1';
  static const String uploadUrl = '$baseUrl/$cloudName/image/upload';

  /// อัปโหลดรูปภาพไป Cloudinary
  static Future<Map<String, dynamic>> uploadImage({
    required XFile imageFile,
    String? folder,
    Map<String, String>? tags,
    bool autoOptimize = true,
    String quality = 'auto',
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // อ่านไฟล์รูปภาพ
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.name.split('.').first;
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // สร้าง public_id ที่ไม่ซ้ำ
      final publicId = folder != null 
          ? '$folder/${fileName}_$timestamp'
          : '${fileName}_$timestamp';

      // เตรียมข้อมูลสำหรับอัปโหลด
      Map<String, String> uploadParams = {
        'public_id': publicId,
        'timestamp': timestamp,
        'api_key': apiKey,
      };

      // เพิ่มการ optimize รูปภาพ
      if (autoOptimize) {
        uploadParams['quality'] = quality;
        uploadParams['fetch_format'] = 'auto';
        uploadParams['flags'] = 'progressive';
      }

      // เพิ่มการ resize (ถ้ากำหนด)
      List<String> transformations = [];
      if (maxWidth != null || maxHeight != null) {
        String resize = 'c_limit';
        if (maxWidth != null) resize += ',w_$maxWidth';
        if (maxHeight != null) resize += ',h_$maxHeight';
        transformations.add(resize);
      }

      if (transformations.isNotEmpty) {
        uploadParams['transformation'] = transformations.join('/');
      }

      // เพิ่ม tags (ถ้ามี)
      if (tags != null && tags.isNotEmpty) {
        uploadParams['tags'] = tags.values.join(',');
        uploadParams.addAll(tags);
      }

      // สร้าง signature
      final signature = _generateSignature(uploadParams, apiSecret);
      uploadParams['signature'] = signature;

      // สร้าง multipart request
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      
      // เพิ่ม parameters
      request.fields.addAll(uploadParams);
      
      // เพิ่มไฟล์รูปภาพ
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name,
        ),
      );

      // ส่ง request
      print('กำลังอัปโหลดไป Cloudinary...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        print('อัปโหลดสำเร็จ: ${result['secure_url']}');
        
        return {
          'success': true,
          'url': result['secure_url'],
          'public_id': result['public_id'],
          'width': result['width'],
          'height': result['height'],
          'format': result['format'],
          'bytes': result['bytes'],
          'created_at': result['created_at'],
          'resource_type': result['resource_type'],
          'version': result['version'],
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Cloudinary Error: ${error['error']['message']}');
      }

    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// อัปโหลดหลายรูปพร้อมกัน
  static Future<List<Map<String, dynamic>>> uploadMultipleImages({
    required List<XFile> imageFiles,
    String? folder,
    Map<String, String>? tags,
    bool autoOptimize = true,
    int? maxWidth,
    int? maxHeight,
    int maxConcurrent = 3, // จำกัดการอัปโหลดพร้อมกัน
  }) async {
    List<Map<String, dynamic>> results = [];
    
    // แบ่งการอัปโหลดเป็นกลุ่มเพื่อไม่ให้ excessive requests
    for (int i = 0; i < imageFiles.length; i += maxConcurrent) {
      final batch = imageFiles.skip(i).take(maxConcurrent).toList();
      
      final batchResults = await Future.wait(
        batch.map((imageFile) => uploadImage(
          imageFile: imageFile,
          folder: folder,
          tags: tags,
          autoOptimize: autoOptimize,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        )),
      );
      
      results.addAll(batchResults);
    }
    
    return results;
  }

  /// ลบรูปภาพจาก Cloudinary
  static Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      final params = {
        'public_id': publicId,
        'timestamp': timestamp,
        'api_key': apiKey,
      };

      final signature = _generateSignature(params, apiSecret);
      params['signature'] = signature;

      final response = await http.post(
        Uri.parse('$baseUrl/$cloudName/image/destroy'),
        body: params,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['result'] == 'ok';
      }
      
      return false;
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      return false;
    }
  }

  /// ลบหลายรูปพร้อมกัน
  static Future<void> deleteMultipleImages(List<String> publicIds) async {
    for (final publicId in publicIds) {
      await deleteImage(publicId);
    }
  }

  /// สร้าง URL สำหรับรูปที่ optimize แล้ว
  static String getOptimizedUrl({
    required String publicId,
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
    bool progressive = true,
    String crop = 'limit',
  }) {
    List<String> transformations = [];
    
    // เพิ่มการ resize
    if (width != null || height != null) {
      String resize = 'c_$crop';
      if (width != null) resize += ',w_$width';
      if (height != null) resize += ',h_$height';
      transformations.add(resize);
    }
    
    // เพิ่มการ optimize
    transformations.add('q_$quality');
    transformations.add('f_$format');
    
    if (progressive) {
      transformations.add('fl_progressive');
    }
    
    final transformationString = transformations.join(',');
    
    return 'https://res.cloudinary.com/$cloudName/image/upload/$transformationString/v1/$publicId';
  }

  /// สร้าง thumbnail URL
  static String getThumbnailUrl({
    required String publicId,
    int size = 150,
    String quality = 'auto',
  }) {
    return getOptimizedUrl(
      publicId: publicId,
      width: size,
      height: size,
      quality: quality,
      crop: 'fill', // crop เป็นสี่เหลี่ยมจัตุรัส
    );
  }

  /// ดึงข้อมูลรูปภาพ
  static Future<Map<String, dynamic>?> getImageDetails(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      final params = {
        'timestamp': timestamp,
        'api_key': apiKey,
      };

      final signature = _generateSignature(params, apiSecret);
      
      final response = await http.get(
        Uri.parse('$baseUrl/$cloudName/resources/image/upload/$publicId')
          .replace(queryParameters: {
            ...params,
            'signature': signature,
          }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      
      return null;
    } catch (e) {
      print('Error getting image details: $e');
      return null;
    }
  }

  /// ค้นหารูปภาพ
  static Future<List<Map<String, dynamic>>> searchImages({
    String? expression,
    String? tag,
    int maxResults = 50,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      Map<String, String> params = {
        'timestamp': timestamp,
        'api_key': apiKey,
        'max_results': maxResults.toString(),
      };

      if (expression != null) {
        params['expression'] = expression;
      }
      
      if (tag != null) {
        params['tags'] = tag;
      }

      final signature = _generateSignature(params, apiSecret);
      params['signature'] = signature;

      final response = await http.post(
        Uri.parse('$baseUrl/$cloudName/resources/search'),
        body: params,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(result['resources'] ?? []);
      }
      
      return [];
    } catch (e) {
      print('Error searching images: $e');
      return [];
    }
  }

  /// สร้าง signature สำหรับ Cloudinary API
  static String _generateSignature(
    Map<String, String> params,
    String apiSecret,
  ) {
    // เรียงพารามิเตอร์ตามลำดับตัวอักษร
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // สร้าง query string
    final queryString = sortedParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    // เพิ่ม API secret
    final stringToSign = '$queryString$apiSecret';

    // สร้าง SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  /// ตรวจสอบ usage ปัจจุบัน
  static Future<Map<String, dynamic>?> getUsage() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      final params = {
        'timestamp': timestamp,
        'api_key': apiKey,
      };

      final signature = _generateSignature(params, apiSecret);
      
      final response = await http.get(
        Uri.parse('$baseUrl/$cloudName/usage')
          .replace(queryParameters: {
            ...params,
            'signature': signature,
          }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      
      return null;
    } catch (e) {
      print('Error getting usage: $e');
      return null;
    }
  }
}