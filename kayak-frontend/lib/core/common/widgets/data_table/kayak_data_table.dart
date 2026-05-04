/// Data table component with pagination, sorting, and empty state
library;

import 'package:flutter/material.dart';

/// Column definition for data table
class DataTableColumn<T> {
  const DataTableColumn({
    required this.label,
    required this.valueBuilder,
    this.width,
    this.sortable = false,
    this.textAlign = TextAlign.start,
  });
  final String label;
  final String Function(T item) valueBuilder;
  final double? width;
  final bool sortable;
  final TextAlign textAlign;
}

/// Sort state for data table
class SortState {
  const SortState({
    required this.columnIndex,
    required this.ascending,
  });
  final int columnIndex;
  final bool ascending;
}

/// Generic data table with pagination
class KayakDataTable<T> extends StatefulWidget {
  const KayakDataTable({
    super.key,
    required this.columns,
    required this.data,
    this.pageSize = 10,
    this.showPagination = true,
    this.showRowNumbers = false,
    this.onRefresh,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = false,
  });
  final List<DataTableColumn<T>> columns;
  final List<T> data;
  final int pageSize;
  final bool showPagination;
  final bool showRowNumbers;
  final VoidCallback? onRefresh;
  final Future<void> Function()? onLoadMore;
  final bool isLoading;
  final bool hasMore;

  @override
  State<KayakDataTable<T>> createState() => _KayakDataTableState<T>();
}

class _KayakDataTableState<T> extends State<KayakDataTable<T>> {
  int _currentPage = 0;
  SortState? _sortState;

  int get _totalPages => (widget.data.length / widget.pageSize).ceil();

  List<T> get _pageData {
    if (!widget.showPagination) {
      return _sortedData;
    }

    final start = _currentPage * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, widget.data.length);

    if (start >= widget.data.length) {
      return [];
    }

    return _sortedData.sublist(start, end);
  }

  List<T> get _sortedData {
    if (_sortState == null) {
      return widget.data;
    }

    final column = widget.columns[_sortState!.columnIndex];
    final ascending = _sortState!.ascending;

    final sorted = List<T>.from(widget.data);
    sorted.sort((a, b) {
      final aValue = column.valueBuilder(a);
      final bValue = column.valueBuilder(b);

      // valueBuilder returns String, so use string comparison
      final result = aValue.compareTo(bValue);
      return ascending ? result : -result;
    });

    return sorted;
  }

  void _onSort(int columnIndex) {
    if (!widget.columns[columnIndex].sortable) return;

    setState(() {
      if (_sortState?.columnIndex == columnIndex) {
        _sortState = SortState(
          columnIndex: columnIndex,
          ascending: !_sortState!.ascending,
        );
      } else {
        _sortState = SortState(
          columnIndex: columnIndex,
          ascending: true,
        );
      }
    });
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty && !widget.isLoading) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: _buildTable(),
          ),
        ),
        if (widget.showPagination) _buildPagination(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无数据',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: _sortState?.columnIndex,
        sortAscending: _sortState?.ascending ?? true,
        columns: [
          if (widget.showRowNumbers)
            const DataColumn(
              label: Text('#'),
            ),
          ...widget.columns.asMap().entries.map((entry) {
            final column = entry.value;
            return DataColumn(
              label: Text(column.label),
              numeric: column.textAlign == TextAlign.end,
              onSort: column.sortable ? (_, __) => _onSort(entry.key) : null,
            );
          }),
        ],
        rows: _pageData.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return DataRow(
            cells: [
              if (widget.showRowNumbers)
                DataCell(Text('${_currentPage * widget.pageSize + index + 1}')),
              ...widget.columns.map((column) {
                return DataCell(
                  Text(
                    column.valueBuilder(item),
                    textAlign: column.textAlign,
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPagination() {
    if (!widget.showPagination || _totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
          ),
          const SizedBox(width: 16),
          Text(
            '第 ${_currentPage + 1} / $_totalPages 页',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages - 1
                ? () => _goToPage(_currentPage + 1)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: _currentPage < _totalPages - 1
                ? () => _goToPage(_totalPages - 1)
                : null,
          ),
          if (widget.hasMore && widget.onLoadMore != null) ...[
            const SizedBox(width: 16),
            if (widget.isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton(
                onPressed: widget.onLoadMore,
                child: const Text('加载更多'),
              ),
          ],
        ],
      ),
    );
  }
}
