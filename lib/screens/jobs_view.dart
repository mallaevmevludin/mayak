import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/job_service.dart';
import '../theme/app_theme.dart';
import '../widgets/job_card.dart';
import '../widgets/skeleton_item.dart';
import '../models/job_model.dart';
import 'job_detail_screen.dart';
import 'create_job_screen.dart';

class JobsView extends StatefulWidget {
  const JobsView({super.key});

  @override
  State<JobsView> createState() => _JobsViewState();
}

class _JobsViewState extends State<JobsView> {
  String _selectedCategory = 'all';
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JobService>(context, listen: false).fetchJobs(category: _selectedCategory);
    });
  }

  void _onScroll() {
    if (!mounted) return;
    final offset = _scrollController.offset;
    final newOpacity = (offset / 60.0).clamp(0.0, 1.0);
    if (newOpacity != _appBarOpacity) {
      setState(() {
        _appBarOpacity = newOpacity;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Provider.of<JobService>(context, listen: false).fetchJobs(category: _selectedCategory);
  }

  void _onCategorySelected(String categoryKey) {
    if (_selectedCategory == categoryKey) return;
    setState(() {
      _selectedCategory = categoryKey;
    });
    Provider.of<JobService>(context, listen: false).fetchJobs(category: categoryKey);
  }

  void _showCreateJobSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateJobScreen(),
    );
  }

  Widget _buildSkeletonGrid(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonItem(width: 80, height: 16, borderRadius: 6),
                  SizedBox(height: 12),
                  SkeletonItem(width: double.infinity, height: 16, borderRadius: 4),
                  SizedBox(height: 6),
                  SkeletonItem(width: 120, height: 16, borderRadius: 4),
                  SizedBox(height: 12),
                  SkeletonItem(width: double.infinity, height: 28, borderRadius: 8),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      SkeletonItem(width: 16, height: 16, borderRadius: 8),
                      SizedBox(width: 8),
                      SkeletonItem(width: 60, height: 12, borderRadius: 4),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: SkeletonItem(width: double.infinity, height: 28, borderRadius: 6)),
                      SizedBox(width: 8),
                      Expanded(child: SkeletonItem(width: double.infinity, height: 28, borderRadius: 6)),
                    ],
                  ),
                ],
              ),
            );
          },
          childCount: 3,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  size: 36,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Нет активных заказов',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCategory == 'all'
                    ? 'Будьте первым, кто создаст заказ на фриланс-витрине!'
                    : 'В этой категории пока нет заказов. Попробуйте выбрать другую или создайте свой!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showCreateJobSheet,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Разместить заказ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final jobService = Provider.of<JobService>(context);

    // List of categories for chips
    final filterCategories = [
      {'key': 'all', 'emoji': '🌐', 'name': 'Все'},
      ...JobModel.categories.entries.map((e) => {
            'key': e.key,
            'emoji': e.value['emoji']!,
            'name': e.value['name']!,
          }),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primary,
        displacement: 60,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── iOS-style Large Title AppBar ──
            SliverAppBar(
              expandedHeight: 100,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 10),
                title: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.25 : 0.04,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Работа',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: _showCreateJobSheet,
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.25 : 0.04,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),

            // ── Category Filter Chips ──
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filterCategories.length,
                  itemBuilder: (context, index) {
                    final item = filterCategories[index];
                    final isSelected = _selectedCategory == item['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => _onCategorySelected(item['key']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.12)
                                : (isDark ? AppTheme.darkSurface : const Color(0xFFF2F2F7)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary.withValues(alpha: 0.4)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(item['emoji']!, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                item['name']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : (isDark ? Colors.white : Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Main Listings Content ──
            if (jobService.isLoading && jobService.jobs.isEmpty)
              _buildSkeletonGrid(isDark)
            else if (jobService.jobs.isEmpty)
              _buildEmptyState(isDark)
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final job = jobService.jobs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: JobCard(
                          job: job,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JobDetailScreen(job: job),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: jobService.jobs.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
