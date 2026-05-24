import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class UserFeedbackScreen extends StatefulWidget {
  const UserFeedbackScreen({super.key});

  @override
  State<UserFeedbackScreen> createState() => _UserFeedbackScreenState();
}

class _UserFeedbackScreenState extends State<UserFeedbackScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _feedbackList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchFeedback();
  }

  Future<void> _fetchFeedback() async {
    setState(() => _isLoading = true);
    try {
      final feedback = await _apiService.getAdminFeedback();
      setState(() {
        _feedbackList = feedback;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في جلب الرسائل: $e')),
      );
    }
  }

  Future<void> _resolveFeedback(int id, {bool reject = false}) async {
    try {
      final success = await _apiService.resolveAdminFeedback(id, reject: reject);
      if (success) {
        _fetchFeedback(); // Refresh the list
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reject ? 'تم رفض الرسالة' : 'تم تحديد الرسالة كمقروءة/محلولة'),
            backgroundColor: reject ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('رسائل وبلاغات المستخدمين'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchFeedback),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _feedbackList.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد رسائل حالياً',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchFeedback,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _feedbackList.length,
                    itemBuilder: (context, index) {
                      final item = _feedbackList[index];
                      return _buildFeedbackCard(item);
                    },
                  ),
                ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'pending';
    final isResolved = status == 'resolved';
    final isRejected = status == 'rejected';
    
    Color statusColor = Colors.orangeAccent;
    String statusText = 'قيد الانتظار';
    
    if (isResolved) {
      statusColor = Colors.greenAccent;
      statusText = 'محلول';
    } else if (isRejected) {
      statusColor = Colors.redAccent;
      statusText = 'مرفوض';
    }

    // Usually reporter_id is "system_public" but we can check if it's a real user ID
    final reporterId = item['reporter_id'] ?? 'Unknown';
    final isPublic = reporterId == 'system_public';

    final createdAt = item['created_at'] != null 
        ? DateTime.parse(item['created_at']) 
        : DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item['reason'] ?? 'بدون نص',
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(isPublic ? Icons.public : Icons.person, size: 14, color: Colors.blueAccent),
                    const SizedBox(width: 4),
                    Text(
                      isPublic ? 'زائر' : 'مستخدم: $reporterId',
                      style: TextStyle(color: Colors.blueAccent.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (status == 'pending') ...[
            Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _resolveFeedback(item['id'], reject: true),
                    icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                    label: const Text('رفض', style: TextStyle(color: Colors.redAccent)),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _resolveFeedback(item['id'], reject: false),
                    icon: const Icon(Icons.check, color: Colors.greenAccent, size: 18),
                    label: const Text('تحديد كمقروء/محلول', style: TextStyle(color: Colors.greenAccent)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
