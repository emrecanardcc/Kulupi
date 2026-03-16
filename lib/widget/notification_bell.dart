import 'package:flutter/material.dart';
import 'package:kulupi/services/notification_service.dart';
import 'package:kulupi/utils/glass_components.dart';
import 'package:intl/intl.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final NotificationService _notificationService = NotificationService();
  late Stream<List<Map<String, dynamic>>> _notificationsStream;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _notificationsStream = _notificationService.getNotificationsStream();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await _notificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color iconColor = isDark ? Colors.white : const Color(0xFF1F2937);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _notificationsStream,
      initialData: const [],
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final notifications = snapshot.data!;
          final unreadNotifications = notifications.where((n) => !n['is_read']).toList();
          
          if (_unreadCount != unreadNotifications.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _unreadCount = unreadNotifications.length;
                });
              }
            });
          }
        }

        return GestureDetector(
          onTap: () => _showNotificationsDialog(),
          child: Stack(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: iconColor,
                size: 28,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.white : Colors.white, width: 1),
                    ),
                    child: Text(
                      _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: AuraGlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Bildirimler",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _notificationsStream,
                initialData: const [],
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notifications = snapshot.data!;
                  
                  if (notifications.isEmpty) {
                    return const Center(
                      child: Text(
                        "Henüz bildirim yok",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 400,
                    child: ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
                  );
                },
              ),
              
              if (_unreadCount > 0) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      await _notificationService.markAllAsRead();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AuraTheme.kAccentCyan,
                    ),
                    child: const Text("Tümünü Okundu İşaretle", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final createdAt = DateTime.tryParse(notification['created_at'] ?? '');
    final formattedDate = createdAt != null 
        ? DateFormat('d MMM HH:mm', 'tr_TR').format(createdAt)
        : '';

    return InkWell(
      onTap: () async {
        if (!isRead) {
          await _notificationService.markAsRead(notification['id']);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead 
              ? Colors.white.withValues(alpha: 0.05) 
              : AuraTheme.kAccentCyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead 
                ? Colors.white.withValues(alpha: 0.1) 
                : AuraTheme.kAccentCyan.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İkon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getNotificationColor(notification['type']),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(notification['type']),
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            
            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['title'] ?? 'Bildirim',
                    style: TextStyle(
                      color: isRead ? Colors.white70 : Colors.white,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            
            // Okundu durumu göstergesi
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.cyanAccent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'event':
        return Colors.blue;
      case 'club':
        return Colors.green;
      case 'system':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'club':
        return Icons.group;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
}
