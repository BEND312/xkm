import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/data/m_theme.dart';

class SimplePagination extends StatelessWidget {
  const SimplePagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.showTotal = true,
    this.total,
  });

  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final bool showTotal;
  final int? total;

  Widget _buildPageButton(
    BuildContext context, {
    required int page,
    bool isActive = false,
    bool disabled = false,
    bool isEllipsis = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: FTappable(
        onPress: disabled ? null : () => onPageChanged(page),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? MTheme.primary2 : Colors.transparent,
            border: Border.all(
              color: isActive
                  ? MTheme.primary2
                  : Colors.grey.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              isEllipsis ? '...' : '$page',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPageButtons(BuildContext context) {
    const maxVisiblePages = 5;
    List<Widget> buttons = [];

    // 添加上一页按钮
    buttons.add(
      Container(
        margin: const EdgeInsets.only(right: 8),
        child: FTappable(
          onPress:
              currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Icon(
                Icons.chevron_left,
                size: 20,
                color: currentPage > 1
                    ? Colors.grey
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ),
    );

    // 计算要显示的页码范围
    int startPage = currentPage - (maxVisiblePages ~/ 2);
    int endPage = currentPage + (maxVisiblePages ~/ 2);

    if (startPage < 1) {
      endPage = endPage + (1 - startPage);
      startPage = 1;
    }

    if (endPage > totalPages) {
      startPage = startPage - (endPage - totalPages);
      endPage = totalPages;
    }

    startPage = startPage.clamp(1, totalPages);
    endPage = endPage.clamp(1, totalPages);

    // 添加页码按钮
    for (int i = startPage; i <= endPage; i++) {
      // 如果是最后一个按钮且还有更多页码，显示省略号
      bool isLastButton = i == endPage;
      bool hasMorePages = endPage < totalPages;
      bool showEllipsis = isLastButton && hasMorePages;

      buttons.add(_buildPageButton(
        context,
        page: i,
        isActive: i == currentPage,
        isEllipsis: showEllipsis,
      ));
    }

    // 添加下一页按钮
    buttons.add(
      Container(
        margin: const EdgeInsets.only(left: 8),
        child: FTappable(
          onPress: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: currentPage < totalPages
                    ? Colors.grey
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ),
    );

    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTotal && total != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '共 $total 条',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildPageButtons(context),
        ),
      ],
    );
  }
}
