import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InterestsSelector extends StatefulWidget {
  final List<String> selectedInterests;
  final Function(List<String>) onInterestsChanged;

  const InterestsSelector({
    super.key,
    required this.selectedInterests,
    required this.onInterestsChanged,
  });

  @override
  State<InterestsSelector> createState() => _InterestsSelectorState();
}

class _InterestsSelectorState extends State<InterestsSelector> {
  final TextEditingController _customInterestController =
      TextEditingController();

  final List<String> _suggestions = [
    'Flutter',
    'Dart',
    'Дизайн (UI/UX)',
    'Путешествия',
    'Спорт',
    'Музыка',
    'Книги',
    'Фильмы',
    'Кулинария',
    'Программирование',
    'Фотография',
    'Искусство',
    'Технологии',
    'Игры',
  ];

  void _addInterest(String interest) {
    final cleaned = interest.trim();
    if (cleaned.isEmpty) return;

    if (!widget.selectedInterests.any(
      (i) => i.toLowerCase() == cleaned.toLowerCase(),
    )) {
      final updatedList = List<String>.from(widget.selectedInterests)
        ..add(cleaned);
      widget.onInterestsChanged(updatedList);
    }
    _customInterestController.clear();
  }

  void _removeInterest(String interest) {
    final updatedList = List<String>.from(widget.selectedInterests)
      ..remove(interest);
    widget.onInterestsChanged(updatedList);
  }

  @override
  void dispose() {
    _customInterestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ваши интересы',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Выберите из предложенных или добавьте свои:',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),

        // Display current selected interests in a Wrap
        if (widget.selectedInterests.isNotEmpty) ...[
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: widget.selectedInterests.map((interest) {
              return Chip(
                label: Text(
                  interest,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppTheme.primary,
                deleteIcon: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
                onDeleted: () => _removeInterest(interest),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Input for custom interest
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customInterestController,
                decoration: InputDecoration(
                  hintText: 'Добавить свой интерес...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  fillColor: isDark ? AppTheme.darkBg : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppTheme.borderDark
                          : AppTheme.borderLight,
                    ),
                  ),
                ),
                onSubmitted: _addInterest,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _addInterest(_customInterestController.text),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Suggestion list
        Text(
          'Популярные теги:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _suggestions.map((suggestion) {
            final isSelected = widget.selectedInterests.contains(suggestion);
            return ChoiceChip(
              label: Text(
                suggestion,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _addInterest(suggestion);
                } else {
                  _removeInterest(suggestion);
                }
              },
              selectedColor: AppTheme.primary,
              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primary
                      : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  width: 1,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
