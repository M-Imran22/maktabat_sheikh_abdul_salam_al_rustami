import 'package:flutter/material.dart';

class BiographyScreen extends StatelessWidget {
  const BiographyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'شیخ کا تعارف',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Sheikh's Image
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(75),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                size: 80,
                color: Colors.green[700],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Sheikh's Name
            const Text(
              'شیخ عبدالسلام الرستمی',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 10),
            
            Text(
              'رحمہ اللہ تعالیٰ',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Biography Content
            _buildBiographySection(
              'ابتدائی زندگی',
              'شیخ عبدالسلام الرستمی رحمہ اللہ کی پیدائش اور ابتدائی تعلیم کے بارے میں تفصیلی معلومات۔ آپ نے اپنی ابتدائی تعلیم مقامی علماء سے حاصل کی۔',
            ),
            
            _buildBiographySection(
              'علمی خدمات',
              'آپ نے اسلامی علوم میں گہری مہارت حاصل کی اور مختلف موضوعات پر قیمتی کتب تصنیف کیں۔ آپ کی تعلیمات نے ہزاروں طلباء کو فائدہ پہنچایا۔',
            ),
            
            _buildBiographySection(
              'تصنیفات',
              'شیخ کی متعدد کتب مختلف اسلامی موضوعات پر موجود ہیں جن میں فقہ، حدیث، تفسیر اور اخلاق شامل ہیں۔ یہ تمام کتب اس ایپلیکیشن میں دستیاب ہیں۔',
            ),
            
            _buildBiographySection(
              'وفات',
              'شیخ عبدالسلام الرستمی رحمہ اللہ کا انتقال ہوا اور آپ کی علمی میراث آج بھی لوگوں کو فائدہ پہنچا رہی ہے۔ اللہ تعالیٰ آپ کو جنت الفردوس میں اعلیٰ مقام عطا فرمائے۔',
            ),
            
            const SizedBox(height: 30),
            
            // Prayer for Sheikh
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Text(
                'رَبِّ اغْفِرْ لَهُ وَارْحَمْهُ وَأَدْخِلْهُ فِي عِبَادِكَ الصَّالِحِينَ\n\nاے اللہ! انہیں بخش دے، ان پر رحم فرما اور انہیں اپنے نیک بندوں میں داخل فرما۔',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiographySection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 15),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.8,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}