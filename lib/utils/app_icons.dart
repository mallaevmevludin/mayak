import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class AppIcons {
  // Available keys for selection inside the habit creator
  static const List<String> keys = [
    'activity',
    'droplet',
    'book',
    'brain',
    'apple',
    'bed',
    'coffee',
    'dumbbell',
    'sprout',
    'timer',
    'bike',
    'heart',
    'smile',
    'sparkles',
    'award',
    'flame',
    'gem',
    'star',
    'target',
    'briefcase',
    'brush',
    'music',
    'palette',
    'pen-tool',
    'graduation-cap',
  ];

  // Map key to IconData
  static IconData getIcon(String key) {
    switch (key) {
      case 'activity':
        return LucideIcons.activity;
      case 'droplet':
        return LucideIcons.droplet;
      case 'book':
        return LucideIcons.book;
      case 'brain':
        return LucideIcons.brain;
      case 'apple':
        return LucideIcons.apple;
      case 'bed':
        return LucideIcons.bed;
      case 'coffee':
        return LucideIcons.coffee;
      case 'dumbbell':
        return LucideIcons.dumbbell;
      case 'sprout':
        return LucideIcons.sprout;
      case 'timer':
        return LucideIcons.timer;
      case 'bike':
        return LucideIcons.bike;
      case 'heart':
        return LucideIcons.heart;
      case 'smile':
        return LucideIcons.smile;
      case 'sparkles':
        return LucideIcons.sparkles;
      case 'award':
        return LucideIcons.award;
      case 'flame':
        return LucideIcons.flame;
      case 'gem':
        return LucideIcons.gem;
      case 'star':
        return LucideIcons.star;
      case 'target':
        return LucideIcons.target;
      case 'briefcase':
        return LucideIcons.briefcase;
      case 'brush':
        return LucideIcons.brush;
      case 'music':
        return LucideIcons.music;
      case 'palette':
        return LucideIcons.palette;
      case 'pen-tool':
        return LucideIcons.pen_tool;
      case 'graduation-cap':
        return LucideIcons.graduation_cap;

      // Legacy Emoji Mappings for database / local state compatibility
      case '🏃':
        return LucideIcons.activity;
      case '💧':
        return LucideIcons.droplet;
      case '📚':
        return LucideIcons.book;
      case '🧘':
        return LucideIcons.brain;
      case '🧠':
        return LucideIcons.brain;
      case '🍎':
        return LucideIcons.apple;
      case '🥦':
        return LucideIcons.apple;
      case '💤':
        return LucideIcons.bed;
      case '🛌':
        return LucideIcons.bed;
      case '☕':
        return LucideIcons.coffee;
      case '🍵':
        return LucideIcons.coffee;
      case '💪':
        return LucideIcons.dumbbell;
      case '🌱':
        return LucideIcons.sprout;
      case '⏰':
        return LucideIcons.timer;
      case '🚴':
        return LucideIcons.bike;
      case '🏊':
        return LucideIcons.activity;
      case '✍️':
        return LucideIcons.pen_tool;
      case '🎹':
        return LucideIcons.music;
      case '🎸':
        return LucideIcons.music;
      case '🎨':
        return LucideIcons.palette;
      case '💼':
        return LucideIcons.briefcase;
      case '🧹':
        return LucideIcons.brush;
      case '🎓':
        return LucideIcons.graduation_cap;
      case '🌟':
        return LucideIcons.sparkles;
      case '❤️':
        return LucideIcons.heart;
      case '🔥':
        return LucideIcons.flame;
      case '💎':
        return LucideIcons.gem;
      case '⭐':
        return LucideIcons.star;
      case '🎯':
        return LucideIcons.target;
      case '🏅':
        return LucideIcons.award;
      case '🚶':
        return LucideIcons.activity;
      case '🚭':
        return LucideIcons.ban;
      case '💻':
        return LucideIcons.laptop;
      case '🌳':
        return LucideIcons.sprout;
      case '✏️':
        return LucideIcons.pen_tool;

      default:
        return LucideIcons.circle_question_mark;
    }
  }
}
