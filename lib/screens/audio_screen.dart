import 'package:flutter/material.dart';

class AudioScreen extends StatelessWidget {
  const AudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'آڈیو لیکچرز',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sampleAudios.length,
        itemBuilder: (context, index) {
          final audio = _sampleAudios[index];
          return _buildAudioCard(audio, context);
        },
      ),
    );
  }

  Widget _buildAudioCard(Map<String, String> audio, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            Icons.play_arrow,
            color: Colors.orange[700],
            size: 30,
          ),
        ),
        title: Text(
          audio['title']!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.right,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              audio['description']!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 5),
            Text(
              audio['duration']!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.headphones,
          color: Colors.grey,
          size: 20,
        ),
        onTap: () {
          _playAudio(context, audio);
        },
      ),
    );
  }

  void _playAudio(BuildContext context, Map<String, String> audio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing ${audio['title']}...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  static final List<Map<String, String>> _sampleAudios = [
    {
      'title': 'توحید کی اہمیت',
      'description': 'توحید کے بنیادی اصول',
      'duration': '45:30',
    },
    {
      'title': 'نماز کے آداب',
      'description': 'نماز کی صحیح ادائیگی',
      'duration': '32:15',
    },
    {
      'title': 'قرآن کی تلاوت',
      'description': 'قرآن مجید کی تجوید',
      'duration': '28:45',
    },
    {
      'title': 'اخلاق اسلامی',
      'description': 'اسلامی اخلاق کی بنیادیں',
      'duration': '41:20',
    },
    {
      'title': 'دعا کی اہمیت',
      'description': 'دعا کے آداب و فضائل',
      'duration': '35:10',
    },
  ];
}