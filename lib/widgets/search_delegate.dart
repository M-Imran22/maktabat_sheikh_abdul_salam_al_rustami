import 'package:flutter/material.dart';

class BookSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, String>> books;

  BookSearchDelegate(this.books);

  @override
  String get searchFieldLabel => 'کتاب تلاش کریں...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final trimmed = query.trim().toLowerCase();
    final results =
        books.where((book) {
          final title = (book['title'] ?? '').toLowerCase();
          final category = (book['category'] ?? '').toLowerCase();
          final description = (book['description'] ?? '').toLowerCase();
          return title.contains(trimmed) ||
              category.contains(trimmed) ||
              description.contains(trimmed);
        }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text(
          'کوئی کتاب نہیں ملی',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final book = results[index];
          final title = book['title'] ?? '';
          final category = book['category'] ?? '';
          final pages = book['pages'] != null ? '${book['pages']} صفحات' : '';

          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.black12,
              child: Icon(Icons.menu_book_rounded, color: Colors.black87),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              category.isNotEmpty && pages.isNotEmpty
                  ? '$category • $pages'
                  : category,
              style: const TextStyle(color: Colors.black54),
            ),
            trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
            onTap: () => close(context, title),
          );
        },
      ),
    );
  }
}
