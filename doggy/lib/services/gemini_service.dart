import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyAxDbz9DmXyHd5LvM_fA0exYny7hzdEpd8';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''คุณเป็นผู้เชี่ยวชาญด้านการฝึกสุนัข ตอบคำถามด้วยความเป็นมิตรและใช้ภาษาไทยง่ายๆแบบเป็นกันเอง และกระชับ หลีกเลี่ยงการตอบนอกประเด็นหรือใช้ศัพท์เทคนิคที่ซับซ้อน

📱 กฎการตอบ:
- ตอบสั้นและเข้าใจง่าย (ไม่เกิน 150 คำ)
- ใช้ภาษาไทยเท่านั้น
- แบ่งข้อมูลเป็นหัวข้อสั้นๆ หรือลิสต์รายการ
- เริ่มแต่ละข้อด้วย "- " (เครื่องหมายขีด + ช่องว่าง)
- หลีกเลี่ยงอีโมจิ ใช้เฉพาะเมื่อจำเป็น
- เน้นเนื้อหาที่ปฏิบัติได้จริง
- ข้อความสั้นกระชับ ไม่ซ้ำซาก

ตัวอย่างรูปแบบที่ต้องการ:
วิธีฝึกสุนัขให้นั่ง:

- ถือขนมในมือ 
- ยกมือขึ้นเหนือหัว
- พูด "นั่ง" เสียงใส
- ให้รางวัลทันที

เคล็ดลับ:
- ฝึก 5-10 นาที/วัน
- ใจเย็นและอดทน
- ไม่ตีหรือตะคอกสุนัขเสียงดัง

คำถาม: $message

ตอบแบบสั้นและเข้าใจง่าย:'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.6,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 300, // ลดลงจาก 300 เป็น 250 เพื่อให้สั้นกว่าเดิม
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      print('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          
          if (candidate['content'] != null && 
              candidate['content']['parts'] != null && 
              candidate['content']['parts'].isNotEmpty &&
              candidate['content']['parts'][0]['text'] != null) {
            
            String responseText = candidate['content']['parts'][0]['text'];
            
            responseText = _formatResponseForMobile(responseText);
            
            return responseText;
          }
          else if (candidate['finishReason'] != null) {
            String reason = candidate['finishReason'];
            switch (reason) {
              case 'MAX_TOKENS':
                return 'คำตอบยาวเกินไป กรุณาถามคำถามสั้นๆ';
              case 'SAFETY':
                return 'ขออภัย ไม่สามารถตอบคำถามนี้ได้ ลองถามคำถามอื่นนะครับ';
              case 'RECITATION':
                return 'เนื้อหาอาจมีลิขสิทธิ์ กรุณาถามใหม่';
              default:
                return 'ไม่สามารถสร้างคำตอบได้ ลองใหม่อีกครั้ง';
            }
          }
          else {
            return 'ไม่เข้าใจคำถาม ลองถามใหม่อีกครั้ง';
          }
        } else {
          return 'ไม่สามารถตอบได้ในขณะนี้ ลองถามใหม่นะครับ';
        }
      } else {
        switch (response.statusCode) {
          case 400:
            return 'คำถามไม่ถูกต้อง ลองพิมพ์ใหม่';
          case 401:
            return 'API Key ผิด ติดต่อผู้พัฒนา';
          case 403:
            return 'ไม่มีสิทธิ์ใช้งาน ติดต่อผู้พัฒนา';
          case 429:
            return 'ใช้งานเกินขีดจำกัด รอสักครู่แล้วลองใหม่';
          case 500:
            return 'เซิร์ฟเวอร์มีปัญหา ลองใหม่ภายหลัง';
          default:
            return 'เชื่อมต่อไม่ได้ ตรวจสอบอินเทอร์เน็ต';
        }
      }
    } catch (e) {
      print('Error: $e');
      return 'ไม่สามารถเชื่อมต่อได้ ตรวจสอบอินเทอร์เน็ต';
    }
  }

  /// ปรับรูปแบบข้อความให้เหมาะกับการอ่านบนมือถือและลดการใช้อีโมจิ
  String _formatResponseForMobile(String text) {
    // จำกัดความยาวของข้อความ
    if (text.length > 350) {
      text = text.substring(0, 350) + '...';
    }
    
    // ลบอีโมจิทั้งหมด
    text = text.replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true), '');
    
    // แทนที่ bullet points ต่างๆ ด้วยรูปแบบเดียวกัน
    text = text.replaceAll('•', '- ');
    text = text.replaceAll('*', '- ');
    text = text.replaceAll('○', '- ');
    text = text.replaceAll('◦', '- ');
    text = text.replaceAll('▪', '- ');
    text = text.replaceAll('▫', '- ');
    
    // ปรับปรุงการจัดรูปแบบ list
    text = text.replaceAllMapped(RegExp(r'^(\s*)[-]\s*(.+)$', multiLine: true), (match) {
      return '- ${match.group(2)!.trim()}';
    });
    
    // เพิ่ม line break หลังจากเครื่องหมายวรรคตอน
    text = text.replaceAll(RegExp(r'\.(?!\s|\n|$)'), '.\n');
    text = text.replaceAll(RegExp(r'!(?!\s|\n|$)'), '!\n');
    text = text.replaceAll(RegExp(r'\?(?!\s|\n|$)'), '?\n');
    text = text.replaceAll(RegExp(r':(?!\s|\n|$)'), ':\n');
    
    // ลบบรรทัดว่างซ้ำ
    text = text.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    
    // ปรับหัวข้อให้มี format ที่ดี
    text = text.replaceAllMapped(RegExp(r'^(.+):$', multiLine: true), (match) {
      String title = match.group(1)!.trim();
      if (title.length > 2 && !title.startsWith('-')) {
        return '$title:\n';
      }
      return match.group(0)!;
    });
    
    // ลบช่องว่างเกินและปรับให้เรียบร้อย
    text = text.trim();
    text = text.replaceAll(RegExp(r' +'), ' '); // ลบช่องว่างเกิน
    text = text.replaceAll(RegExp(r'\n +'), '\n'); // ลบช่องว่างหน้าบรรทัด
    
    return text;
  }

  List<String> getSuggestedQuestions() {
    return [
      'สุนัขกัดของเล่น',
      'ฝึกให้นั่ง',
      'หยุดเห่า',
      'อาหารลูกสุนัข',
      'เดินตาม',
      'กลัวเสียงดัง',
      'ดูแลฟัน',
      'อาบน้ำ',
      'สุนัขเศร้า',
      'ฝึกให้ไม่กระโดด'
    ];
  }

  Future<bool> testConnection() async {
    try {
      final testResponse = await sendMessage('ทดสอบ');
      return !testResponse.contains('เชื่อมต่อไม่ได้') && 
             !testResponse.contains('API Key ผิด') &&
             !testResponse.contains('ไม่มีสิทธิ์');
    } catch (e) {
      return false;
    }
  }

  /// ตรวจสอบคุณภาพของ API Key
  Future<String> validateApiKey() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': 'test'}]
            }
          ]
        }),
      );

      switch (response.statusCode) {
        case 200:
          return 'API Key ใช้งานได้';
        case 401:
          return 'API Key ไม่ถูกต้อง';
        case 403:
          return 'API Key ไม่มีสิทธิ์ใช้งาน';
        case 429:
          return 'API Key ใช้งานเกินขีดจำกัด';
        default:
          return 'ไม่สามารถตรวจสอบ API Key ได้';
      }
    } catch (e) {
      return 'เกิดข้อผิดพลาดในการตรวจสอบ API Key';
    }
  }

  /// ตรวจสอบและทำความสะอาดข้อความที่ป้อนเข้า
  String _sanitizeInput(String input) {
    // ลบอักขระพิเศษที่อาจทำให้เกิดปัญหา
    input = input.trim();
    
    // จำกัดความยาวของข้อความป้อนเข้า
    if (input.length > 200) {
      input = input.substring(0, 200);
    }
    
    return input;
  }

  /// ส่งข้อความที่ผ่านการตรวจสอบแล้ว
  Future<String> sendSafeMessage(String message) async {
    final sanitizedMessage = _sanitizeInput(message);
    
    if (sanitizedMessage.isEmpty) {
      return 'กรุณาป้อนคำถาม';
    }
    
    return await sendMessage(sanitizedMessage);
  }
}