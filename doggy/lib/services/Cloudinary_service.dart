import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'enhanced_image_handler_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  // ค่าต่างๆ จาก Cloudinary Dashboard
  static String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
  static String apiKey = dotenv.env['CLOUDINARY_API_KEY']!;
  static String apiSecret = dotenv.env['CLOUDINARY_API_SECRET']!;

  static String baseUrl = 'https://api.cloudinary.com/v1_1';
  static String imageUploadUrl = '$baseUrl/$cloudName/image/upload';
  static String videoUploadUrl = '$baseUrl/$cloudName/video/upload';

  /// อัปโหลดรูปภาพไป Cloudinary พร้อมการประมวลผล HEIC ขั้นสูง
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
      
      // ประมวลผลรูปภาพขั้นสูงก่อนอัปโหลด
      if (processImage) {
        print('🔄 Processing image with enhanced handler...');
        
        // วิเคราะห์ไฟล์ก่อน
        final fileAnalysis = await EnhancedImageHandler.analyzeImageFile(imageFile);
        print('📊 File analysis: ${fileAnalysis['recommendedAction']}');
        
        if (fileAnalysis['needsProcessing'] == true) {
          print('🛠️ File needs processing, applying enhanced conversion...');
          fileToUpload = await EnhancedImageHandler.processImageAdvanced(imageFile);
        } else {
          print('✅ File is ready for upload without processing');
        }
      }

      // อ่านไฟล์รูปภาพที่ประมวลผลแล้ว
      final bytes = await fileToUpload.readAsBytes();
      final fileName = fileToUpload.name.split('.').first;
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // สร้าง public_id ที่ไม่ซ้ำ
      final publicId = folder != null 
          ? '$folder/${fileName}_$timestamp'
          : '${fileName}_$timestamp';

      // เตรียมข้อมูลสำหรับ signature
      Map<String, String> signatureParams = {
        'timestamp': timestamp.toString(),
        'public_id': publicId,
      };

      // เพิ่ม folder ถ้ามี
      if (folder != null) {
        signatureParams['folder'] = folder;
      }

      // เพิ่มการ transformation สำหรับ HEIC/HEIF files
      List<String> transformations = [];
      
      // Auto format conversion for HEIC/HEIF
      if (EnhancedImageHandler.isHeifFile(imageFile.name)) {
        transformations.add('f_jpg'); // Force JPEG format
        print('🔄 Adding JPEG format transformation for HEIC/HEIF file');
      }
      
      // เพิ่มการ resize ถ้ากำหนด
      if (maxWidth != null || maxHeight != null) {
        String resize = 'c_limit';
        if (maxWidth != null) resize += ',w_$maxWidth';
        if (maxHeight != null) resize += ',h_$maxHeight';
        transformations.add(resize);
      }
      
      // รวม transformations
      if (transformations.isNotEmpty) {
        signatureParams['transformation'] = transformations.join(',');
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

      // สร้าง signature
      final signature = _generateSignature(signatureParams, apiSecret);

      // เตรียมข้อมูลสำหรับ upload
      Map<String, String> uploadParams = Map.from(signatureParams);
      
      // เพิ่มการ optimize รูปภาพ (ไม่รวมใน signature)
      if (autoOptimize) {
        uploadParams['quality'] = quality;
        uploadParams['fetch_format'] = 'auto';
        uploadParams['flags'] = 'progressive';
        
        // เพิ่ม auto orientation fix
        uploadParams['angle'] = 'auto_right';
      }

      // เพิ่ม api_key และ signature
      uploadParams['api_key'] = apiKey;
      uploadParams['signature'] = signature;

      // สร้าง multipart request
      var request = http.MultipartRequest('POST', Uri.parse(imageUploadUrl));
      
      // เพิ่ม parameters
      request.fields.addAll(uploadParams);
      
      // เพิ่มไฟล์รูปภาพ (ใช้ชื่อไฟล์ใหม่ถ้าเป็น HEIC/HEIF)
      String uploadFileName = fileToUpload.name;
      if (EnhancedImageHandler.isHeifFile(imageFile.name) && !uploadFileName.toLowerCase().endsWith('.jpg')) {
        uploadFileName = uploadFileName.replaceAll(RegExp(r'\.(heic|heif)$', caseSensitive: false), '.jpg');
      }
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: uploadFileName,
        ),
      );

      // ส่ง request
      print('📤 Uploading image to Cloudinary...');
      print('📁 File size: ${_formatFileSize(bytes.length)}');
      print('🏷️ Upload filename: $uploadFileName');
      print('🔑 Signature params: ${signatureParams.keys.join(', ')}');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📨 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        print('✅ Image uploaded successfully!');
        print('🔗 URL: ${result['secure_url']}');
        print('📊 Final format: ${result['format']}');
        
        // ทำความสะอาดไฟล์ชั่วคราว
        if (fileToUpload.path != imageFile.path) {
          try {
            await File(fileToUpload.path).delete();
            print('🧹 Cleaned up temporary processed file');
          } catch (e) {
            print('⚠️ Could not delete temp file: $e');
          }
        }
        
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
          'was_processed': fileToUpload.path != imageFile.path,
          'original_format': EnhancedImageHandler.isHeifFile(imageFile.name) ? 'HEIC/HEIF' : 'Standard',
        };
      } else {
        print('❌ Upload failed!');
        print('📨 Error response: ${response.body}');
        final error = jsonDecode(response.body);
        throw Exception('Cloudinary Error: ${error['error']['message']}');
      }

    } catch (e) {
      print('❌ Error uploading image to Cloudinary: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// อัปโหลดรูปภาพแบบง่าย (สำหรับ post ในกลุ่ม) - รองรับ HEIC
  static Future<String?> uploadPostImage(XFile imageFile) async {
    try {
      print('📤 Uploading post image: ${imageFile.name}');
      
      final result = await uploadImage(
        imageFile: imageFile,
        folder: 'doggy_training/posts',
        autoOptimize: true,
        processImage: true, // เปิดการประมวลผลขั้นสูง
        maxWidth: 1200,
        maxHeight: 1200,
        customTags: {
          'category': 'post',
          'app': 'doggy_training',
        },
      );

      if (result['success'] == true) {
        print('✅ Post image uploaded: ${result['url']}');
        return result['url'];
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      print('❌ Error uploading post image: $e');
      return null;
    }
  }

  /// อัปโหลดหลายรูปพร้อมกัน (เวอร์ชันขั้นสูงรองรับ HEIC)
  static Future<List<String>> uploadPostImages(List<XFile> imageFiles) async {
    List<String> uploadedUrls = [];
    
    print('📤 Uploading ${imageFiles.length} images with HEIC support...');
    
    // วิเคราะห์ไฟล์ก่อนอัปโหลด
    for (int i = 0; i < imageFiles.length; i++) {
      final analysis = await EnhancedImageHandler.analyzeImageFile(imageFiles[i]);
      print('📊 Image ${i + 1}: ${analysis['name']} - ${analysis['recommendedAction']}');
    }
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        print('📤 Uploading image ${i + 1}/${imageFiles.length}: ${imageFiles[i].name}');
        final url = await uploadPostImage(imageFiles[i]);
        if (url != null) {
          uploadedUrls.add(url);
          print('✅ Image ${i + 1} uploaded successfully');
        } else {
          print('❌ Image ${i + 1} upload failed');
        }
      } catch (e) {
        print('❌ Failed to upload image ${i + 1}: $e');
        // Continue with other images even if one fails
      }
    }
    
    print('🎉 Successfully uploaded ${uploadedUrls.length}/${imageFiles.length} images');
    
    // ทำความสะอาดไฟล์ชั่วคราว
    await EnhancedImageHandler.cleanupTempFiles();
    
    return uploadedUrls;
  }

  /// อัปโหลดหลายรูปพร้อมกัน (เวอร์ชันขั้นสูงสำหรับ advanced features)
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
    
    print('📤 Starting advanced upload for ${imageFiles.length} images...');
    
    // ประมวลผลรูปภาพทั้งหมดก่อน (เพื่อแปลง HEIC)
    List<XFile> processedFiles = imageFiles;
    if (processImages) {
      print('🛠️ Pre-processing all images...');
      processedFiles = await EnhancedImageHandler.processMultipleImagesAdvanced(imageFiles);
    }
    
    // แบ่งการอัปโหลดเป็นกลุ่มเพื่อไม่ให้ excessive requests
    for (int i = 0; i < processedFiles.length; i += maxConcurrent) {
      final batch = processedFiles.skip(i).take(maxConcurrent).toList();
      
      print('📤 Uploading batch ${(i ~/ maxConcurrent) + 1}/${((processedFiles.length - 1) ~/ maxConcurrent) + 1} (${batch.length} files)...');
      
      final batchResults = await Future.wait(
        batch.map((imageFile) => uploadImage(
          imageFile: imageFile,
          folder: folder,
          customTags: customTags,
          autoOptimize: autoOptimize,
          processImage: false, // Already processed above
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        )),
      );
      
      results.addAll(batchResults);
      
      // แสดงผลลัพธ์ของ batch
      final successCount = batchResults.where((r) => r['success'] == true).length;
      print('✅ Batch completed: ${successCount}/${batch.length} successful');
    }
    
    // สรุปผลลัพธ์
    final totalSuccess = results.where((r) => r['success'] == true).length;
    print('🎉 Advanced upload completed: ${totalSuccess}/${imageFiles.length} successful');
    
    // ทำความสะอาดไฟล์ชั่วคราว
    await EnhancedImageHandler.cleanupTempFiles();
    
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
      print('📤 Uploading video to Cloudinary...');
      print('📁 File size: ${_formatFileSize(bytes.length)}');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        print('✅ Video uploaded successfully: ${result['secure_url']}');
        
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
      print('❌ Error uploading video to Cloudinary: $e');
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
        print('✅ Image deleted successfully: $publicId');
        return result['result'] == 'ok';
      }
      
      return false;
    } catch (e) {
      print('❌ Error deleting image from Cloudinary: $e');
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
        print('✅ Video deleted successfully: $publicId');
        return result['result'] == 'ok';
      }
      
      return false;
    } catch (e) {
      print('❌ Error deleting video from Cloudinary: $e');
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

    print('🔑 Parameters for signature: ${sortedParams.keys.join(', ')}');

    // สร้าง SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  /// แปลงขนาดไฟล์เป็นสตริง
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  // Utility method สำหรับแปลง File เป็น XFile
  static XFile fileToXFile(File file) {
    return XFile(file.path);
  }

  /// ตรวจสอบสถานะของ Cloudinary service
  static Future<bool> checkServiceHealth() async {
    try {
      // สร้าง simple ping request
      final response = await http.get(
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/list'),
      );
      
      return response.statusCode == 401; // 401 คือ unauthorized ซึ่งหมายความว่า service ทำงานปกติ
    } catch (e) {
      print('❌ Cloudinary service health check failed: $e');
      return false;
    }
  }

  /// ดึงข้อมูลการใช้งาน Cloudinary
  static Future<Map<String, dynamic>?> getUsageStats() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final params = {
        'timestamp': timestamp.toString(),
      };

      final signature = _generateSignature(params, apiSecret);
      
      final finalParams = {
        ...params,
        'api_key': apiKey,
        'signature': signature,
      };

      final response = await http.get(
        Uri.parse('$baseUrl/$cloudName/usage').replace(queryParameters: finalParams),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting usage stats: $e');
      return null;
    }
  }
}