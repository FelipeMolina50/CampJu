import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/publicacion_model.dart';
import '../../../services/auth_provider.dart';
import '../../../services/publicacion_service.dart';
import 'post_card.dart';

class BosqueFeedWidget extends StatefulWidget {
  final String? bosqueId; // Opcional, si es null carga todas las publicaciones

  const BosqueFeedWidget({super.key, this.bosqueId});

  @override
  State<BosqueFeedWidget> createState() => _BosqueFeedWidgetState();
}

class _BosqueFeedWidgetState extends State<BosqueFeedWidget> {
  final PublicacionService _service = PublicacionService();
  final List<PublicacionModel> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore && _hasMore) {
      _loadMorePosts();
    }
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('publicaciones')
        .orderBy('createdAt', descending: true);
    
    if (widget.bosqueId != null && widget.bosqueId!.isNotEmpty) {
      query = query.where('bosqueId', isEqualTo: widget.bosqueId);
    }
    return query;
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _buildQuery().limit(10).get();

      if (mounted) {
        setState(() {
          _posts.clear();
          _posts.addAll(snapshot.docs.map((doc) => PublicacionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
          if (snapshot.docs.isNotEmpty) {
            _lastDocument = snapshot.docs.last;
          }
          _hasMore = snapshot.docs.length == 10;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_lastDocument == null) return;
    setState(() => _isLoadingMore = true);
    
    try {
      final snapshot = await _buildQuery()
          .startAfterDocument(_lastDocument!)
          .limit(10)
          .get();

      if (mounted) {
        setState(() {
          _posts.addAll(snapshot.docs.map((doc) => PublicacionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
          if (snapshot.docs.isNotEmpty) {
            _lastDocument = snapshot.docs.last;
          }
          _hasMore = snapshot.docs.length == 10;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay publicaciones en tu bosque',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;

    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          final post = _posts[index];
          return PostCard(post: post, currentUserId: userId);
        },
      ),
    );
  }
}
