import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class EnhancedImageHandler {
  /// แปลงไฟล์ HEIF/HEIC เป็น JPEG อย่างถูกต้อง
  static Future<XFile> processImageAdvanced(XFile originalFile) async {
    try {
      final fileName = originalFile.name.toLowerCase();
      
      // ตรวจสอบว่าเป็นไฟล์ HEIF/HEIC หรือไม่
      if (fileName.endsWith('.heic') || fileName.endsWith('.heif')) {
        
        
        // อ่านข้อมูลไฟล์เดิม
        final originalBytes = await originalFile.readAsBytes();
        
        try {
          // ใช้ image package เพื่อ decode และ encode ใหม่
          final originalImage = img.decodeImage(originalBytes);
          
          if (originalImage != null) {
            // แปลงเป็น JPEG
            final jpegBytes = img.encodeJpg(originalImage, quality: 85);
            
            // สร้างชื่อไฟล์ใหม่
            final newFileName = fileName
                .replaceAll('.heic', '.jpg')
                .replaceAll('.heif', '.jpg');
            
            // สร้างไฟล์ชั่วคราวใหม่
            final tempDir = Directory.systemTemp;
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final tempFile = File('${tempDir.path}/${timestamp}_converted_$newFileName');
            
            // เขียนข้อมูลลงไฟล์ใหม่
            await tempFile.writeAsBytes(jpegBytes);

            
            return XFile(tempFile.path);
          } else {

            return await _fallbackHeifConversion(originalFile, originalBytes);
          }
        } catch (decodeError) {
          return await _fallbackHeifConversion(originalFile, originalBytes);
        }
      }
      
      // ถ้าไม่ใช่ HEIF/HEIC ให้ตรวจสอบและปรับปรุงรูปภาพ
      return await _optimizeRegularImage(originalFile);
      
    } catch (e) {
      // ส่งไฟล์เดิมกลับไปถ้าไม่สามารถประมวลผลได้
      return originalFile;
    }
  }
  
  /// วิธีสำรองสำหรับแปลง HEIF (เปลี่ยนชื่อไฟล์และ metadata)
  static Future<XFile> _fallbackHeifConversion(XFile originalFile, Uint8List originalBytes) async {
    try {
      print('🔄 Using fallback HEIF conversion...');
      
      final fileName = originalFile.name.toLowerCase();
      final newFileName = fileName
          .replaceAll('.heic', '.jpg')
          .replaceAll('.heif', '.jpg');
      
      // สร้างไฟล์ชั่วคราวใหม่
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/${timestamp}_fallback_$newFileName');
      
      // เขียนข้อมูลลงไฟล์ใหม่ (แม้จะยังเป็น HEIF format ภายใน)
      await tempFile.writeAsBytes(originalBytes);
      
      
      return XFile(tempFile.path);
    } catch (e) {
      print('❌ Fallback conversion failed: $e');
      return originalFile;
    }
  }
  
  /// ปรับปรุงและบีบอัดรูปภาพทั่วไป
  static Future<XFile> _optimizeRegularImage(XFile originalFile) async {
    try {
      final fileSize = await File(originalFile.path).length();
      print('📁 Original file size: ${_formatFileSize(fileSize)}');
      
      // ถ้าไฟล์ใหญ่เกิน 2MB ให้บีบอัด
      if (fileSize > 2 * 1024 * 1024) {
        print('🔄 File is large, compressing...');
        
        final originalBytes = await originalFile.readAsBytes();
        final originalImage = img.decodeImage(originalBytes);
        
        if (originalImage != null) {
          // ปรับขนาดถ้าความกว้างเกิน 1920px
          img.Image resizedImage = originalImage;
          if (originalImage.width > 1920) {
            resizedImage = img.copyResize(
              originalImage, 
              width: 1920,
              interpolation: img.Interpolation.linear,
            );
            print('📐 Resized from ${originalImage.width}x${originalImage.height} to ${resizedImage.width}x${resizedImage.height}');
          }
          
          // บีบอัดเป็น JPEG
          final compressedBytes = img.encodeJpg(resizedImage, quality: 80);
          
          // สร้างไฟล์ชั่วคราว
          final tempDir = Directory.systemTemp;
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final extension = path.extension(originalFile.name).toLowerCase();
          final nameWithoutExt = path.basenameWithoutExtension(originalFile.name);
          final tempFile = File('${tempDir.path}/${timestamp}_optimized_$nameWithoutExt.jpg');
          
          await tempFile.writeAsBytes(compressedBytes);
          
          print('✅ Image optimized');
          print('📁 New file size: ${_formatFileSize(compressedBytes.length)}');
          print('💾 Size reduction: ${((fileSize - compressedBytes.length) / fileSize * 100).toStringAsFixed(1)}%');
          
          return XFile(tempFile.path);
        }
      }
      
      // ถ้าไฟล์ไม่ใหญ่หรือไม่สามารถบีบอัดได้ ส่งไฟล์เดิมกลับ
      return originalFile;
      
    } catch (e) {
      print('❌ Error optimizing image: $e');
      return originalFile;
    }
  }
  
  /// ประมวลผลรูปภาพหลายรูปพร้อมกัน
  static Future<List<XFile>> processMultipleImagesAdvanced(List<XFile> imageFiles) async {
    List<XFile> processedImages = [];
    
    print('🔄 Processing ${imageFiles.length} images with advanced handler...');
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        print('Processing image ${i + 1}/${imageFiles.length}: ${imageFiles[i].name}');
        
        final processedImage = await processImageAdvanced(imageFiles[i]);
        processedImages.add(processedImage);
        
        print('✅ Successfully processed ${i + 1}/${imageFiles.length}');
      } catch (e) {
        print('❌ Failed to process image ${i + 1}: $e');
        // ใช้ไฟล์เดิมถ้าประมวลผลไม่ได้
        processedImages.add(imageFiles[i]);
      }
    }
    
    print('🎉 Advanced processing completed: ${processedImages.length}/${imageFiles.length} images');
    return processedImages;
  }
  
  /// ตรวจสอบและวิเคราะห์ไฟล์รูปภาพ
  static Future<Map<String, dynamic>> analyzeImageFile(XFile file) async {
    try {
      final fileSize = await File(file.path).length();
      final fileName = file.name.toLowerCase();
      final extension = path.extension(fileName);
      
      // อ่านข้อมูลรูปภาพ
      final bytes = await file.readAsBytes();
      img.Image? decodedImage;
      
      try {
        decodedImage = img.decodeImage(bytes);
      } catch (e) {
        print('Cannot decode image: $e');
      }
      
      return {
        'name': file.name,
        'path': file.path,
        'size': fileSize,
        'sizeFormatted': _formatFileSize(fileSize),
        'extension': extension,
        'isHeif': isHeifFile(fileName),
        'isValid': isValidImageFile(fileName),
        'canDecode': decodedImage != null,
        'width': decodedImage?.width ?? 0,
        'height': decodedImage?.height ?? 0,
        'aspectRatio': decodedImage != null ? decodedImage.width / decodedImage.height : 0,
        'needsProcessing': _needsProcessing(fileName, fileSize, decodedImage),
        'recommendedAction': _getRecommendedAction(fileName, fileSize, decodedImage),
      };
    } catch (e) {
      return {
        'name': file.name,
        'path': file.path,
        'size': 0,
        'sizeFormatted': '0B',
        'extension': 'unknown',
        'isHeif': false,
        'isValid': false,
        'canDecode': false,
        'error': e.toString(),
        'needsProcessing': true,
        'recommendedAction': 'Error occurred during analysis',
      };
    }
  }
  
  /// ตรวจสอบว่าไฟล์ต้องการการประมวลผลหรือไม่
  static bool _needsProcessing(String fileName, int fileSize, img.Image? decodedImage) {
    // HEIF/HEIC files always need processing
    if (isHeifFile(fileName)) return true;
    
    // Large files need compression
    if (fileSize > 2 * 1024 * 1024) return true;
    
    // Very large dimensions need resizing
    if (decodedImage != null && (decodedImage.width > 2048 || decodedImage.height > 2048)) {
      return true;
    }
    
    return false;
  }
  
  /// แนะนำการกระทำที่ควรทำ
  static String _getRecommendedAction(String fileName, int fileSize, img.Image? decodedImage) {
    if (isHeifFile(fileName)) {
      return 'Convert HEIF/HEIC to JPEG';
    }
    
    if (fileSize > 5 * 1024 * 1024) {
      return 'Compress large file (${_formatFileSize(fileSize)})';
    }
    
    if (decodedImage != null && decodedImage.width > 2048) {
      return 'Resize large dimensions (${decodedImage.width}x${decodedImage.height})';
    }
    
    if (fileSize > 2 * 1024 * 1024) {
      return 'Light compression recommended';
    }
    
    return 'No processing needed';
  }
  
  /// ตรวจสอบว่าเป็นไฟล์รูปภาพหรือไม่
  static bool isValidImageFile(String fileName) {
    final validExtensions = [
      '.jpg', '.jpeg', '.png', '.gif', '.webp', 
      '.heic', '.heif', '.bmp', '.tiff'
    ];
    final extension = path.extension(fileName).toLowerCase();
    return validExtensions.contains(extension);
  }
  
  /// ตรวจสอบว่าเป็นไฟล์ HEIF/HEIC หรือไม่
  static bool isHeifFile(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    return extension == '.heic' || extension == '.heif';
  }
  
  /// แปลงขนาดไฟล์เป็นสตริง
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  
  /// ทำความสะอาดไฟล์ชั่วคราว
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = Directory.systemTemp;
      final files = await tempDir.list().toList();
      
      int deletedCount = 0;
      for (final file in files) {
        if (file is File) {
          final fileName = path.basename(file.path);
          // ลบไฟล์ที่สร้างโดย handler นี้
          if (fileName.contains('_converted_') || 
              fileName.contains('_optimized_') || 
              fileName.contains('_fallback_')) {
            try {
              await file.delete();
              deletedCount++;
            } catch (e) {
              // ไม่สามารถลบได้ อาจถูกใช้งานอยู่
            }
          }
        }
      }
      
      if (deletedCount > 0) {
        print('🧹 Cleaned up $deletedCount temporary image files');
      }
    } catch (e) {
      print('❌ Error cleaning temp files: $e');
    }
  }
  
  /// สร้าง thumbnail จากรูปภาพ
  static Future<XFile?> createThumbnail(XFile originalFile, {int size = 200}) async {
    try {
      final bytes = await originalFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) return null;
      
      // สร้าง thumbnail แบบ square
      final thumbnail = img.copyResizeCropSquare(originalImage, size: size);
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);
      
      // สร้างไฟล์ thumbnail
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nameWithoutExt = path.basenameWithoutExtension(originalFile.name);
      final thumbnailFile = File('${tempDir.path}/${timestamp}_thumb_${nameWithoutExt}.jpg');
      
      await thumbnailFile.writeAsBytes(thumbnailBytes);
      
      print('📷 Created thumbnail: ${thumbnailFile.path}');
      return XFile(thumbnailFile.path);
    } catch (e) {
      print('❌ Error creating thumbnail: $e');
      return null;
    }
  }
}