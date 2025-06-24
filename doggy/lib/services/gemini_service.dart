import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // แทนที่ด้วย API Key ของคุณ
  static const String _apiKey = 'AIzaSyAxDbz9DmXyHd5LvM_fA0exYny7hzdEpd8'; // API Key ที่เห็นใน error
  
  // แก้ไข model name เป็น gemini-1.5-flash ที่ยังรองรับ
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

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
                  'text': '''คุณเป็นผู้เชี่ยวชาญด้านการฝึกสุนัขที่มีประสบการณ์กว่า 10 ปี คุณมีความรู้ลึกเกี่ยวกับ:
- พฤติกรรมสุนัขทุกสายพันธุ์
- เทคนิคการฝึกสุนัขสมัยใหม่
- การแก้ปัญหาพฤติกรรมสุนัข
- การดูแลสุขภาพสุนัข
- การเลือกอาหารและโภชนาการ
- การเล่นและการออกกำลังกาย

โปรดตอบคำถามด้วยน้ำเสียงที่เป็นมิตร เข้าใจง่าย และให้คำแนะนำที่ปฏิบัติได้จริง หากไม่แน่ใจเรื่องใด ให้แนะนำให้ปรึกษาสัตวแพทย์

คำถาม: $message'''
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
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          return 'ขออภัย ไม่สามารถรับคำตอบได้ในขณะนี้ กรุณาลองใหม่';
        }
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return 'เกิดข้อผิดพลาดในการเชื่อมต่อ กรุณาลองใหม่ภายหลัง (Error: ${response.statusCode})';
      }
    } catch (e) {
      print('Error: $e');
      return 'ไม่สามารถเชื่อมต่อได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
    }
  }

  // สำหรับคำถามแนะนำ
  List<String> getSuggestedQuestions() {
    return [
      'สุนัขกัดของเล่นทำยังไงดี?',
      'วิธีฝึกสุนัขให้นั่งยังไง?',
      'สุนัขเห่าตอนกลางคืนแก้ไขอย่างไร?',
      'อาหารไหนดีสำหรับลูกสุนัข?',
      'วิธีฝึกสุนัขให้เดินตามเจ้าของ',
      'สุนัขกลัวเสียงดังทำยังไงดี?',
      'วิธีดูแลฟันสุนัขอย่างไร?',
      'สุนัขไม่ยอมอาบน้ำแก้ไขยังไง?'
    ];
  }
}