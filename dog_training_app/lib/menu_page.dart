import 'package:flutter/material.dart';
import 'training_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  final List<Map<String, String>> trainingOptions = const [
    {'title': 'ฝึกการนั่ง', 'image': 'assets/images/sit.png', 'video': 'assets/videos/sit_training.mp4'},
    {'title': 'ฝึกการรอ', 'image': 'assets/images/stay.png', 'video': 'assets/videos/stay_training.mp4'},
    {'title': 'ฝึกการมา', 'image': 'assets/images/come.png', 'video': 'assets/videos/come_training.mp4'},
    {'title': 'ฝึกการนอน', 'image': 'assets/images/down.png', 'video': 'assets/videos/down_training.mp4'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การฝึกพื้นฐาน'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: trainingOptions.length,
        itemBuilder: (context, index) {
          final training = trainingOptions[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12.0),
                    ),
                    child: Image.asset(
                      training['image']!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    training['title']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrainingDetailPage(
                            title: training['title']!,
                            videoPath: training['video']!,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      minimumSize: const Size(40, 40),
                    ),
                    child: const Text(
                      "เข้าสู่การฝึก",
                      style: TextStyle(
                        fontSize: 16,               
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,  
                        fontFamily: 'Roboto',  
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
