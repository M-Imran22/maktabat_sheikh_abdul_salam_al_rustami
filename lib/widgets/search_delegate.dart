import 'package:flutter/material.dart';

class BookSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, String>> books;

  BookSearchDelegate(this.books);

  @override
  String get searchFieldLabel => 'کتاب تلاش کریں...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
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
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = books.where((book) =>
        book['title']!.contains(query) ||
        book['description']!.contains(query)).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final book = results[index];
        return ListTile(
          title: Text(book['title']!, textAlign: TextAlign.right),
          subtitle: Text(book['description']!, textAlign: TextAlign.right),
          onTap: () => close(context, book['title']!),
        );
      },
    );
  }
}