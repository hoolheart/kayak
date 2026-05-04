/// Form input components
library;

import 'package:flutter/material.dart';

/// Search input field with clear button
class SearchInput extends StatefulWidget {
  const SearchInput({
    super.key,
    this.hintText = '搜索...',
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.debounceDelay = const Duration(milliseconds: 300),
  });
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final Duration debounceDelay;

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clear,
              )
            : null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

/// Filter chip selector for single or multiple selection
class FilterChipSelector<T> extends StatelessWidget {
  const FilterChipSelector({
    super.key,
    required this.options,
    this.selectedValue,
    this.selectedValues = const [],
    this.onChanged,
    this.onMultiChanged,
    this.allowMultiple = false,
    required this.labelBuilder,
    this.showAllOption = true,
  }) : assert(
          allowMultiple ? onMultiChanged != null : onChanged != null,
          'Either onChanged or onMultiChanged must be provided based on allowMultiple',
        );
  final List<T> options;
  final T? selectedValue;
  final List<T> selectedValues;
  final ValueChanged<T?>? onChanged;
  final ValueChanged<List<T>>? onMultiChanged;
  final bool allowMultiple;
  final String Function(T) labelBuilder;
  final bool showAllOption;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (showAllOption && allowMultiple)
          FilterChip(
            label: const Text('全部'),
            selected: selectedValues.isEmpty,
            onSelected: (selected) {
              if (selected) {
                onMultiChanged?.call([]);
              }
            },
          ),
        if (showAllOption && !allowMultiple)
          FilterChip(
            label: const Text('全部'),
            selected: selectedValue == null,
            onSelected: (selected) {
              if (selected) {
                onChanged?.call(null as T);
              }
            },
          ),
        ...options.map((option) {
          if (allowMultiple) {
            final isSelected = selectedValues.contains(option);
            return FilterChip(
              label: Text(labelBuilder(option)),
              selected: isSelected,
              onSelected: (selected) {
                final newValues = List<T>.from(selectedValues);
                if (selected) {
                  newValues.add(option);
                } else {
                  newValues.remove(option);
                }
                onMultiChanged?.call(newValues);
              },
            );
          } else {
            final isSelected = selectedValue == option;
            return FilterChip(
              label: Text(labelBuilder(option)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onChanged?.call(option);
                }
              },
            );
          }
        }),
      ],
    );
  }
}

/// Status badge widget
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  factory StatusBadge.success(String label) {
    return StatusBadge(
      label: label,
      backgroundColor: Colors.green.shade100,
      textColor: Colors.green.shade800,
    );
  }

  factory StatusBadge.warning(String label) {
    return StatusBadge(
      label: label,
      backgroundColor: Colors.orange.shade100,
      textColor: Colors.orange.shade800,
    );
  }

  factory StatusBadge.error(String label) {
    return StatusBadge(
      label: label,
      backgroundColor: Colors.red.shade100,
      textColor: Colors.red.shade800,
    );
  }

  factory StatusBadge.info(String label) {
    return StatusBadge(
      label: label,
      backgroundColor: Colors.blue.shade100,
      textColor: Colors.blue.shade800,
    );
  }

  factory StatusBadge.neutral(String label) {
    return StatusBadge(
      label: label,
      backgroundColor: Colors.grey.shade100,
      textColor: Colors.grey.shade800,
    );
  }
  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
