import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'deleted_items_service.dart';

class RecentlyDeletedScreen extends StatefulWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  State<RecentlyDeletedScreen> createState() => _RecentlyDeletedScreenState();
}

class _RecentlyDeletedScreenState extends State<RecentlyDeletedScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const int _pageSize = 30;

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];

  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _isActionLoading = false;
  bool _hasMore = true;
  String? _error;
  String searchQuery = '';

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _baseQuery() {
    return FirebaseFirestore.instance
        .collection('deleted_items')
        .orderBy('deletedAt', descending: true);
  }

  Future<void> _loadInitial() async {
    if (mounted) {
      setState(() {
        _isLoadingInitial = true;
        _error = null;
      });
    }

    try {
      _docs.clear();
      _lastDoc = null;
      _hasMore = true;

      final snapshot = await _baseQuery().limit(_pageSize).get();

      _docs.addAll(snapshot.docs);
      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
      }
      _hasMore = snapshot.docs.length == _pageSize;

      if (!mounted) return;
      setState(() {
        _isLoadingInitial = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingInitial = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final snapshot = await _baseQuery()
          .startAfterDocument(_lastDoc!)
          .limit(_pageSize)
          .get();

      _docs.addAll(snapshot.docs);
      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
      }
      _hasMore = snapshot.docs.length == _pageSize;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    if (_isActionLoading) return;

    try {
      setState(() {
        _isActionLoading = true;
      });

      await action();
      await _loadInitial();

      if (!mounted) return;
      if (successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  String _safeString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString();
  }

  DateTime? _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) {
      final m = difference.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (difference.inHours < 24) {
      final h = difference.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 7) {
      final d = difference.inDays;
      return '$d day${d == 1 ? '' : 's'} ago';
    }
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (searchQuery.trim().isEmpty) return true;

    final q = searchQuery.trim().toLowerCase();

    final fields = [
      _safeString(data['venueName']),
      _safeString(data['title']),
      _safeString(data['subtitle']),
      _safeString(data['deletedByEmail']),
      _safeString(data['itemType']),
    ].join(' ').toLowerCase();

    if (fields.contains(q)) return true;

    final searchTerms = (data['searchTerms'] as List?) ?? [];
    for (final term in searchTerms) {
      if (term.toString().toLowerCase().contains(q)) {
        return true;
      }
    }

    return false;
  }

  Widget _buildTile(Map<String, dynamic> data) {
    final sourceCollection = _safeString(data['sourceCollection']);
    final sourceDocId = _safeString(data['sourceDocId']);
    final title = _safeString(data['title'], 'Untitled');
    final subtitle = _safeString(data['subtitle'], 'No details');
    final deletedByEmail = _safeString(data['deletedByEmail'], 'Unknown user');
    final itemType = _safeString(data['itemType'], 'item');
    final deletedAt = _asDate(data['deletedAt']);

    final deletedText = deletedAt == null
        ? 'Unknown time'
        : '${_timeAgo(deletedAt)} (${DateFormat('dd MMM yyyy, HH:mm').format(deletedAt)})';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          '$itemType\n$subtitle\nDeleted by: $deletedByEmail\nDeleted: $deletedText',
          style: const TextStyle(height: 1.4),
        ),
        trailing: PopupMenuButton<String>(
          enabled: !_isActionLoading,
          onSelected: (value) {
            if (value == 'restore') {
              _runAction(
                () => DeletedItemsService.restoreItem(
                  collection: sourceCollection,
                  docId: sourceDocId,
                ),
                successMessage: 'Item restored successfully.',
              );
            } else if (value == 'delete') {
              _runAction(
                () => DeletedItemsService.permanentlyDeleteItem(
                  collection: sourceCollection,
                  docId: sourceDocId,
                ),
                successMessage: 'Item permanently deleted.',
              );
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'restore', child: Text('Restore')),
            PopupMenuItem(value: 'delete', child: Text('Delete Forever')),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList() {
    final filtered = _docs.where((d) => _matchesSearch(d.data())).toList();

    final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped = {};

    for (final doc in filtered) {
      final data = doc.data();
      final venueId = _safeString(data['venueId'], 'unknown-venue');
      grouped.putIfAbsent(venueId, () => []);
      grouped[venueId]!.add(doc);
    }

    final groups = grouped.entries.toList();

    groups.sort((a, b) {
      final aDate = a.value.isNotEmpty ? _asDate(a.value.first.data()['deletedAt']) : null;
      final bDate = b.value.isNotEmpty ? _asDate(b.value.first.data()['deletedAt']) : null;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    if (groups.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 140),
          Center(child: Text('No matching deleted items.')),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: groups.length + (_hasMore || _isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= groups.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: _isLoadingMore
                  ? const CircularProgressIndicator()
                  : const Text('Scroll to load more'),
            ),
          );
        }

        final entry = groups[index];
        final items = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(entry.value);

        items.sort((a, b) {
          final aDate = _asDate(a.data()['deletedAt']);
          final bDate = _asDate(b.data()['deletedAt']);

          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

        final first = items.first.data();
        final venueName = _safeString(first['venueName'], 'Unknown Venue');
        final latestDeletedAt = _asDate(first['deletedAt']);

        final latestText = latestDeletedAt == null
            ? 'Unknown time'
            : '${_timeAgo(latestDeletedAt)} (${DateFormat('dd MMM yyyy, HH:mm').format(latestDeletedAt)})';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              venueName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${items.length} deleted item(s)\nLatest deletion: $latestText',
              style: const TextStyle(height: 1.4),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isActionLoading
                        ? null
                        : () {
                            _runAction(
                              () => DeletedItemsService.restoreVenueGroup(
                                venueId: entry.key,
                              ),
                              successMessage: 'Venue group restored successfully.',
                            );
                          },
                    icon: const Icon(Icons.restore),
                    label: const Text('Restore All'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isActionLoading
                        ? null
                        : () {
                            _runAction(
                              () => DeletedItemsService.permanentlyDeleteVenueGroup(
                                venueId: entry.key,
                              ),
                              successMessage: 'Venue group permanently deleted.',
                            );
                          },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete All Forever'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...items.map((doc) => _buildTile(doc.data())),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final noItems = _docs.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Deleted'),
        actions: [
          IconButton(
            onPressed: (_isLoadingInitial || _isActionLoading) ? null : _loadInitial,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (value) {
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                      if (!mounted) return;
                      setState(() {
                        searchQuery = value.trim();
                      });
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Search deleted items',
                    hintText: 'e.g. mojito, happy hour, venue, owner@email.com',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchDebounce?.cancel();
                              searchController.clear();
                              setState(() {
                                searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _isLoadingInitial
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text('Error: $_error'))
                          : noItems
                              ? RefreshIndicator(
                                  onRefresh: _loadInitial,
                                  child: ListView(
                                    controller: _scrollController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: const [
                                      SizedBox(height: 140),
                                      Center(child: Text('No deleted items.')),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadInitial,
                                  child: _buildGroupedList(),
                                ),
                ),
              ],
            ),
          ),
          if (_isActionLoading)
            Container(
              color: Colors.black.withOpacity(0.08),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}