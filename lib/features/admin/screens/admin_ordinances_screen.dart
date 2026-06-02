import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/ordinance_model.dart';
import '../../../data/services/ordinance_service.dart';
import 'admin_shell.dart';

class AdminOrdinancesScreen extends StatefulWidget {
  const AdminOrdinancesScreen({super.key});

  @override
  State<AdminOrdinancesScreen> createState() => _AdminOrdinancesScreenState();
}

class _AdminOrdinancesScreenState extends State<AdminOrdinancesScreen> {
  final OrdinanceService _service = OrdinanceService();
  String _search = '';

  void _showOrdinanceDialog({OrdinanceModel? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final numberCtrl = TextEditingController(text: existing?.number ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String? selectedCategory =
        existing?.category ?? OrdinanceModel.categories.first;
    DateTime selectedDate = existing?.dateEnacted ?? DateTime.now();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Add Ordinance' : 'Edit Ordinance'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: numberCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ordinance Number (e.g. 2024-01)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: OrdinanceModel.categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setS(() => selectedCategory = v),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Date Enacted',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      DateFormat('MMM d, yyyy').format(selectedDate),
                    ),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setS(() => selectedDate = picked);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            AdminHoverButton(
              label: 'Cancel',
              onTap: () => Navigator.pop(ctx),
              outlined: true,
              small: true,
            ),
            const SizedBox(width: 8),
            AdminHoverButton(
              label: existing == null ? 'Add' : 'Save',
              onTap: () async {
                if (titleCtrl.text.trim().isEmpty ||
                    numberCtrl.text.trim().isEmpty)
                  return;
                Navigator.pop(ctx);
                if (existing == null) {
                  final ord = OrdinanceModel(
                    id: const Uuid().v4(),
                    title: titleCtrl.text.trim(),
                    number: numberCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    content: descCtrl.text.trim(),
                    category: selectedCategory!,
                    dateEnacted: selectedDate,
                    createdAt: DateTime.now(),
                    tags: [],
                    isActive: true,
                  );
                  await _service.addOrdinance(ord);
                } else {
                  await _service.updateOrdinance(existing.id, {
                    'title': titleCtrl.text.trim(),
                    'number': numberCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'category': selectedCategory,
                    'dateEnacted': selectedDate.toIso8601String(),
                  });
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        existing == null
                            ? 'Ordinance added'
                            : 'Ordinance updated',
                      ),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                }
              },
              color: AppTheme.primaryBlue,
              small: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _archive(OrdinanceModel ord) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archive Ordinance'),
        content: Text(
          'Archive "${ord.title}"? It will be hidden from residents.',
        ),
        actions: [
          AdminHoverButton(
            label: 'Cancel',
            onTap: () => Navigator.pop(context, false),
            outlined: true,
            small: true,
          ),
          const SizedBox(width: 8),
          AdminHoverButton(
            label: 'Archive',
            onTap: () => Navigator.pop(context, true),
            color: AppTheme.primaryRed,
            small: true,
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.updateOrdinance(ord.id, {'isActive': false});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ordinance archived'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: '/admin/ordinances',
      child: Column(
        children: [
          const AdminPageHeader(
            title: 'Ordinances',
            subtitle: 'Municipality of Pila, Laguna',
          ),
          Expanded(
            child: StreamBuilder<List<OrdinanceModel>>(
              stream: _service.getOrdinances(
                searchQuery: _search,
                activeOnly: false,
              ),
              builder: (context, snapshot) {
                final ordinances = snapshot.data ?? [];
                return Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 260,
                            height: 36,
                            child: TextField(
                              onChanged: (v) => setState(() => _search = v),
                              decoration: InputDecoration(
                                hintText: 'Search ordinances...',
                                hintStyle: const TextStyle(fontSize: 12),
                                prefixIcon: const Icon(Icons.search, size: 16),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          AdminHoverButton(
                            label: '+ Add Ordinance',
                            icon: Icons.add,
                            onTap: () => _showOrdinanceDialog(),
                            color: AppTheme.primaryBlue,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text('NUMBER', style: _hStyle),
                          ),
                          Expanded(child: Text('TITLE', style: _hStyle)),
                          SizedBox(
                            width: 130,
                            child: Text('CATEGORY', style: _hStyle),
                          ),
                          SizedBox(
                            width: 130,
                            child: Text('DATE ENACTED', style: _hStyle),
                          ),
                          SizedBox(
                            width: 110,
                            child: Text('STATUS', style: _hStyle),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text('ACTIONS', style: _hStyle),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: snapshot.connectionState == ConnectionState.waiting
                          ? const Center(child: CircularProgressIndicator())
                          : ordinances.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.gavel_rounded,
                                    size: 48,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No ordinances yet. Add one above.',
                                    style: TextStyle(color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: ordinances.length,
                              separatorBuilder: (_, _x) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) => _OrdinanceRow(
                                ordinance: ordinances[i],
                                onEdit: () => _showOrdinanceDialog(
                                  existing: ordinances[i],
                                ),
                                onArchive: () => _archive(ordinances[i]),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const _hStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: AppTheme.textMuted,
  letterSpacing: 0.5,
);

class _OrdinanceRow extends StatelessWidget {
  final OrdinanceModel ordinance;
  final VoidCallback onEdit, onArchive;
  const _OrdinanceRow({
    required this.ordinance,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, yyyy').format(ordinance.dateEnacted);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              'No. ${ordinance.number}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              ordinance.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            width: 130,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ordinance.category.split(' ').first,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              date,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
          SizedBox(
            width: 110,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Published',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.successGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              children: [
                AdminHoverButton(
                  label: 'Edit',
                  onTap: onEdit,
                  outlined: true,
                  small: true,
                ),
                const SizedBox(width: 6),
                AdminHoverButton(
                  label: 'Archive',
                  onTap: onArchive,
                  color: AppTheme.primaryRed,
                  small: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
