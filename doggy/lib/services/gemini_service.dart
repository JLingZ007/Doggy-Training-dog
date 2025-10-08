import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY']!;
  static final String _baseUrl = dotenv.env['GEMINI_BASE_URL']!;

  /// ส่งข้อความไปยัง Gemini API พร้อม prompt ที่ปรับปรุงใหม่
  Future<String> sendMessage(String message) async {
    // ป้องกันการส่งข้อความว่างหรือยาวเกินไป
    final sanitizedMessage = _sanitizeInput(message);
    if (sanitizedMessage.isEmpty) {
      return 'กรุณาป้อนคำถาม';
    }

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
                  // --- Prompt ที่ปรับปรุงใหม่ ---
                  'text': '''คุณคือ "ผู้ช่วยฝึกสุนัข" เป็น AI ที่เชี่ยวชาญและเป็นมิตร
                  
                  **กฎการตอบ:**
                  1.  **ตอบสั้นและกระชับมาก:** ไม่เกิน 1-2 ย่อหน้าสั้นๆ (ประมาณ 400 อักขระ)
                  2.  **ใช้ภาษาไทยเท่านั้น:** เป็นกันเอง เข้าใจง่าย
                  3.  **จัดรูปแบบเสมอ:**
                      - ใช้หัวข้อที่ชัดเจน (เช่น "วิธีแก้:", "เคล็ดลับ:")
                      - แบ่งเนื้อหาเป็นลิสต์รายการสั้นๆ โดยใช้ "- " นำหน้าเสมอ
                  4.  **ตรงประเด็น:** ตอบเฉพาะคำถาม ไม่ต้องเกริ่นนำหรือสรุปยาว
                  5.  **ห้ามใช้อีโมจิ**

                  **ตัวอย่างรูปแบบที่สมบูรณ์แบบ:**
                  
                  ฝึกสุนัขให้นั่ง:
                  
                  - ถือขนมไว้เหนือหัวสุนัขเล็กน้อย
                  - พูดคำสั่ง "นั่ง" ด้วยเสียงที่ชัดเจน
                  - เมื่อสุนัขนั่ง ให้รางวัลทันที
                  
                  เคล็ดลับเพิ่มเติม:
                  - ฝึกครั้งละ 5-10 นาที
                  - ทำซ้ำๆ และใจเย็น
                  
                  ---
                  
                  **คำถามจากผู้ใช้:** $sanitizedMessage
                  '''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
            {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
            {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
            {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'}
          ]
        }),
      );

      return _handleResponse(response);

    } catch (e) {
      print('Error sending message: $e');
      return 'เชื่อมต่อไม่ได้ โปรดตรวจสอบอินเทอร์เน็ต';
    }
  }
  
  /// จัดการกับการตอบกลับจาก API
  String _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)); // แก้ปัญหาภาษาไทย

      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final candidate = data['candidates'][0];

        if (candidate['content']?['parts']?[0]?['text'] != null) {
          String responseText = candidate['content']['parts'][0]['text'];
          return _formatResponse(responseText);
        } 
        else if (candidate['finishReason'] != null) {
          // จัดการกรณีที่ API ไม่สามารถสร้างคำตอบได้
          return _getErrorMessageForFinishReason(candidate['finishReason']);
        }
      }
      return 'ไม่ได้รับคำตอบที่สมบูรณ์ ลองใหม่อีกครั้ง';
    } else {
      // จัดการกับ HTTP Error Codes
      return _getErrorMessageForStatusCode(response.statusCode);
    }
  }

  /// ฟังก์ชันทำความสะอาดข้อความที่ได้รับจาก Gemini (ปรับปรุงใหม่)
  String _formatResponse(String text) {
    // 1. ลบช่องว่างที่ไม่จำเป็นที่หัวและท้ายข้อความ
    text = text.trim();
    // 2. ทำให้มีบรรทัดว่างระหว่างย่อหน้าไม่เกิน 1 บรรทัด
    text = text.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    return text;
  }

  /// เตรียมข้อความจากผู้ใช้ก่อนส่ง
  String _sanitizeInput(String input) {
    String sanitized = input.trim();
    if (sanitized.length > 200) {
      sanitized = sanitized.substring(0, 200);
    }
    return sanitized;
  }
  
  /// แปลง Finish Reason เป็นข้อความที่ผู้ใช้เข้าใจง่าย
  String _getErrorMessageForFinishReason(String reason) {
    switch (reason) {
      case 'SAFETY':
        return 'ขออภัย ไม่สามารถตอบคำถามนี้ได้เนื่องจากข้อจำกัดด้านความปลอดภัย';
      case 'MAX_TOKENS':
        return 'คำตอบยาวเกินไป ระบบตัดข้อความบางส่วนออก';
      default:
        return 'ไม่สามารถสร้างคำตอบได้ ลองเปลี่ยนคำถามดูนะครับ';
    }
  }
  
  /// แปลง Status Code เป็นข้อความที่ผู้ใช้เข้าใจง่าย
  String _getErrorMessageForStatusCode(int statusCode) {
    switch (statusCode) {
      case 400: return 'คำถามไม่ถูกต้อง ลองพิมพ์ใหม่';
      case 429: return 'ใช้งานเกินขีดจำกัด รอสักครู่แล้วลองใหม่';
      case 500: return 'เซิร์ฟเวอร์มีปัญหา ลองใหม่ภายหลัง';
      default: return 'เกิดข้อผิดพลาด (${statusCode})';
    }
  }
  
  /// รายการคำถามแนะนำ (เหมือนเดิม)
  List<String> getSuggestedQuestions() {
    return [
      'สอนให้นั่ง',
      'ทำไมสุนัขชอบกัดของ',
      'วิธีหยุดไม่ให้สุนัขเห่า',
      'อาหารที่ลูกสุนัขควรกิน',
      'ฝึกให้สุนัขเดินตาม',
      'สุนัขกลัวเสียงดังทำไง',
      'วิธีดูแลฟันสุนัข',
      'ควรอาบน้ำสุนัขบ่อยแค่ไหน'
    ];
  }
}