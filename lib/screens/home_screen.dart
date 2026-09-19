import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/tab_provider.dart';
import '../models/models.dart';
import 'person_detail_screen.dart';
import 'recently_deleted_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
  int _selectedFilterIndex = 0; // 0: All, 1: They owe me, 2: I owe, 3: Settled
  bool _isSelectionMode = false;
  final Set<String> _selectedTabIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<TabProvider>(
        context,
        listen: false,
      ).setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Show a modern minimalist dialog to add a new person's tab
  void _showAddPersonDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Spacer(),
                        Text(
                          'Add New Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        labelText: "Account Name",
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF82C8E5),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an account name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        labelText: "Description (Optional)",
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF82C8E5),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Provider.of<TabProvider>(
                            context,
                            listen: false,
                          ).addPerson(
                            nameController.text,
                            description: descriptionController.text,
                          );
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF9CAF88,
                        ), // Sage green #9caf88
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditPersonDialog(PersonTab person) {
    final nameController = TextEditingController(text: person.name);
    final descriptionController = TextEditingController(
      text: person.description,
    );
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Spacer(),
                        Text(
                          'Edit Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        labelText: "Account Name",
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF82C8E5),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        labelText: "Description (Optional)",
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF82C8E5),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Provider.of<TabProvider>(
                            context,
                            listen: false,
                          ).editPerson(
                            person.id,
                            nameController.text,
                            descriptionController.text,
                          );
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF82C8E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDeletePerson(PersonTab tab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete ${tab.name}?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will move the account and all its transactions to Recently Deleted, where you can restore it or delete it permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () {
              final provider = Provider.of<TabProvider>(context, listen: false);
              provider.deletePerson(tab.id);
              Navigator.pop(context); // Close dialog

              // Show SnackBar with Undo
              if (provider.trash.isNotEmpty) {
                final recentlyDeleted = provider.trash.last;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Moved "${tab.name}" to Recently Deleted.'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: const Color(0xFF9CAF88),
                      onPressed: () {
                        provider.restoreItem(recentlyDeleted);
                      },
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Delete Account',
              style: TextStyle(
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMultiple(List<String> ids) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete ${ids.length} selected accounts?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will move these ${ids.length} accounts and their transactions to Recently Deleted, where you can restore them or delete them permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () {
              final provider = Provider.of<TabProvider>(context, listen: false);
              provider.deleteMultiplePersons(ids);
              setState(() {
                _isSelectionMode = false;
                _selectedTabIds.clear();
              });
              Navigator.pop(context); // Close dialog

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Moved ${ids.length} accounts to Recently Deleted.',
                  ),
                  action: SnackBarAction(
                    label: 'View Trash',
                    textColor: const Color(0xFF9CAF88),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RecentlyDeletedScreen(),
                        ),
                      );
                    },
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text(
              'Delete Selected',
              style: TextStyle(
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete ALL accounts?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will move all accounts and transaction histories to Recently Deleted, where they can be restored or permanently cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () {
              final provider = Provider.of<TabProvider>(context, listen: false);
              final deletedCount = provider.tabs.length;
              provider.deleteAllPersons();
              setState(() {
                _isSelectionMode = false;
                _selectedTabIds.clear();
              });
              Navigator.pop(context); // Close dialog

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Moved $deletedCount accounts to Recently Deleted.',
                  ),
                  action: SnackBarAction(
                    label: 'View Trash',
                    textColor: const Color(0xFF9CAF88),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RecentlyDeletedScreen(),
                        ),
                      );
                    },
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text(
              'Delete Everything',
              style: TextStyle(
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show a sort selection Dialog
  void _showSortDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Consumer<TabProvider>(
                builder: (context, provider, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Spacer(),
                          Text(
                            'Sort Accounts By',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSortOption(
                        context,
                        title: 'Last Active',
                        icon: Icons.access_time,
                        isSelected: provider.sortType == SortType.lastActive,
                        onTap: () {
                          provider.setSortType(SortType.lastActive);
                          Navigator.pop(context);
                        },
                      ),
                      _buildSortOption(
                        context,
                        title: 'Name (A-Z)',
                        icon: Icons.sort_by_alpha,
                        isSelected: provider.sortType == SortType.alphabetical,
                        onTap: () {
                          provider.setSortType(SortType.alphabetical);
                          Navigator.pop(context);
                        },
                      ),
                      _buildSortOption(
                        context,
                        title: 'Highest Balance (outstanding balance)',
                        icon: Icons.trending_up,
                        isSelected:
                            provider.sortType == SortType.highestBalance,
                        onTap: () {
                          provider.setSortType(SortType.highestBalance);
                          Navigator.pop(context);
                        },
                      ),
                      _buildSortOption(
                        context,
                        title: 'Lowest Balance (overpayment)',
                        icon: Icons.trending_down,
                        isSelected: provider.sortType == SortType.lowestBalance,
                        onTap: () {
                          provider.setSortType(SortType.lowestBalance);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF9CAF88);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? primaryColor
            : (isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? primaryColor
              : (isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: primaryColor)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: Consumer<TabProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF9CAF88)),
            );
          }

          // Net balance sums
          final totalOwed = provider.totalOwedToMe;
          final totalIOwe = provider.totalIOweThem;
          final netTotal = provider.netTotalBalance;

          // Apply local selected index filters on top of provider's searched/sorted list
          final allFilteredTabs = provider.filteredTabs;
          List<PersonTab> displayedTabs = [];
          if (_selectedFilterIndex == 0) {
            displayedTabs = allFilteredTabs;
          } else if (_selectedFilterIndex == 1) {
            displayedTabs = allFilteredTabs
                .where((tab) => tab.netBalance > 0.01)
                .toList();
          } else if (_selectedFilterIndex == 2) {
            displayedTabs = allFilteredTabs
                .where((tab) => tab.netBalance < -0.01)
                .toList();
          } else if (_selectedFilterIndex == 3) {
            displayedTabs = allFilteredTabs
                .where((tab) => tab.netBalance.abs() <= 0.01)
                .toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Beautiful Deep Green Header Summary block
              Container(
                color: const Color(0xFF9CAF88),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  bottom: 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand / Title row
                    _isSelectionMode
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isSelectionMode = false;
                                        _selectedTabIds.clear();
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${_selectedTabIds.length} Selected',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        final allIds = displayedTabs
                                            .map((t) => t.id)
                                            .toList();
                                        if (_selectedTabIds.length ==
                                            displayedTabs.length) {
                                          _selectedTabIds.clear();
                                        } else {
                                          _selectedTabIds.addAll(allIds);
                                        }
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      _selectedTabIds.length ==
                                              displayedTabs.length
                                          ? 'Deselect All'
                                          : 'Select All',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: _selectedTabIds.isEmpty
                                          ? Colors.white.withOpacity(0.4)
                                          : const Color(0xFFEF4444),
                                      size: 22,
                                    ),
                                    onPressed: _selectedTabIds.isEmpty
                                        ? null
                                        : () {
                                            _confirmDeleteMultiple(
                                              _selectedTabIds.toList(),
                                            );
                                          },
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'TABKEEPER',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) {
                                  if (value == 'select_delete') {
                                    setState(() {
                                      _isSelectionMode = true;
                                      _selectedTabIds.clear();
                                    });
                                  } else if (value == 'recently_deleted') {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RecentlyDeletedScreen(),
                                      ),
                                    );
                                  } else if (value == 'delete_all') {
                                    _confirmDeleteAll();
                                  } else if (value == 'logout') {
                                    final authService =
                                        Provider.of<AuthService>(
                                          context,
                                          listen: false,
                                        );
                                    authService.signOut();
                                  }
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
                                      PopupMenuItem<String>(
                                        value: 'logout',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.logout,
                                              size: 18,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Logout',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      PopupMenuItem<String>(
                                        value: 'select_delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.checklist_outlined,
                                              size: 18,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Select',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'recently_deleted',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline_outlined,
                                              size: 18,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Recently Deleted',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete_all',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.delete_sweep_outlined,
                                              size: 18,
                                              color: Color(0xFFB91C1C),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Delete all tabs',
                                              style: TextStyle(
                                                color: Color(0xFFB91C1C),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 24),
                    // Horizontal dashboard container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF7D9369,
                        ), // Matching deeper shade for summary card
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NET BALANCE',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            netTotal == 0
                                ? '₱0.00'
                                : (netTotal >= 0
                                      ? _currencyFormat.format(netTotal)
                                      : '-${_currencyFormat.format(netTotal.abs())}'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            color: Colors.white.withOpacity(0.15),
                            height: 1,
                            thickness: 1,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'OUTSTANDING BALANCE',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currencyFormat.format(totalOwed),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'OVERPAYMENT',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currencyFormat.format(totalIOwe),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Outlined search and filter capsule block
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Search bar row with sort button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF1F5F9).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                textAlignVertical: TextAlignVertical.center,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search names or notes...',
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[500],
                                    size: 18,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 16,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            FocusScope.of(context).unfocus();
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Sort trigger button
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.sort_outlined,
                                color: isDark
                                    ? Colors.grey[300]
                                    : const Color(0xFF0F172A),
                                size: 18,
                              ),
                              onPressed: _showSortDialog,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Filter chips scrollable list
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFilterChip(0, 'All'),
                            const SizedBox(width: 8),
                            _buildFilterChip(1, 'Outstanding balance'),
                            const SizedBox(width: 8),
                            _buildFilterChip(2, 'Overpayment'),
                            const SizedBox(width: 8),
                            _buildFilterChip(3, 'Settled'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Person cards list
              Expanded(
                child: displayedTabs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.contacts_outlined,
                              size: 64,
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No matches found'
                                  : 'No accounts yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Try checking spelling or filters'
                                  : 'Tap "+" to start tracking',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 90,
                          top: 4,
                        ),
                        itemCount: displayedTabs.length,
                        itemBuilder: (context, index) {
                          final personTab = displayedTabs[index];
                          final balance = personTab.netBalance;
                          final isCardOwed = balance >= 0;

                          // Generate initials for avatar
                          final trimmedName = personTab.name.trim();
                          final words = trimmedName.isEmpty
                              ? <String>[]
                              : trimmedName.split(RegExp(r'\s+'));
                          final initials = words.isEmpty
                              ? '?'
                              : (words.length > 1 &&
                                        words[0].isNotEmpty &&
                                        words[1].isNotEmpty
                                    ? '${words[0][0]}${words[1][0]}'
                                          .toUpperCase()
                                    : (words[0].isNotEmpty
                                          ? words[0][0].toUpperCase()
                                          : '?'));

                          // Get active transactions info
                          final activeList = personTab.transactions
                              .where((t) => !t.isPaid)
                              .toList();
                          final activeCount = activeList.length;
                          String subtitleText = '0 entries';
                          if (activeCount > 0) {
                            final lastTx = activeList.first;
                            final detailString = lastTx.description.isEmpty
                                ? lastTx.methodOfUtang
                                : lastTx.description;
                            final entryLabel = activeCount == 1
                                ? 'entry'
                                : 'entries';
                            subtitleText =
                                '$activeCount $entryLabel • $detailString';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                if (_isSelectionMode) {
                                  setState(() {
                                    if (_selectedTabIds.contains(
                                      personTab.id,
                                    )) {
                                      _selectedTabIds.remove(personTab.id);
                                    } else {
                                      _selectedTabIds.add(personTab.id);
                                    }
                                  });
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PersonDetailScreen(
                                        personTabId: personTab.id,
                                      ),
                                    ),
                                  );
                                }
                              },
                              onLongPress: () {
                                if (!_isSelectionMode) {
                                  setState(() {
                                    _isSelectionMode = true;
                                    _selectedTabIds.add(personTab.id);
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Top User Row
                                    Row(
                                      children: [
                                        if (_isSelectionMode) ...[
                                          Icon(
                                            _selectedTabIds.contains(
                                                  personTab.id,
                                                )
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color:
                                                _selectedTabIds.contains(
                                                  personTab.id,
                                                )
                                                ? const Color(0xFF9CAF88)
                                                : (isDark
                                                      ? Colors.grey[500]
                                                      : Colors.grey[400]),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        // Initials CircleAvatar (light green bg / dark green text)
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isDark
                                              ? const Color(
                                                  0xFF9CAF88,
                                                ).withOpacity(0.2)
                                              : const Color(0xFFF0F4EC),
                                          child: Text(
                                            initials,
                                            style: const TextStyle(
                                              color: Color(0xFF9CAF88),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Name and Entry details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                personTab.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              if (personTab
                                                  .description
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  personTab.description,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark
                                                        ? Colors.grey[300]
                                                        : Colors.grey[700],
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                              const SizedBox(height: 2),
                                              Text(
                                                subtitleText,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : Colors.grey[500],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!_isSelectionMode)
                                          PopupMenuButton<String>(
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: isDark
                                                  ? Colors.grey[600]
                                                  : Colors.grey[400],
                                              size: 20,
                                            ),
                                            padding: EdgeInsets.zero,
                                            color: isDark
                                                ? const Color(0xFF1E293B)
                                                : Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _showEditPersonDialog(
                                                  personTab,
                                                );
                                              } else if (value == 'delete') {
                                                _confirmDeletePerson(personTab);
                                              }
                                            },
                                            itemBuilder:
                                                (
                                                  BuildContext context,
                                                ) => <PopupMenuEntry<String>>[
                                                  PopupMenuItem<String>(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.edit_outlined,
                                                          size: 18,
                                                          color: isDark
                                                              ? Colors.white70
                                                              : Colors.black54,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          'Edit tab',
                                                          style: TextStyle(
                                                            color: isDark
                                                                ? Colors.white
                                                                : const Color(
                                                                    0xFF0F172A,
                                                                  ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem<String>(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.delete_outline,
                                                          size: 18,
                                                          color: Color(
                                                            0xFFB91C1C,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const Text(
                                                          'Delete tab',
                                                          style: TextStyle(
                                                            color: Color(
                                                              0xFFB91C1C,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                          ),
                                      ],
                                    ),
                                    const Divider(height: 24, thickness: 0.5),
                                    // Bottom Net Balance Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'NET BALANCE',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                                color: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[500],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              balance == 0
                                                  ? 'Settled'
                                                  : (isCardOwed
                                                        ? _currencyFormat
                                                              .format(
                                                                balance.abs(),
                                                              )
                                                        : '-${_currencyFormat.format(balance.abs())}'),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: balance == 0
                                                    ? Colors.grey[400]
                                                    : (isCardOwed
                                                          ? const Color(
                                                              0xFF9CAF88,
                                                            )
                                                          : const Color(
                                                              0xFFB91C1C,
                                                            )),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Stacked totals on the right side
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '+${_currencyFormat.format(personTab.totalOwedToMe)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF9CAF88),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '-${_currencyFormat.format(personTab.totalIOweThem)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFB91C1C),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: _showAddPersonDialog,
              backgroundColor: const Color(0xFF9CAF88),
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              elevation: 4,
              child: const Icon(Icons.add, size: 28),
            ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF9CAF88) // Signature theme color
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[300] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}
