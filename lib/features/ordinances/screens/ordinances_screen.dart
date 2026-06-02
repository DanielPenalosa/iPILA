import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ordinance_model.dart';
import '../../../data/services/ordinance_service.dart';
import '../../home/widgets/mobile_shell.dart';
import 'package:intl/intl.dart';

class OrdinancesScreen extends StatefulWidget {
  const OrdinancesScreen({super.key});

  @override
  State<OrdinancesScreen> createState() => _OrdinancesScreenState();
}

class _OrdinancesScreenState extends State<OrdinancesScreen>
    with SingleTickerProviderStateMixin {
  final OrdinanceService _service = OrdinanceService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Ordinances & FAQs',
      currentIndex: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primaryBlue,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Ordinances'),
                Tab(text: 'FAQs'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OrdinancesTab(service: _service),
                _FaqsTab(service: _service),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdinancesTab extends StatefulWidget {
  final OrdinanceService service;

  const _OrdinancesTab({required this.service});

  @override
  State<_OrdinancesTab> createState() => _OrdinancesTabState();
}

class _OrdinancesTabState extends State<_OrdinancesTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search ordinances...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    ...OrdinanceModel.categories.map(
                      (c) => _CategoryChip(
                        label: c,
                        selected: _selectedCategory == c,
                        onTap: () => setState(() => _selectedCategory = c),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<OrdinanceModel>>(
            stream: widget.service.getOrdinances(
              category: _selectedCategory,
              searchQuery: _searchQuery,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final ordinances = snapshot.data ?? [];
              if (ordinances.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.gavel_rounded,
                        size: 56,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No ordinances found.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ordinances.length,
                itemBuilder: (_, i) => _OrdinanceCard(
                  ordinance: ordinances[i],
                  onTap: () => context.push('/ordinance/${ordinances[i].id}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrdinanceCard extends StatelessWidget {
  final OrdinanceModel ordinance;
  final VoidCallback onTap;

  const _OrdinanceCard({required this.ordinance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.gavel_rounded,
            color: AppTheme.primaryBlue,
            size: 22,
          ),
        ),
        title: Text(
          ordinance.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ordinance No. ${ordinance.number}',
              style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue),
            ),
            Text(
              'Enacted: ${DateFormat('MMM d, yyyy').format(ordinance.dateEnacted)}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            ordinance.category.split(' ').first,
            style: const TextStyle(fontSize: 10, color: AppTheme.primaryBlue),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _FaqsTab extends StatelessWidget {
  final OrdinanceService service;

  const _FaqsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getFaqs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final faqs = snapshot.data ?? [];
        if (faqs.isEmpty) {
          return const Center(child: Text('No FAQs available yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: faqs.length,
          itemBuilder: (_, i) {
            final faq = faqs[i];
            return Card(
              child: ExpansionTile(
                leading: const Icon(
                  Icons.help_outline_rounded,
                  color: AppTheme.primaryBlue,
                ),
                title: Text(
                  faq['question'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      faq['answer'] ?? '',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
        checkmarkColor: AppTheme.primaryBlue,
      ),
    );
  }
}
