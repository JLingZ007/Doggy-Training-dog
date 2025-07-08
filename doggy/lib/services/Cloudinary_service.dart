import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';

// Import SimpleImageHandler ที่เราสร้าง
import 'ImageHandler_Service.dart'; 

class CloudinaryService {
  // ค่าต่างๆ จาก Cloudinary Dashboard
  static const String cloudName = 'duyhqyjjo';
  static const String apiKey = '243279538533494';
  static const String apiSecret = 'FZC1FO0pBpEwV7nFJSczRGfCJCs';
  
  static const String baseUrl = 'https://api.cloudinary.com/v1_1';
  static const String imageUploadUrl = '$baseUrl/$cloudName/image/upload';
  static const String videoUploadUrl = '$baseUrl/$cloudName/video/upload';

  /// อัปโหลดรูปภาพไป Cloudinary พร้อมประมวลผลรูปภาพ
  static Future<Map<String, dynamic>> uploadImage({
    required XFile imageFile,
    String? folder,
    Map<String, String>? customTags,
    bool autoOptimize = true,
    bool processImage = true,
    String quality = 'auto',
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      XFile fileToUpload = imageFile;
      
      // ประมวลผลรูปภาพก่อนอัปโหลด (แก้ปัญหา HEIF)
      if (processImage) {
        print('Processing image before upload...');
        
       
       
        fileToUpload = await SimpleImageHandler.processImageBasic(imageFile);
        print('Image processed successfully');
        
        
        // ประมวลผลพื้นฐาน (สำหรับตอนนี้)
        // fileToUpload = await _basicImageProcessing(imageFile);
      }

      // อ่านไฟล์รูปภาพ
      final bytes = await fileToUpload.readAsBytes();
      final fileName = fileToUpload.name.split('.').first;
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // สร้าง public_id ที่ไม่ซ้ำ
      final publicId = folder != null 
          ? '$folder/${fileName}_$timestamp'
          : '${fileName}_$timestamp';

      // เตรียมข้อมูลสำหรับ signature (เฉพาะที่จำเป็น)
      Map<String, String> signatureParams = {
        'timestamp': timestamp.toString(),
        'public_id': publicId,
      };

      // เพิ่ม folder ถ้ามี
      if (folder != null) {
        signatureParams['folder'] = folder;
      }

      // เพิ่มการ resize (ถ้ากำหนด) - สำหรับ signature
      if (maxWidth != null || maxHeight != null) {
        String resize = 'c_limit';
        if (maxWidth != null) resize += ',w_$maxWidth';
        if (maxHeight != null) resize += ',h_$maxHeight';
        signatureParams['transformation'] = resize;
      }

      // เพิ่ม tags สำหรับ signature
      if (customTags != null && customTags.isNotEmpty) {
        List<String> tagsList = [];
        customTags.forEach((key, value) {
          tagsList.add('${key}_$value');
        });
        
        if (tagsList.isNotEmpty) {
          signatureParams['tags'] = tagsList.join(',');
        }
      }

      // สร้าง signature ก่อน
      final signature = _generateSignature(signatureParams, apiSecret);

      // เตรียมข้อมูลสำหรับ upload (รวม optimization params)
      Map<String, String> uploadParams = Map.from(signatureParams);
      
      // เพิ่มการ optimize รูปภาพ (ไม่รวมใน signature)
      if (autoOptimize) {
        uploadParams['quality'] = quality;
        uploadParams['fetch_format'] = 'auto';
        uploadParams['flags'] = 'progressive';
      }

      // เพิ่ม api_key และ signature
      uploadParams['api_key'] = apiKey;
      uploadParams['signature'] = signature;

      // สร้าง multipart request
      var request = http.MultipartRequest('POST', Uri.parse(imageUploadUrl));
      
      // เพิ่ม parameters
      request.fields.addAll(uploadParams);
      
      // เพิ่มไฟล์รูปภาพ
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileToUpload.name,
        ),
      );

      // ส่ง request
      print('กำลังอัปโหลดรูปภาพไป Cloudinary...');
      print('File size: ${bytes.length} bytes');
      print('Signature params: ${signatureParams.keys.join(', ')}');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        print('อัปโหลดรูปภาพสำเร็จ: ${result['secure_url']}');
        
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
        print('Error response body: ${response.body}');
        final error = jsonDecode(response.body);
        throw Exception('Cloudinary Error: ${error['error']['message']}');
      }

    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// ประมวลผลรูปภาพพื้นฐาน (Fallback)
  static Future<XFile> _basicImageProcessing(XFile originalFile) async {
    try {
      // ตรวจสอบว่าเป็นไฟล์ HEIF/HEIC หรือไม่
      final fileName = originalFile.name.toLowerCase();
      if (fileName.endsWith('.heic') || fileName.endsWith('.heif')) {
        print('⚠️ HEIF/HEIC file detected. Converting to JPEG.');
        
        // สำหรับตอนนี้ให้เปลี่ยนชื่อไฟล์เป็น .jpg
        final newFileName = fileName
            .replaceAll('.heic', '.jpg')
            .replaceAll('.heif', '.jpg');
        
        // สร้างไฟล์ใหม่โดยคัดลอกข้อมูล
        final bytes = await originalFile.readAsBytes();
        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempFile = File('${tempDir.path}/${timestamp}_$newFileName');
        await tempFile.writeAsBytes(bytes);
        
        print('✅ HEIF converted to: ${tempFile.path}');
        return XFile(tempFile.path);
      }
      
      return originalFile;
    } catch (e) {
      print('Error in basic image processing: $e');
      return originalFile;
    }
  }

  /// อัปโหลดรูปภาพแบบง่าย (สำหรับ post ในกลุ่ม)
  static Future<String?> uploadPostImage(XFile imageFile) async {
    try {
      final result = await uploadImage(
        imageFile: imageFile,
        folder: 'doggy_training/posts',
        autoOptimize: true,
        processImage: true, // เปิดการประมวลผลรูปภาพ
        maxWidth: 1200,
        maxHeight: 1200,
        customTags: {
          'category': 'post',
          'app': 'doggy_training',
        },
      );

      if (result['success'] == true) {
        return result['url'];
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      print('Error uploading post image: $e');
      return null;
    }
  }

  /// อัปโหลดหลายรูปพร้อมกัน (สำหรับ post)
  static Future<List<String>> uploadPostImages(List<XFile> imageFiles) async {
    List<String> uploadedUrls = [];
    
    print('Uploading ${imageFiles.length} images to Cloudinary...');
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        print('Uploading image ${i + 1}/${imageFiles.length}...');
        final url = await uploadPostImage(imageFiles[i]);
        if (url != null) {
          uploadedUrls.add(url);
        }
      } catch (e) {
        print('Failed to upload image ${i + 1}: $e');
        // Continue with other images even if one fails
      }
    }
    
    print('Successfully uploaded ${uploadedUrls.length}/${imageFiles.length} images');
    return uploadedUrls;
  }

  /// อัปโหลดหลายรูปพร้อมกัน (เวอร์ชันขั้นสูง)
  static Future<List<Map<String, dynamic>>> uploadMultipleImages({
    required List<XFile> imageFiles,
    String? folder,
    Map<String, String>? customTags,
    bool autoOptimize = true,
    bool processImages = true,
    int? maxWidth,
    int? maxHeight,
    int maxConcurrent = 3,
  }) async {
    List<Map<String, dynamic>> results = [];
    
    // แบ่งการอัปโหลดเป็นกลุ่มเพื่อไม่ให้ excessive requests
    for (int i = 0; i < imageFiles.length; i += maxConcurrent) {
      final batch = imageFiles.skip(i).take(maxConcurrent).toList();
      
      final batchResults = await Future.wait(
        batch.map((imageFile) => uploadImage(
          imageFile: imageFile,
          folder: folder,
          customTags: customTags,
          autoOptimize: autoOptimize,
          processImage: processImages, // เปิดการประมวลผลรูปภาพ
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        )),
      );
      
      results.addAll(batchResults);
    }
    
    return results;
  }

  /// อัปโหลดวิดีโอไป Cloudinary
  static Future<Map<String, dynamic>> uploadVideo({
    required XFile videoFile,
    String? folder,
    Map<String, String>? customTags,
    bool autoOptimize = true,
    String quality = 'auto',
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // อ่านไฟล์วิดีโอ
      final bytes = await videoFile.readAsBytes();
      final fileName = videoFile.name.split('.').first;
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // สร้าง public_id ที่ไม่ซ้ำ
      final publicId = folder != null 
          ? '$folder/${fileName}_$timestamp'
          : '${fileName}_$timestamp';

      // เตรียมข้อมูลสำหรับ signature (เฉพาะที่จำเป็น)
      Map<String, String> signatureParams = {
        'timestamp': timestamp.toString(),
        'resource_type': 'video',
        'public_id': publicId,
      };

      // เพิ่ม folder ถ้ามี
      if (folder != null) {
        signatureParams['folder'] = folder;
      }

      // เพิ่มการ resize (ถ้ากำหนด) - สำหรับ signature
      if (maxWidth != null || maxHeight != null) {
        String resize = 'c_limit';
        if (maxWidth != null) resize += ',w_$maxWidth';
        if (maxHeight != null) resize += ',h_$maxHeight';
        signatureParams['transformation'] = resize;
      }

      // เพิ่ม tags สำหรับ signature
      if (customTags != null && customTags.isNotEmpty) {
        List<String> tagsList = [];
        customTags.forEach((key, value) {
          tagsList.add('${key}_$value');
        });
        
        if (tagsList.isNotEmpty) {
          signatureParams['tags'] = tagsList.join(',');
        }
      }

      // สร้าง signature ก่อน
      final signature = _generateSignature(signatureParams, apiSecret);

      // เตรียมข้อมูลสำหรับ upload (รวม optimization params)
      Map<String, String> uploadParams = Map.from(signatureParams);

      // เพิ่มการ optimize วิดีโอ (ไม่รวมใน signature)
      if (autoOptimize) {
        uploadParams['quality'] = quality;
        uploadParams['format'] = 'mp4';
        uploadParams['video_codec'] = 'h264';
      }

      // เพิ่ม api_key และ signature
      uploadParams['api_key'] = apiKey;
      uploadParams['signature'] = signature;

      // สร้าง multipart request
      var request = http.MultipartRequest('POST', Uri.parse(videoUploadUrl));
      
      // เพิ่ม parameters
      request.fields.addAll(uploadParams);
      
      // เพิ่มไฟล์วิดีโอ
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: videoFile.name,
        ),
      );

      // ส่ง request
      print('กำลังอัปโหลดวิดีโอไป Cloudinary...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        print('อัปโหลดวิดีโอสำเร็จ: ${result['secure_url']}');
        
        // สร้าง thumbnail URL สำหรับวิดีโอ
        final thumbnailUrl = 'https://res.cloudinary.com/$cloudName/video/upload/c_scale,w_300,h_200/${result['public_id']}.jpg';
        
        return {
          'success': true,
          'url': result['secure_url'],
          'public_id': result['public_id'],
          'width': result['width'],
          'height': result['height'],
          'format': result['format'],
          'bytes': result['bytes'],
          'duration': result['duration'],
          'created_at': result['created_at'],
          'resource_type': result['resource_type'],
          'version': result['version'],
          'thumbnail_url': thumbnailUrl,
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Cloudinary Error: ${error['error']['message']}');
      }

    } catch (e) {
      print('Error uploading video to Cloudinary: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// ลบรูปภาพจาก Cloudinary
  static Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final params = {
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      };

      final signature = _generateSignature(params, apiSecret);
      
      final finalParams = {
        ...params,
        'api_key': apiKey,
        'signature': signature,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/$cloudName/image/destroy'),
        body: finalParams,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('ลบรูปภาพสำเร็จ: $publicId');
        return result['result'] == 'ok';
      }
      
      return false;
    } catch (e) {
      print('Error deleting image from Cloudinary: $e');
      return false;
    }
  }

  /// ลบวิดีโอจาก Cloudinary
  static Future<bool> deleteVideo(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final params = {
        'public_id': publicId,
        'timestamp': timestamp.toString(),
        'resource_type': 'video',
      };

      final signature = _generateSignature(params, apiSecret);
      
      final finalParams = {
        ...params,
        'api_key': apiKey,
        'signature': signature,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/$cloudName/video/destroy'),
        body: finalParams,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('ลบวิดีโอสำเร็จ: $publicId');
        return result['result'] == 'ok';
      }
      
      return false;
    } catch (e) {
      print('Error deleting video from Cloudinary: $e');
      return false;
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
      crop: 'fill',
    );
  }

  /// สร้าง signature สำหรับ Cloudinary API
  static String _generateSignature(
    Map<String, String> params,
    String apiSecret,
  ) {
    // เรียงพารามิเตอร์ตามลำดับตัวอักษร (ไม่รวม api_key และ signature)
    final sortedParams = Map.fromEntries(
      params.entries
          .where((entry) => 
              entry.key != 'signature' && 
              entry.key != 'api_key' &&
              entry.value.isNotEmpty)
          .toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
    );

    // สร้าง query string
    final queryString = sortedParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    // เพิ่ม API secret
    final stringToSign = '$queryString$apiSecret';

    print('Parameters for signature: ${sortedParams.keys.join(', ')}');
    print('String to sign: $stringToSign');

    // สร้าง SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  // Utility method สำหรับแปลง File เป็น XFile
  static XFile fileToXFile(File file) {
    return XFile(file.path);
  }
}