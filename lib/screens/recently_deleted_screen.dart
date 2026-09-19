import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/tab_provider.dart';

class RecentlyDeletedScreen extends StatelessWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TabProvider>(context);
    final trashItems = provider.trash;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort trash items by deletedAt desc (newest deleted first)
    final sortedTrash = List<DeletedItem>.from(trashItems)
      ..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Recently Deleted',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (sortedTrash.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () => _confirmEmptyTrash(context, provider),
                icon: const Icon(Icons.delete_forever_outlined, size: 18, color: Color(0xFFB91C1C)),
                label: const Text(
                  'Empty Trash',
                  style: TextStyle(
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: sortedTrash.isEmpty
          ? _buildEmptyState(context, isDark)
          : Column(
              children: [
                _buildInfoBanner(isDark),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: sortedTrash.length,
                    itemBuilder: (context, index) {
                      final item = sortedTrash[index];
                      return _buildTrashItemCard(context, provider, item, isDark);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoBanner(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Items are stored here until you restore them or delete them permanently.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 72,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Trash is Empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Deleted accounts and transactions will show up here so you can restore them if needed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashItemCard(BuildContext context, TabProvider provider, DeletedItem item, bool isDark) {
    final dateStr = DateFormat('MMM dd, yyyy hh:mm a').format(item.deletedAt);
    final isPerson = item.type == 'person';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Leading Icon representation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPerson
                    ? const Color(0xFF9CAF88).withOpacity(0.12)
                    : Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPerson ? Icons.person_outline : Icons.receipt_long_outlined,
                color: isPerson ? const Color(0xFF9CAF88) : Colors.amber[800],
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Middle text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPerson
                        ? 'Deleted account • $dateStr'
                        : 'From ${item.parentPersonName ?? "Unknown"} • $dateStr',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions (Restore / Delete Forever)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Restore button
                IconButton(
                  tooltip: 'Restore',
                  icon: const Icon(Icons.settings_backup_restore, color: Color(0xFF9CAF88)),
                  onPressed: () {
                    provider.restoreItem(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Restored "${item.displayName}" successfully!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
                // Delete permanently button
                IconButton(
                  tooltip: 'Delete Permanently',
                  icon: const Icon(Icons.delete_forever, color: Color(0xFFB91C1C)),
                  onPressed: () => _confirmDeletePermanently(context, provider, item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePermanently(BuildContext context, TabProvider provider, DeletedItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Permanently?'),
          content: Text(
            'Are you sure you want to permanently delete "${item.displayName}"? This action is absolute and cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                provider.permanentlyDeleteItem(item.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Item permanently deleted.'),
                    backgroundColor: const Color(0xFFB91C1C),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _confirmEmptyTrash(BuildContext context, TabProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Empty Trash?'),
          content: const Text(
            'This will permanently delete all items in the trash folder. This action is absolute and cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                provider.clearTrash();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Trash cleared successfully.'),
                    backgroundColor: const Color(0xFFB91C1C),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Empty All'),
            ),
          ],
        );
      },
    );
  }
}
