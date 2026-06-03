import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';
import '../services/image_upload_service.dart';
import '../services/supabase_config.dart';
import '../theme/app_theme.dart';
import '../models/job_model.dart';
import '../widgets/custom_text_field.dart'; // To reuse RussianPhoneTextInputFormatter

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
  final _phoneController = TextEditingController();
  final _telegramController = TextEditingController();

  String _selectedCategory = 'construction';
  bool _isSubmitting = false;
  final List<File> _selectedImages = [];
  final List<String> _existingImageUrls = [];

  Future<void> _pickImage() async {
    final totalCount = _existingImageUrls.length + _selectedImages.length;
    if (totalCount >= 5) return;

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } else {
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          final spaceLeft = 5 - totalCount;
          _selectedImages.addAll(
            pickedFiles.take(spaceLeft).map((xfile) => File(xfile.path)),
          );
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.jobToEdit != null) {
      _titleController.text = widget.jobToEdit!.title;
      _descriptionController.text = widget.jobToEdit!.description;
      _budgetController.text = widget.jobToEdit!.budget ?? '';
      _phoneController.text = widget.jobToEdit!.contactPhone ?? '';
      _telegramController.text = widget.jobToEdit!.contactTelegram ?? '';
      _selectedCategory = widget.jobToEdit!.category;
      _existingImageUrls.addAll(widget.jobToEdit!.imageUrls);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = Provider.of<AuthService>(
          context,
          listen: false,
        ).currentUser;
        if (user != null && user.phoneNumber.isNotEmpty) {
          // Apply phone formatter logic or prefill directly if it fits the mask
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
    _phoneController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final List<String> newUploadedUrls = [];
    if (_selectedImages.isNotEmpty) {
      if (!SupabaseConfig.isConfigured) {
        // Mock mode: simulate upload latency and use stock premium placeholder images
        for (int i = 0; i < _selectedImages.length; i++) {
          newUploadedUrls.add(
            'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=800&q=80',
          );
        }
      } else {
        try {
          for (final file in _selectedImages) {
            final optimizedResult = await ImageUploadService.optimizeImage(
              file,
            );
            final uploadResult = await ImageUploadService.uploadPostImage(
              imageFile: optimizedResult['optimized']!,
              thumbnailFile: optimizedResult['thumbnail']!,
            );
            newUploadedUrls.add(uploadResult['imageUrl']!);
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Ошибка загрузки фото: $e')));
          }
          return;
        }
      }
    }

    final finalImageUrls = [..._existingImageUrls, ...newUploadedUrls];
    bool success = false;
    final jobService = Provider.of<JobService>(context, listen: false);

    if (widget.jobToEdit == null) {
      success = await jobService.createJob(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        budget: _budgetController.text,
        contactPhone: _phoneController.text,
        contactTelegram: _telegramController.text,
        imageUrls: finalImageUrls,
      );
    } else {
      final editJob = widget.jobToEdit!;
      final bool titleChanged = _titleController.text.trim() != editJob.title;
      final bool descChanged =
          _descriptionController.text.trim() != editJob.description;
      final bool catChanged = _selectedCategory != editJob.category;
      final bool budgetChanged =
          _budgetController.text.trim() != (editJob.budget ?? '');
      final bool phoneChanged =
          _phoneController.text.trim() != (editJob.contactPhone ?? '');
      final bool tgChanged =
          _telegramController.text.trim() != (editJob.contactTelegram ?? '');
      final bool imagesChanged = !listEquals(finalImageUrls, editJob.imageUrls);

      final hasChanges =
          titleChanged ||
          descChanged ||
          catChanged ||
          budgetChanged ||
          phoneChanged ||
          tgChanged ||
          imagesChanged;
      String nextStatus = 'pending';
      if (!hasChanges && editJob.status == 'active') {
        nextStatus = 'active'; // keep active if no changes
      }

      success = await jobService.updateJob(
        jobId: editJob.id,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        budget: _budgetController.text,
        contactPhone: _phoneController.text,
        contactTelegram: _telegramController.text,
        imageUrls: finalImageUrls,
        status: nextStatus,
        rejectionComment: nextStatus == 'active'
            ? editJob.rejectionComment
            : null,
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
        final bool catChanged = _selectedCategory != editJob.category;
        final bool budgetChanged =
            _budgetController.text.trim() != (editJob.budget ?? '');
        final bool phoneChanged =
            _phoneController.text.trim() != (editJob.contactPhone ?? '');
        final bool tgChanged =
            _telegramController.text.trim() != (editJob.contactTelegram ?? '');
        final bool imagesChanged = !listEquals(
          finalImageUrls,
          editJob.imageUrls,
        );
        final hasChanges =
            titleChanged ||
            descChanged ||
            catChanged ||
            budgetChanged ||
            phoneChanged ||
            tgChanged ||
            imagesChanged;

        if (!hasChanges && editJob.status == 'active') {
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
          // Drag handle and header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE5E5EA),
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

          // Scrollable Form
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
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

                    // Category Selector Label
                    Text(
                      'Категория заказа *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Horizontal scroll categories
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
                                            ? const Color(0xFF2C2C2E)
                                            : const Color(0xFFF2F2F7)),
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

                    // Photos Selector Section
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
                            (_existingImageUrls.length +
                                _selectedImages.length) +
                            ((_existingImageUrls.length +
                                        _selectedImages.length) <
                                    5
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          final totalImages =
                              _existingImageUrls.length +
                              _selectedImages.length;
                          if (index == totalImages) {
                            // Add photo button
                            return GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2C2C2E)
                                      : const Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
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
                            // Existing Network Image
                            final url = _existingImageUrls[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 88,
                              height: 88,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      url,
                                      width: 88,
                                      height: 88,
                                      fit: BoxFit.cover,
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
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
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

                          // Selected Local File Image
                          final fileIndex = index - _existingImageUrls.length;
                          final file = _selectedImages[fileIndex];
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 88,
                            height: 88,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    file,
                                    width: 88,
                                    height: 88,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(fileIndex);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
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
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
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

                    // Budget
                    Text(
                      'Бюджет',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: const InputDecoration(
                        hintText:
                            'Например: 150 000 (оставьте пустым для договорной)',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Contact Phone
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

                    // Contact Telegram
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
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final clean = value.trim();
                          if (!clean.startsWith('@') &&
                              !clean.startsWith('http')) {
                            // Suggest adding @
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
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
