import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final Future<String> _policy = rootBundle.loadString(
    'assets/data/privacy_policy_ur.txt',
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('رازداری کی پالیسی')),
        body: SafeArea(
          child: FutureBuilder<String>(
            future: _policy,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('پالیسی دکھانے میں خرابی ہوئی۔'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  snapshot.data!,
                  textDirection: TextDirection.rtl,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.8),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
