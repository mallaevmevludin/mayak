import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';
import '../services/image_upload_service.dart';
import '../services/supabase_config.dart';
import '../services/social_service.dart';
import '../theme/app_theme.dart';
import '../models/job_model.dart';
import '../widgets/custom_text_field.dart'; // To reuse RussianPhoneTextInputFormatter
import '../widgets/job_card.dart';

class CreateJobScreen extends StatefulWidget {
  final JobModel? jobToEdit;
  const CreateJobScreen({super.key, this.jobToEdit});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _budgetFromController = TextEditingController();
  final _budgetToController = TextEditingController();
  String _budgetType = 'agreement';
  final _phoneController = TextEditingController();
  final _telegramController = TextEditingController();
  final _settlementController = TextEditingController();

  String _selectedCategory = 'construction';
  bool _isSubmitting = false;
  int _uploadingCount = 0;
  final List<String> _existingImageUrls = [];
  
  String? _selectedLocation;
  String _selectedWorkType = 'one_time';
  bool _publishToSocialFeed = true;

  Future<void> _uploadFile(File file) async {
    setState(() {
      _uploadingCount++;
    });
    try {
      String imageUrl;
      if (!SupabaseConfig.isConfigured) {
        // Mock mode: simulate upload latency
        await Future.delayed(const Duration(seconds: 1));
        imageUrl = 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=800&q=80';
      } else {
        final optimizedResult = await ImageUploadService.optimizeImage(file);
        final uploadResult = await ImageUploadService.uploadPostImage(
          imageFile: optimizedResult['optimized']!,
          thumbnailFile: optimizedResult['thumbnail']!,
        );
        imageUrl = uploadResult['imageUrl']!;
      }
      setState(() {
        _existingImageUrls.add(imageUrl);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки фото: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingCount--;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final totalCount = _existingImageUrls.length + _uploadingCount;
    if (totalCount >= 5) return;

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Выберите источник',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primary,
                ),
                title: const Text('Галерея'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppTheme.primary,
                ),
                title: const Text('Камера'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    if (source == ImageSource.camera) {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (pickedFile != null) {
        _uploadFile(File(pickedFile.path));
      }
    } else {
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (pickedFiles.isNotEmpty) {
        final spaceLeft = 5 - totalCount;
        for (final file in pickedFiles.take(spaceLeft)) {
          _uploadFile(File(file.path));
        }
      }
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final modalBg = isDark ? AppTheme.darkSurface : Colors.white;
            final searchController = TextEditingController();
            List<String> filteredList = List.from(JobModel.locationsOfDagestan);

            void filter(String query) {
              final cleanQuery = query.trim().toLowerCase();
              setModalState(() {
                if (cleanQuery.isEmpty) {
                  filteredList = List.from(JobModel.locationsOfDagestan);
                } else {
                  filteredList = JobModel.locationsOfDagestan
                      .where((loc) => loc.toLowerCase().contains(cleanQuery))
                      .toList();
                }
              });
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: modalBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      Text(
                        'Выберите локацию',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: searchController,
                          onChanged: (val) {
                            filter(val);
                            setModalState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Поиск города или района...',
                            prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      searchController.clear();
                                      filter('');
                                      setModalState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            filled: true,
                            fillColor: isDark ? AppTheme.cardBorderDark : AppTheme.lightSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final location = filteredList[index];
                            final isSelected = _selectedLocation == location;
                            final isCity = !location.contains('район');

                            return ListTile(
                              leading: Icon(
                                isCity ? Icons.location_city_rounded : Icons.map_rounded,
                                color: isSelected ? AppTheme.primary : Colors.grey,
                                size: 20,
                              ),
                              title: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : (isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_rounded, color: AppTheme.primary, size: 20)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedLocation = location;
                                  if (isCity) {
                                    _settlementController.clear();
                                  }
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showPreview() {
    final isDistrict = _selectedLocation != null && _selectedLocation!.contains('район');
    final String locationType = isDistrict ? 'district' : 'city';
    final String? city = !isDistrict ? _selectedLocation : null;
    final String? district = isDistrict ? _selectedLocation!.replaceAll(' район', '') : null;
    final String? settlement = isDistrict ? _settlementController.text.trim() : null;

    final tempJob = JobModel(
      id: 0,
      userId: Provider.of<AuthService>(context, listen: false).currentUser?.id ?? '',
      userFirstName: Provider.of<AuthService>(context, listen: false).currentUser?.firstName ?? 'Пользователь',
      userLastName: Provider.of<AuthService>(context, listen: false).currentUser?.lastName ?? '',
      userUsername: Provider.of<AuthService>(context, listen: false).currentUser?.username ?? 'user',
      userEmojiAvatar: Provider.of<AuthService>(context, listen: false).currentUser?.emojiAvatar,
      userAvatarUrl: Provider.of<AuthService>(context, listen: false).currentUser?.avatarUrl,
      userIsVerified: Provider.of<AuthService>(context, listen: false).currentUser?.isVerified ?? false,
      title: _titleController.text.trim().isEmpty ? 'Заголовок объявления' : _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? 'Описание объявления' : _descriptionController.text.trim(),
      category: JobCategory.fromString(_selectedCategory),
      budget: _getSubmitBudget(),
      contactPhone: _phoneController.text.trim(),
      contactTelegram: _telegramController.text.trim(),
      status: JobStatus.active,
      createdAt: DateTime.now(),
      imageUrls: _existingImageUrls,
      locationType: LocationType.fromString(locationType),
      city: city,
      district: district,
      settlement: settlement,
      workType: WorkType.fromString(_selectedWorkType),
    );

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: JobCard(
                    job: tempJob,
                    onTap: () {},
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardBorderDark : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? Colors.white : Colors.black,
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

  @override
  void initState() {
    super.initState();
    if (widget.jobToEdit != null) {
      _titleController.text = widget.jobToEdit!.title;
      _descriptionController.text = widget.jobToEdit!.description;
      
      final b = widget.jobToEdit!.budget ?? '';
      final cleanB = b.trim();
      if (cleanB.isEmpty) {
        _budgetType = 'agreement';
      } else if (cleanB.contains('-') || cleanB.startsWith('от') || cleanB.startsWith('до')) {
        _budgetType = 'range';
        if (cleanB.contains('-')) {
          final parts = cleanB.split('-');
          if (parts.length == 2) {
            _budgetFromController.text = _formatThousands(parts[0]);
            _budgetToController.text = _formatThousands(parts[1]);
          }
        } else if (cleanB.startsWith('от')) {
          _budgetFromController.text = _formatThousands(cleanB);
        } else if (cleanB.startsWith('до')) {
          _budgetToController.text = _formatThousands(cleanB);
        }
      } else {
        _budgetType = 'fixed';
        _budgetController.text = _formatThousands(cleanB);
      }
      
      _phoneController.text = widget.jobToEdit!.contactPhone ?? '';
      _telegramController.text = widget.jobToEdit!.contactTelegram ?? '';
      _selectedCategory = widget.jobToEdit!.category.name;
      _existingImageUrls.addAll(widget.jobToEdit!.imageUrls);
      _selectedWorkType = widget.jobToEdit!.workType?.toDbString() ?? 'one_time';
      
      if (widget.jobToEdit!.locationType == LocationType.district) {
        _selectedLocation = widget.jobToEdit!.district != null && widget.jobToEdit!.district!.isNotEmpty
            ? '${widget.jobToEdit!.district} район'
            : null;
        _settlementController.text = widget.jobToEdit!.settlement ?? '';
      } else {
        _selectedLocation = widget.jobToEdit!.city;
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = Provider.of<AuthService>(
          context,
          listen: false,
        ).currentUser;
        if (user != null && user.phoneNumber.isNotEmpty) {
          final formatter = RussianPhoneTextInputFormatter();
          final formatted = formatter.formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(text: user.phoneNumber),
          );
          _phoneController.text = formatted.text;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _budgetFromController.dispose();
    _budgetToController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    _settlementController.dispose();
    super.dispose();
  }

  String _formatThousands(String text) {
    if (text.isEmpty) return '';
    final cleanText = text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      buffer.write(cleanText[i]);
      final reversedIndex = cleanText.length - 1 - i;
      if (reversedIndex % 3 == 0 && reversedIndex > 0) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  String _getSubmitBudget() {
    if (_budgetType == 'agreement') {
      return '';
    } else if (_budgetType == 'fixed') {
      return _budgetController.text.trim();
    } else {
      final from = _budgetFromController.text.trim();
      final to = _budgetToController.text.trim();
      if (from.isNotEmpty && to.isNotEmpty) {
        return '$from - $to ₽';
      } else if (from.isNotEmpty) {
        return 'от $from ₽';
      } else if (to.isNotEmpty) {
        return 'до $to ₽';
      } else {
        return '';
      }
    }
  }

  Widget _buildBudgetTab(String type, String label) {
    final isSelected = _budgetType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _budgetType = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.12)
                : (isDark ? AppTheme.cardBorderDark : AppTheme.lightSurface),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primary.withValues(alpha: 0.4) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.primary : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите локацию')),
      );
      return;
    }

    if (_uploadingCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, дождитесь окончания загрузки фотографий')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final finalImageUrls = _existingImageUrls;
    bool success = false;
    final jobService = Provider.of<JobService>(context, listen: false);
    final socialService = Provider.of<SocialService>(context, listen: false);

    final isDistrict = _selectedLocation!.contains('район');
    final String locationType = isDistrict ? 'district' : 'city';
    final String? city = !isDistrict ? _selectedLocation : null;
    final String? district = isDistrict ? _selectedLocation!.replaceAll(' район', '') : null;
    final String? settlement = isDistrict ? _settlementController.text.trim() : null;

    if (widget.jobToEdit == null) {
      final createdJob = await jobService.createJob(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        budget: _getSubmitBudget(),
        contactPhone: _phoneController.text,
        contactTelegram: _telegramController.text,
        imageUrls: finalImageUrls,
        locationType: locationType,
        city: city,
        district: district,
        settlement: settlement,
        workType: _selectedWorkType,
      );
      success = createdJob != null;
      if (success && _publishToSocialFeed) {
        try {
          await socialService.createPost(
            'Ищу исполнителя для заказа: "${_titleController.text}". Подробнее в деталях вакансии ниже 👇',
            jobId: createdJob.id,
          );
        } catch (e) {
          debugPrint('Failed to auto-publish job to social feed: $e');
        }
      }
    } else {
      final editJob = widget.jobToEdit!;
      final bool titleChanged = _titleController.text.trim() != editJob.title;
      final bool descChanged =
          _descriptionController.text.trim() != editJob.description;
      final bool catChanged = _selectedCategory != editJob.category.name;
      final bool budgetChanged =
          _getSubmitBudget() != (editJob.budget ?? '');
      final bool phoneChanged =
          _phoneController.text.trim() != (editJob.contactPhone ?? '');
      final bool tgChanged =
          _telegramController.text.trim() != (editJob.contactTelegram ?? '');
      final bool imagesChanged = !listEquals(finalImageUrls, editJob.imageUrls);
      final bool locTypeChanged = LocationType.fromString(locationType) != editJob.locationType;
      final bool cityChanged = city != editJob.city;
      final bool districtChanged = district != editJob.district;
      final bool settlementChanged = settlement != editJob.settlement;
      final bool workTypeChanged = WorkType.fromString(_selectedWorkType) != editJob.workType;

      final hasChanges =
          titleChanged ||
          descChanged ||
          catChanged ||
          budgetChanged ||
          phoneChanged ||
          tgChanged ||
          imagesChanged ||
          locTypeChanged ||
          cityChanged ||
          districtChanged ||
          settlementChanged ||
          workTypeChanged;

      String nextStatus = 'pending';
      if (!hasChanges && editJob.status == JobStatus.active) {
        nextStatus = 'active';
      }

      success = await jobService.updateJob(
        jobId: editJob.id,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        budget: _getSubmitBudget(),
        contactPhone: _phoneController.text,
        contactTelegram: _telegramController.text,
        imageUrls: finalImageUrls,
        status: nextStatus,
        rejectionComment: nextStatus == 'active'
            ? editJob.rejectionComment
            : null,
        locationType: locationType,
        city: city,
        district: district,
        settlement: settlement,
        workType: _selectedWorkType,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      final isEdit = widget.jobToEdit != null;
      String message = 'Заказ отправлен на проверку!';
      if (isEdit) {
        final editJob = widget.jobToEdit!;
        final bool titleChanged = _titleController.text.trim() != editJob.title;
        final bool descChanged =
            _descriptionController.text.trim() != editJob.description;
        final bool catChanged = _selectedCategory != editJob.category.name;
        final bool budgetChanged =
            _getSubmitBudget() != (editJob.budget ?? '');
        final bool phoneChanged =
            _phoneController.text.trim() != (editJob.contactPhone ?? '');
        final bool tgChanged =
            _telegramController.text.trim() != (editJob.contactTelegram ?? '');
        final bool imagesChanged = !listEquals(
          finalImageUrls,
          editJob.imageUrls,
        );
        final bool locTypeChanged = LocationType.fromString(locationType) != editJob.locationType;
        final bool cityChanged = city != editJob.city;
        final bool districtChanged = district != editJob.district;
        final bool settlementChanged = settlement != editJob.settlement;
        final bool workTypeChanged = WorkType.fromString(_selectedWorkType) != editJob.workType;
        
        final hasChanges =
            titleChanged ||
            descChanged ||
            catChanged ||
            budgetChanged ||
            phoneChanged ||
            tgChanged ||
            imagesChanged ||
            locTypeChanged ||
            cityChanged ||
            districtChanged ||
            settlementChanged ||
            workTypeChanged;

        if (!hasChanges && editJob.status == JobStatus.active) {
          message = 'Заказ сохранен без изменений!';
        } else {
          message = 'Заказ обновлен и отправлен на проверку!';
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context, true);
    } else {
      final error = jobService.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${error ?? "неизвестная ошибка"}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppTheme.cardBorderDark
                      : AppTheme.cardBorderLight,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                Text(
                  widget.jobToEdit != null
                      ? 'Редактировать заказ'
                      : 'Новый заказ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                _isSubmitting
                    ? const SizedBox(
                        width: 48,
                        height: 20,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: _submit,
                        child: Text(
                          widget.jobToEdit != null ? 'Сохранить' : 'Отправить',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Заголовок заказа *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        hintText: 'Например: Разработать дизайн визитки',
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Пожалуйста, введите заголовок';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Категория заказа *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: JobModel.categories.length,
                        itemBuilder: (context, index) {
                          final key = JobModel.categories.keys.elementAt(index);
                          final value = JobModel.categories[key]!;
                          final isSelected = _selectedCategory == key;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = key;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary.withValues(alpha: 0.12)
                                      : (isDark
                                            ? AppTheme.cardBorderDark
                                            : AppTheme.lightSurface),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary.withValues(
                                            alpha: 0.4,
                                          )
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      value['emoji']!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      value['name']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.primary
                                            : (isDark
                                                  ? Colors.white
                                                  : Colors.black),
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
                    const SizedBox(height: 20),

                    Text(
                      'Тип работы *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: JobModel.workTypes.entries.map((entry) {
                          final isSelected = _selectedWorkType == entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedWorkType = entry.key;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary.withValues(alpha: 0.12)
                                      : (isDark ? AppTheme.cardBorderDark : AppTheme.lightSurface),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary.withValues(alpha: 0.4)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Фотографии (максимум 5)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 88,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount:
                            (_existingImageUrls.length + _uploadingCount) +
                            ((_existingImageUrls.length + _uploadingCount) < 5 ? 1 : 0),
                        itemBuilder: (context, index) {
                          final totalImages = _existingImageUrls.length + _uploadingCount;
                          
                          if (index == totalImages) {
                            return GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.cardBorderDark : AppTheme.lightSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? Colors.white10 : Colors.black12,
                                    width: 1,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_rounded,
                                      color: AppTheme.primary,
                                      size: 28,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Добавить',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (index < _existingImageUrls.length) {
                            final url = _existingImageUrls[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 88,
                              height: 88,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: url,
                                      width: 88,
                                      height: 88,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: isDark ? AppTheme.darkSurface : AppTheme.cardBorderLight,
                                        child: const Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: isDark ? AppTheme.darkSurface : AppTheme.cardBorderLight,
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: isDark ? Colors.white24 : Colors.black26,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _existingImageUrls.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.cardBorderDark : AppTheme.lightSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.black12,
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Локация (город или район) *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showLocationPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardBorderDark : AppTheme.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    _selectedLocation == null
                                        ? Icons.location_on_outlined
                                        : (_selectedLocation!.contains('район')
                                            ? Icons.map_rounded
                                            : Icons.location_city_rounded),
                                    color: _selectedLocation == null ? Colors.grey : AppTheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedLocation ?? 'Выберите локацию в Дагестане',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: _selectedLocation == null ? FontWeight.normal : FontWeight.w600,
                                        color: _selectedLocation == null
                                            ? Colors.grey
                                            : (isDark ? Colors.white : Colors.black87),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    
                    if (_selectedLocation != null && _selectedLocation!.contains('район')) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Населенный пункт (село)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _settlementController,
                        decoration: const InputDecoration(
                          hintText: 'Например: Чох или Леваши (необязательно)',
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    Text(
                      'Подробное описание задачи *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: 500,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText:
                            'Опишите детали заказа, требования к исполнителю, сроки и условия работы.',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Пожалуйста, введите описание задачи';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Бюджет',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildBudgetTab('agreement', 'Договорная'),
                        const SizedBox(width: 8),
                        _buildBudgetTab('fixed', 'Фиксированный'),
                        const SizedBox(width: 8),
                        _buildBudgetTab('range', 'Диапазон'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_budgetType == 'fixed') ...[
                      TextFormField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                        decoration: const InputDecoration(
                          hintText: 'Введите сумму (например: 15 000)',
                          suffixText: '₽',
                        ),
                      ),
                    ] else if (_budgetType == 'range') ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _budgetFromController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [ThousandsSeparatorInputFormatter()],
                              decoration: const InputDecoration(
                                hintText: 'От (например: 5 000)',
                                suffixText: '₽',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _budgetToController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [ThousandsSeparatorInputFormatter()],
                              decoration: const InputDecoration(
                                hintText: 'До (например: 15 000)',
                                suffixText: '₽',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppTheme.cardBorderDark : AppTheme.lightSurface,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Цена будет указана как "Договорная"',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    Text(
                      'Телефон для связи *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      readOnly: true,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [RussianPhoneTextInputFormatter()],
                      decoration: const InputDecoration(
                        hintText: '+7 (999) 999-99-99',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty ||
                            value == '+7 ') {
                          return 'Введите контактный номер телефона';
                        }
                        if (value.length < 18) {
                          return 'Введите корректный номер телефона';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Telegram',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _telegramController,
                      decoration: const InputDecoration(
                        hintText: 'Например: @username или ссылка',
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (widget.jobToEdit == null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Опубликовать в Сообществе',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Создать пост в ленте Сообщества о вашем заказе',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _publishToSocialFeed,
                            activeThumbColor: AppTheme.primary,
                            onChanged: (val) {
                              setState(() {
                                _publishToSocialFeed = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _showPreview,
                        icon: const Icon(Icons.visibility_rounded, size: 18),
                        label: const Text('Предпросмотр объявления'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? Colors.white30 : Colors.black26,
                            width: 1,
                          ),
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      buffer.write(cleanText[i]);
      final reversedIndex = cleanText.length - 1 - i;
      if (reversedIndex % 3 == 0 && reversedIndex > 0) {
        buffer.write(' ');
      }
    }

    final String formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
