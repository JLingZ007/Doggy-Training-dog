import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class SimpleImageHandler {
  /// แปลงไฟล์ HEIF/HEIC เป็น JPEG (พื้นฐาน)
  static Future<XFile> processImageBasic(XFile originalFile) async {
    try {
      final fileName = originalFile.name.toLowerCase();
      
      // ตรวจสอบว่าเป็นไฟล์ HEIF/HEIC หรือไม่
      if (fileName.endsWith('.heic') || fileName.endsWith('.heif')) {
        print('🔄 Processing HEIF/HEIC file: ${originalFile.name}');
        
        // สร้างชื่อไฟล์ใหม่เป็น .jpg
        final newFileName = fileName
            .replaceAll('.heic', '.jpg')
            .replaceAll('.heif', '.jpg');
        
        // อ่านข้อมูลไฟล์
        final bytes = await originalFile.readAsBytes();
        
        // สร้างไฟล์ชั่วคราวใหม่
        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempFile = File('${tempDir.path}/${timestamp}_$newFileName');
        
        // เขียนข้อมูลลงไฟล์ใหม่
        await tempFile.writeAsBytes(bytes);
        
        print('✅ Converted HEIF to: ${tempFile.path}');
        return XFile(tempFile.path);
      }
      
      // ตรวจสอบขนาดไฟล์
      final fileSize = await File(originalFile.path).length();
      print('📁 File size: ${_formatFileSize(fileSize)}');
      
      // ถ้าไฟล์ใหญ่เกิน 5MB ให้แจ้งเตือน
      if (fileSize > 5 * 1024 * 1024) {
        print('⚠️ Large file detected (${_formatFileSize(fileSize)}). Consider resizing.');
      }
      
      return originalFile;
    } catch (e) {
      print('❌ Error processing image: $e');
      return originalFile;
    }
  }
  
  /// ประมวลผลรูปภาพหลายรูป
  static Future<List<XFile>> processMultipleImages(List<XFile> imageFiles) async {
    List<XFile> processedImages = [];
    
    print('🔄 Processing ${imageFiles.length} images...');
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final processedImage = await processImageBasic(imageFiles[i]);
        processedImages.add(processedImage);
        print('✅ Processed ${i + 1}/${imageFiles.length}: ${imageFiles[i].name}');
      } catch (e) {
        print('❌ Failed to process image ${i + 1}: $e');
        processedImages.add(imageFiles[i]); // ใช้ไฟล์เดิมถ้าประมวลผลไม่ได้
      }
    }
    
    print('🎉 Successfully processed ${processedImages.length}/${imageFiles.length} images');
    return processedImages;
  }
  
  /// ตรวจสอบว่าเป็นไฟล์รูปภาพหรือไม่
  static bool isValidImageFile(String fileName) {
    final validExtensions = [
      '.jpg', '.jpeg', '.png', '.gif', '.webp', 
      '.heic', '.heif', '.bmp'
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
  
  /// ดึงข้อมูลพื้นฐานของไฟล์
  static Future<Map<String, dynamic>> getFileInfo(XFile file) async {
    try {
      final fileSize = await File(file.path).length();
      
      return {
        'name': file.name,
        'path': file.path,
        'size': fileSize,
        'sizeFormatted': _formatFileSize(fileSize),
        'extension': path.extension(file.name),
        'isHeif': isHeifFile(file.name),
        'isValid': isValidImageFile(file.name),
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
        'error': e.toString(),
      };
    }
  }
  
  /// ทำความสะอาดไฟล์ชั่วคราว
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = Directory.systemTemp;
      final files = await tempDir.list().toList();
      
      int deletedCount = 0;
      for (final file in files) {
        if (file is File && file.path.contains('.jpg')) {
          try {
            await file.delete();
            deletedCount++;
          } catch (e) {
            // ไม่สามารถลบได้ อาจถูกใช้งานอยู่
          }
        }
      }
      
      if (deletedCount > 0) {
        print('🧹 Cleaned up $deletedCount temporary files');
      }
    } catch (e) {
      print('❌ Error cleaning temp files: $e');
    }
  }
}