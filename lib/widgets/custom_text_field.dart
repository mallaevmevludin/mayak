import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool isValidated; // Show green check if true
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.isValidated = false,
    this.inputFormatters,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      // Validate on blur
      if (!_focusNode.hasFocus && widget.validator != null) {
        setState(() {
          _errorText = widget.validator!(widget.controller.text);
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword ? _obscureText : false,
            keyboardType: widget.keyboardType,
            style: TextStyle(
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w500,
            ),
            inputFormatters: widget.inputFormatters,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              prefixIcon: Icon(
                widget.prefixIcon,
                color: _isFocused
                    ? AppTheme.primary
                    : (_errorText != null
                          ? AppTheme.error
                          : (widget.isValidated
                                ? AppTheme.success
                                : AppTheme.textSecondaryDark)),
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textSecondaryDark,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : (widget.isValidated && _errorText == null
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.success,
                          )
                        : (_errorText != null
                              ? const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppTheme.error,
                                )
                              : null)),
              // Apply dynamic borders manually or through decoration
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isValidated
                      ? AppTheme.success
                      : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  width: 0.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isValidated
                      ? AppTheme.success
                      : AppTheme.primary,
                  width: 1.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.error, width: 0.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.error, width: 1.0),
              ),
            ),
            onChanged: (val) {
              if (widget.onChanged != null) {
                widget.onChanged!(val);
              }
              if (_errorText != null && widget.validator != null) {
                // Clear error immediately if user fixes the input
                setState(() {
                  _errorText = widget.validator!(val);
                });
              }
            },
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: Text(
              _errorText!,
              style: const TextStyle(
                color: AppTheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

/// A custom formatter to enforce the phone layout: +7 (XXX) XXX-XX-XX
class RussianPhoneTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Always start with +7
    if (text.isEmpty) {
      return const TextEditingValue(
        text: '+7 ',
        selection: TextSelection.collapsed(offset: 3),
      );
    }

    // Strip non-digits except first '+'
    String digits = text.replaceAll(RegExp(r'\D'), '');

    // Ensure it starts with 7. If they delete the 7, replace it.
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '+7 ',
        selection: TextSelection.collapsed(offset: 3),
      );
    }

    if (digits.startsWith('7') || digits.startsWith('8')) {
      digits = digits.substring(1);
    }

    // Cap digits at 10 (excluding country code)
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    final StringBuffer buffer = StringBuffer('+7 ');

    for (int i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      buffer.write(digits[i]);
      if (i == 2) buffer.write(') ');
      if (i == 5) buffer.write('-');
      if (i == 7) buffer.write('-');
    }

    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
