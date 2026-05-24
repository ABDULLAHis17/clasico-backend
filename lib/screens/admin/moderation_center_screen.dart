import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ModerationCenterScreen extends StatefulWidget {
  const ModerationCenterScreen({super.key});

  @override
  State<ModerationCenterScreen> createState() => _ModerationCenterScreenState();
}

class _ModerationCenterScreenState extends State<ModerationCenterScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _reportedComments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchReportedComments();
  }

  Future<void> _fetchReportedComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await _apiService.getReportedComments();
      setState(() {
        _reportedComments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في جلب البلاغات: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('مركز الإشراف'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.auto_awesome), onPressed: () {
            // TODO: Trigger AI Auto-hide
          }, tooltip: 'إخفاء تلقائي بالذكاء الاصطناعي'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchReportedComments),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : RefreshIndicator(
              onRefresh: _fetchReportedComments,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _reportedComments.length,
                itemBuilder: (context, index) {
                  final item = _reportedComments[index];
                  return _buildReportedCommentCard(item);
                },
              ),
            ),
    );
  }

  Widget _buildReportedCommentCard(Map<String, dynamic> item) {
    final comment = item['comment'] as Map<String, dynamic>;
    final reportCount = item['report_count'] ?? 0;
    final toxicity = comment['toxicity_score'] ?? 0.0;
    final isToxic = toxicity > 0.7;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToxic ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'عدد البلاغات: $reportCount',
                      style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                    ),
                    _buildToxicityBadge(toxicity),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  comment['content'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'معرّف المستخدم: ${comment['user_id']}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // TODO: Resolve (Keep)
                  },
                  icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                  label: const Text('إبقاء', style: TextStyle(color: Colors.greenAccent)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    final confirmed = await _showConfirmDelete(comment['id']);
                    if (confirmed) {
                      await _apiService.deleteComment(comment['id']);
                      _fetchReportedComments();
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToxicityBadge(double score) {
    Color color = Colors.greenAccent;
    if (score > 0.4) color = Colors.orangeAccent;
    if (score > 0.7) color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_alt_rounded, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            'ذكاء اصطناعي: ${(score * 100).toInt()}%',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDelete(String id) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من حذف هذا التعليق المسيء؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    ) ?? false;
  }
}
