import 'package:url_launcher/url_launcher.dart';

class YoutubeService {
  /// เปิดวิดีโอ YouTube จาก videoId
  static Future<void> openVideo(String videoId) async {
    if (videoId.isEmpty) return;

    final Uri appUrl = Uri.parse('youtube://www.youtube.com/watch?v=$videoId');
    final Uri webUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');

    try {
      // พยายามเปิดด้วยแอป YouTube ก่อน
      if (await canLaunchUrl(appUrl)) {
        await launchUrl(
          appUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // fallback เปิดผ่าน browser
        await launchUrl(
          webUrl,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // fallback สุดท้าย
      await launchUrl(
        webUrl,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
