import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/job_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_header.dart';
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

  // Filter state fields
  String? _locationType;
  String? _city;
  String? _district;
  String? _workType;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JobService>(context, listen: false).fetchJobs(
        category: _selectedCategory,
        isRefresh: true,
        locationType: _locationType,
        city: _city,
        district: _district,
        workType: _workType,
      );
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

    // Trigger pagination when reaching within 200 pixels of the bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final jobService = Provider.of<JobService>(context, listen: false);
      if (!jobService.isLoading &&
          !jobService.isLoadingMore &&
          jobService.hasMore) {
        jobService.fetchJobs(
          category: _selectedCategory,
          isRefresh: false,
          locationType: _locationType,
          city: _city,
          district: _district,
          workType: _workType,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Provider.of<JobService>(context, listen: false).fetchJobs(
      category: _selectedCategory,
      isRefresh: true,
      locationType: _locationType,
      city: _city,
      district: _district,
      workType: _workType,
    );
  }

  void _onCategorySelected(String categoryKey) {
    if (_selectedCategory == categoryKey) return;
    setState(() {
      _selectedCategory = categoryKey;
    });
    Provider.of<JobService>(context, listen: false).fetchJobs(
      category: categoryKey,
      isRefresh: true,
      locationType: _locationType,
      city: _city,
      district: _district,
      workType: _workType,
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Фильтры вакансий',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_locationType != null || _workType != null)
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              _locationType = null;
                              _city = null;
                              _district = null;
                              _workType = null;
                            });
                          },
                          child: const Text('Сбросить', style: TextStyle(color: AppTheme.error)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location Type Selector
                  const Text('Тип локации', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Все'),
                          selected: _locationType == null,
                          onSelected: (val) {
                            if (val) {
                              setSheetState(() {
                                _locationType = null;
                                _city = null;
                                _district = null;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Город'),
                          selected: _locationType == 'city',
                          onSelected: (val) {
                            if (val) {
                              setSheetState(() {
                                _locationType = 'city';
                                _district = null;
                                _city = 'Махачкала';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Район'),
                          selected: _locationType == 'district',
                          onSelected: (val) {
                            if (val) {
                              setSheetState(() {
                                _locationType = 'district';
                                _city = null;
                                _district = 'Гунибский район';
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contextual dropdown based on location type
                  if (_locationType == 'city') ...[
                    const Text('Выберите город', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _city,
                      items: ['Махачкала', 'Каспийск', 'Дербент', 'Хасавюрт', 'Буйнакск', 'Кизляр', 'Избербаш']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          _city = val;
                        });
                      },
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    ),
                    const SizedBox(height: 16),
                  ] else if (_locationType == 'district') ...[
                    const Text('Выберите район', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _district,
                      items: JobModel.locationsOfDagestan
                          .where((loc) => loc.contains('район'))
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          _district = val;
                        });
                      },
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Work Type Selector
                  const Text('Занятость', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: _workType,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все типы занятости')),
                      ...WorkType.values.map((wt) => DropdownMenuItem(value: wt.toDbString(), child: Text(wt.displayName))),
                    ],
                    onChanged: (val) {
                      setSheetState(() {
                        _workType = val;
                      });
                    },
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  ),
                  const SizedBox(height: 24),

                  // Apply button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Provider.of<JobService>(context, listen: false).fetchJobs(
                        category: _selectedCategory,
                        isRefresh: true,
                        locationType: _locationType,
                        city: _city,
                        district: _district,
                        workType: _workType,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Применить фильтры', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
                  color: isDark ? AppTheme.cardBorderDark : AppTheme.cardBorderLight,
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
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
      child: AppEmptyState(
        icon: Icons.work_outline_rounded,
        title: 'Нет активных заказов',
        subtitle: _selectedCategory == 'all'
            ? 'Будьте первым, кто создаст заказ на фриланс-витрине!'
            : 'В этой категории пока нет заказов. Попробуйте выбрать другую или создайте свой!',
        actionLabel: 'Разместить заказ',
        onAction: _showCreateJobSheet,
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
                titlePadding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  bottom: AppSpacing.md,
                ),
                title: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: AppRadius.controlR,
                    boxShadow: AppShadows.soft(isDark),
                  ),
                  child: Text(
                    'Работа',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.appTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              actions: [
                AppHeaderAction(
                  icon: Icons.filter_list_rounded,
                  onTap: _showFilterSheet,
                  iconColor: (_locationType != null || _workType != null)
                      ? AppTheme.primary
                      : context.appTextSecondary,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: AppHeaderAction(
                    icon: Icons.add_rounded,
                    onTap: _showCreateJobSheet,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: AppAlpha.fillMuted)
                                : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
                            borderRadius: AppRadius.chipR,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary.withValues(alpha: AppAlpha.fillStrong)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(item['emoji']!, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                item['name']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : context.appTextPrimary,
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

            // Bottom loading spinner or spacing for pagination to clear floating nav bar
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  top: jobService.isLoadingMore ? AppSpacing.sm : 0.0,
                  bottom: AppSpacing.bottomNavClearance,
                ),
                child: jobService.isLoadingMore
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
