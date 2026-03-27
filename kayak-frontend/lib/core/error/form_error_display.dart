import 'package:flutter/material.dart';

/// Form error display component
///
/// Used to display form validation errors.
class FormErrorDisplay extends StatelessWidget {
  /// Field error mapping
  final Map<String, List<String>> fieldErrors;

  /// Whether to show icon
  final bool showIcon;

  /// Error text style
  final TextStyle? errorStyle;

  const FormErrorDisplay({
    super.key,
    required this.fieldErrors,
    this.showIcon = true,
    this.errorStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (fieldErrors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fieldErrors.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _FieldErrorItem(
            field: entry.key,
            errors: entry.value,
            showIcon: showIcon,
            errorStyle: errorStyle,
          ),
        );
      }).toList(),
    );
  }
}

class _FieldErrorItem extends StatelessWidget {
  final String field;
  final List<String> errors;
  final bool showIcon;
  final TextStyle? errorStyle;

  const _FieldErrorItem({
    required this.field,
    required this.errors,
    required this.showIcon,
    this.errorStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultStyle = errorStyle ??
        TextStyle(
          color: colorScheme.error,
          fontSize: 12,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showIcon) ...[
          Icon(
            Icons.error_outline,
            color: colorScheme.error,
            size: 16,
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (field.isNotEmpty)
                Text(
                  field,
                  style: defaultStyle.copyWith(fontWeight: FontWeight.w500),
                ),
              ...errors.map((error) => Text(
                    error,
                    style: defaultStyle,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

/// Inherited widget for form error scope
class FormErrorScope extends InheritedNotifier<FormErrorNotifier> {
  const FormErrorScope({
    super.key,
    required FormErrorNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static FormErrorNotifier of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FormErrorScope>();
    return scope!.notifier!;
  }
}

/// Form error state notifier
class FormErrorNotifier extends ChangeNotifier {
  Map<String, List<String>> _fieldErrors = {};

  /// Get field errors
  Map<String, List<String>> get fieldErrors => _fieldErrors;

  /// Check if there are any errors
  bool get hasErrors => _fieldErrors.isNotEmpty;

  /// Set errors for a field
  void setFieldError(String field, List<String> errors) {
    if (errors.isEmpty) {
      _fieldErrors.remove(field);
    } else {
      _fieldErrors[field] = errors;
    }
    notifyListeners();
  }

  /// Set all field errors
  void setErrors(Map<String, List<String>> errors) {
    _fieldErrors = Map.from(errors);
    notifyListeners();
  }

  /// Clear all errors
  void clear() {
    _fieldErrors = {};
    notifyListeners();
  }

  /// Clear errors for a specific field
  void clearField(String field) {
    _fieldErrors.remove(field);
    notifyListeners();
  }
}

/// Form error helper mixin
mixin FormErrorMixin<T extends StatefulWidget> on State<T> {
  FormErrorNotifier? _errorNotifier;

  /// Initialize form error tracking
  void initFormErrorTracking() {
    _errorNotifier = FormErrorNotifier();
  }

  /// Get current form errors
  Map<String, List<String>> get formErrors => _errorNotifier?.fieldErrors ?? {};

  /// Check if form has errors
  bool get hasFormErrors => _errorNotifier?.hasErrors ?? false;

  /// Set field error
  void setFieldError(String field, List<String> errors) {
    _errorNotifier?.setFieldError(field, errors);
  }

  /// Clear field error
  void clearFieldError(String field) {
    _errorNotifier?.clearField(field);
  }

  /// Clear all form errors
  void clearFormErrors() {
    _errorNotifier?.clear();
  }

  @override
  void dispose() {
    _errorNotifier?.dispose();
    super.dispose();
  }
}
