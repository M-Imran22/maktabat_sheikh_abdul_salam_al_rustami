import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/books_screen.dart';
import 'screens/audio_screen.dart';
import 'screens/biography_screen.dart';

void main() {
  runApp(const MaktabatApp());
}

class MaktabatApp extends StatelessWidget {
  const MaktabatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مکتبہ شیخ عبدالسلام الرستمی',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Amiri',
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text(
          'مکتبہ شیخ عبدالسلام الرستمی',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Sheikh's Image
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green[700]!, Colors.green[500]!],
                ),
              ),
              child: Stack(
                children: [
                  // Sheikh's Info
                  const Positioned(
                    right: 20,
                    bottom: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'کتب و مؤلفات',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'شیخ عبدالسلام الرستمی',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'رحمہ اللہ تعالیٰ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sheikh's Image Placeholder
                  const Positioned(
                    left: 20,
                    bottom: 30,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Welcome Text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'بسم اللہ الرحمن الرحیم\n\nالحمد للہ رب العالمین والصلاۃ والسلام علی رسولہ الکریم\n\nاس ایپلیکیشن میں شیخ عبدالسلام الرستمی رحمہ اللہ کی تمام کتب اور آڈیو لیکچرز موجود ہیں۔ اللہ تعالیٰ ہم سب کو ان سے فائدہ اٹھانے کی توفیق عطا فرمائے۔',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: Colors.black87,
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Main Navigation Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Books Section
                  _buildNavigationCard(
                    title: 'کتابیں (PDF)',
                    subtitle: 'شیخ کی تمام کتب',
                    icon: Icons.menu_book,
                    color: Colors.blue[700]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BooksScreen()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Audio Section
                  _buildNavigationCard(
                    title: 'آڈیو لیکچرز',
                    subtitle: 'تمام آڈیو بیانات',
                    icon: Icons.headphones,
                    color: Colors.orange[700]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AudioScreen()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // About Sheikh Section
                  _buildNavigationCard(
                    title: 'شیخ کا تعارف',
                    subtitle: 'حالات زندگی',
                    icon: Icons.person_outline,
                    color: Colors.green[700]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BiographyScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Contact Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
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
                children: [
                  const Text(
                    'رابطہ اور شیئرنگ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'اگر آپ کو کوئی مسئلہ ہو یا تجاویز ہوں تو ہم سے رابطہ کریں',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.share,
                        label: 'شیئر',
                        color: Colors.blue,
                        onTap: () {},
                      ),
                      _buildActionButton(
                        icon: Icons.email,
                        label: 'ای میل',
                        color: Colors.red,
                        onTap: () {},
                      ),
                      _buildActionButton(
                        icon: Icons.star,
                        label: 'ریٹنگ',
                        color: Colors.amber,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
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
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}