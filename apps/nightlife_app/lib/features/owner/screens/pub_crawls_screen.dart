
import 'package:flutter/material.dart';
import '../../../core/widgets/premium_scaffold.dart';
import '../../../core/theme/app_colors.dart';

class PubCrawlsScreen extends StatelessWidget {
  const PubCrawlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      appBar: AppBar(title: const Text('Pub Crawls')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _CrawlCard('London Cocktail Crawl','12 venues • 4 hours'),
          _CrawlCard('Craft Beer Trail','8 venues • 3 hours'),
          _CrawlCard('Hidden Speakeasy Crawl','6 venues • 5 hours'),
        ],
      ),
    );
  }
}

class _CrawlCard extends StatelessWidget {
  final String title; final String subtitle;
  const _CrawlCard(this.title,this.subtitle);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom:16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.08),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.primaryPurple.withOpacity(.35)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
      Text(title,style: const TextStyle(fontSize:20,fontWeight:FontWeight.bold,color: Colors.white)),
      const SizedBox(height:8),
      Text(subtitle,style: const TextStyle(color: Colors.white70)),
    ]),
  );
}
