/*
 * Copyright (c) 2025 BEND
 *
 * This file is a new addition to the project, created as part of secondary development.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/refresh_icon.dart';
import 'package:swustmeow/entity/soa/evaluation_paper.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/status.dart';

import '../../components/utils/base_page.dart';
import '../../data/m_theme.dart';

class SOAEvaluationPage extends StatefulWidget {
  const SOAEvaluationPage({super.key});

  @override
  State<StatefulWidget> createState() => _SOAEvaluationPageState();
}

class _SOAEvaluationPageState extends State<SOAEvaluationPage>
    with SingleTickerProviderStateMixin {
  List<EvaluationPaper> _evaluations = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSubmitting = false;
  late AnimationController _refreshAnimationController;

  // 评价设置
  int _selectedValue = 1; // 默认为非常满意
  String _courseComment = "无";
  final TextEditingController _commentController = TextEditingController();

  // 评分等级选项
  final List<Map<String, dynamic>> _valueOptions = [
    {'value': 1, 'label': '非常满意'},
    {'value': 2, 'label': '满意'},
    {'value': 3, 'label': '一般'},
    {'value': 4, 'label': '不满意'},
  ];

  @override
  void initState() {
    super.initState();
    _commentController.text = _courseComment;
    _loadData();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  Future<void> _loadData() async {
    final service = GlobalService.soaService;
    if (service == null) {
      _refresh(() => _isLoading = false);
      return;
    }

    final result = await service.getEvaluationPaperList();
    if (result.status == Status.ok) {
      _refresh(() {
        _evaluations = result.value ?? [];
        _isLoading = false;
      });
    } else {
      _refresh(() => _isLoading = false);
    }
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  Future<void> _submitAll() async {
    if (_isSubmitting) return;

    final confirmed = await _showConfirmDialog(
      title: '确认批量评价',
      content: '确定要对所有课程（${_evaluations.length}门）进行批量评价吗？\n\n'
          '评分等级：${_valueOptions[_selectedValue - 1]['label']}\n'
          '评论内容：${_courseComment.isEmpty ? "无" : _courseComment}',
    );

    if (confirmed != true) return;

    _refresh(() => _isSubmitting = true);

    final service = GlobalService.soaService;
    if (service == null) {
      _refresh(() => _isSubmitting = false);
      showErrorToast('服务不可用');
      return;
    }

    final result = await service.evaluateAll(
      courseComment: _courseComment,
      value: _selectedValue,
    );

    _refresh(() => _isSubmitting = false);

    if (result.status == Status.ok && result.value != null) {
      final data = result.value!;
      final total = data['total'] as int;
      final completed = data['completed'] as int;
      
      showSuccessToast('评价完成！成功 $completed/$total 门课程');
      
      // 刷新列表
      await _loadData();
    } else {
      showErrorToast('评价失败，请稍后重试');
    }
  }

  Future<void> _submitOne(EvaluationPaper evaluation) async {
    if (_isSubmitting) return;

    final confirmed = await _showConfirmDialog(
      title: '确认评价',
      content: '确定要评价以下课程吗？\n\n'
          '课程：${evaluation.course}\n'
          '教师：${evaluation.teacher}\n'
          '学院：${evaluation.college}\n\n'
          '评分等级：${_valueOptions[_selectedValue - 1]['label']}\n'
          '评论内容：${_courseComment.isEmpty ? "无" : _courseComment}',
    );

    if (confirmed != true) return;

    _refresh(() => _isSubmitting = true);

    final service = GlobalService.soaService;
    if (service == null) {
      _refresh(() => _isSubmitting = false);
      showErrorToast('服务不可用');
      return;
    }

    final result = await service.evaluateOne(
      evaluation.toJson(),
      _courseComment,
      _selectedValue,
    );

    _refresh(() => _isSubmitting = false);

    if (result.status == Status.ok && result.value == true) {
      showSuccessToast('评价成功！');
      
      // 刷新列表
      await _loadData();
    } else {
      showErrorToast('评价失败，请稍后重试');
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BasePage(
        headerPad: false,
        header: BaseHeader(
          title: '教评提交',
          suffixIcons: [
            RefreshIcon(
              isRefreshing: _isRefreshing,
              onRefresh: () async {
                if (_isRefreshing || _isLoading) return;
                _refresh(() => _isRefreshing = true);
                _refreshAnimationController.repeat();
                await _loadData();
                _refresh(() {
                  _isRefreshing = false;
                  _refreshAnimationController.stop();
                  _refreshAnimationController.reset();
                });
              },
            )
          ],
        ),
        content: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: MTheme.primary2,
            ),
            const SizedBox(height: 16),
            Text(
              '加载中...',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_evaluations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FontAwesomeIcons.circleCheck,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无待评价的课程',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '所有课程评价已完成',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSettingsPanel(),
        Expanded(
          child: _buildEvaluationList(),
        ),
      ],
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '评分等级',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _valueOptions.map((option) {
                final isSelected = _selectedValue == option['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _refresh(() => _selectedValue = option['value']);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? MTheme.primary2 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              option['label'],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[700],
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '评论内容',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: TextField(
              controller: _commentController,
              maxLines: 1,
              minLines: 1,
              decoration: InputDecoration(
                hintText: '请输入评论内容（选填）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
                isDense: true,
              ),
              onChanged: (value) {
                _courseComment = value.isEmpty ? "无" : value;
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitAll,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(FontAwesomeIcons.paperPlane, size: 16),
              label: Text(
                _isSubmitting ? '提交中...' : '批量评价（${_evaluations.length}门课程）',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MTheme.primary2,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _evaluations.length,
      itemBuilder: (context, index) {
        final evaluation = _evaluations[index];
        return _buildEvaluationCard(evaluation);
      },
    );
  }

  Widget _buildEvaluationCard(EvaluationPaper evaluation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.bookOpen,
                      size: 16,
                      color: MTheme.primary2,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        evaluation.course,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  FontAwesomeIcons.userGraduate,
                  '教师',
                  evaluation.teacher,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  FontAwesomeIcons.building,
                  '学院',
                  evaluation.college,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _isSubmitting ? null : () => _submitOne(evaluation),
                  icon: Icon(
                    FontAwesomeIcons.check,
                    size: 14,
                  ),
                  label: const Text('单独评价'),
                  style: TextButton.styleFrom(
                    foregroundColor: MTheme.primary2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 8),
        Text(
          '$label：',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
