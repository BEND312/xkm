import 'package:flutter/material.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/components/ykt/pay/ykt_payment_amount_card.dart';
import 'package:swustmeow/components/ykt/pay/ykt_payment_submit_button.dart';
import 'package:swustmeow/components/ykt/pay/ykt_payment_total_card.dart';
import 'package:swustmeow/components/ykt/ykt_card_info_panel.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/entity/apaertment/apartment_student_info.dart';
import 'package:swustmeow/entity/ykt/ykt_card.dart';
import 'package:swustmeow/entity/ykt/ykt_pay_app.dart';
import 'package:swustmeow/services/boxes/apartment_box.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/status.dart';

import '../../../services/ykt_payment_service.dart';

class YKTElectricityPayPage extends StatefulWidget {
  final List<YKTCard> cards;
  final YKTPayApp payApp;

  const YKTElectricityPayPage({
    super.key,
    required this.cards,
    required this.payApp,
  });

  @override
  State<YKTElectricityPayPage> createState() => _YKTElectricityPayPageState();
}

class _YKTElectricityPayPageState extends State<YKTElectricityPayPage> {
  bool _isLoading = false;
  bool _isSubmitting = false;

  // 缴费信息
  String? _selectedCampus;
  String? _selectedBuilding;
  String? _selectedFloor;
  String? _selectedRoom;
  String _payerName = '';
  double _amount = 0.0;

  // 选择数据
  List<Map<String, String>> _campusList = [];
  List<Map<String, String>> _buildingList = [];
  List<Map<String, String>> _floorList = [];
  List<Map<String, String>> _roomList = [];

  // 控制器
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _payerController = TextEditingController();

  // 添加焦点节点
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _payerFocusNode = FocusNode();

  // 新增变量
  String? _pendingCampusName;
  String? _pendingBuilding;
  String? _pendingFloor;
  String? _pendingRoom;

  // 添加跟踪标志，记录用户是否已手动选择
  bool _hasCampusManuallySelected = false;
  bool _hasBuildingManuallySelected = false;
  bool _hasFloorManuallySelected = false;
  bool _hasRoomManuallySelected = false;

  YKTCard? _useCard;
  Map<String, dynamic> _showData = {};
  Map<String, dynamic> _finalData = {};

  @override
  void initState() {
    super.initState();
    _loadPaymentUserInfo();
    _loadCampuses();
    _loadInfo();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _payerController.dispose();
    // 释放焦点节点
    _amountFocusNode.dispose();
    _payerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentUserInfo() async {
    final infoResult = await GlobalService.yktService!
        .getPaymentUserInfo(feeItemId: widget.payApp.feeItemId);
    if (infoResult.status != Status.ok) {
      showErrorToast('无法获取支付信息，请重试');
      return;
    }

    final info = infoResult.value as Map<String, dynamic>;
    final name = info['name'] as String;
    final cardAccount = info['cardAccount'] as String;

    setState(() {
      _payerName = name;
      _payerController.text = name;
      _useCard =
          widget.cards.where((c) => c.account == cardAccount).firstOrNull;
    });
  }

  // 加载校区数据
  Future<void> _loadCampuses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (GlobalService.yktService == null) {
        showErrorToast('本地服务未启动，请重启 APP');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final result = await GlobalService.yktService!.getElectricityData(
        level: '0',
        feeItemId: widget.payApp.feeItemId,
      );

      if (result.status != Status.ok) {
        showErrorToast(result.value ?? '获取校区数据失败');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _campusList =
            (result.value as List<dynamic>).map<Map<String, String>>((item) {
          return {
            'name': item['name'],
            'value': item['value'],
          };
        }).toList();
        _isLoading = false;
      });

      // 设置默认校区（仅当用户尚未手动选择时）
      if (_pendingCampusName != null && !_hasCampusManuallySelected) {
        // 在返回的列表中查找匹配的校区
        for (var campus in _campusList) {
          if (campus['name'] == _pendingCampusName) {
            setState(() {
              _selectedCampus = campus['value'];
            });
            _loadBuildings(_selectedCampus!);
            break;
          }
        }
      }
    } catch (e) {
      showErrorToast('加载校区数据失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInfo() async {
    final info = ApartmentBox.get('studentInfo') as ApartmentStudentInfo?;

    if (info != null && info.roomName.isNotEmpty) {
      // 解析 roomName (例如："西5-404")
      final parts = info.roomName.split('-');
      if (parts.length == 2) {
        final building = parts[0]; // 例如："西5"
        final roomNumber = parts[1]; // 例如："404"

        // 确定校区 (北苑、西苑、西山、东苑)
        String campusName = '';
        if (building.startsWith('北')) {
          campusName = '北苑';
        } else if (building.startsWith('西山')) {
          campusName = '西山';
        } else if (building.startsWith('西')) {
          campusName = '西苑';
        } else if (building.startsWith('东')) {
          campusName = '东苑';
        }

        // 确定楼层 (从房间号第一位获取)
        final floor = roomNumber.isNotEmpty ? roomNumber.substring(0, 1) : '';

        // 存储解析出的信息，等待 _loadCampuses() 完成后设置
        setState(() {
          _pendingCampusName = campusName;
          _pendingBuilding = building;
          _pendingFloor = floor;
          _pendingRoom = roomNumber;
        });
      }
    }
  }

  // 加载楼栋数据
  Future<void> _loadBuildings(String campusValue) async {
    setState(() {
      _isLoading = true;
      if (!_hasBuildingManuallySelected) {
        _selectedBuilding = null;
        _selectedFloor = null;
        _selectedRoom = null;
      }
      _buildingList = [];
      _floorList = [];
      _roomList = [];
    });

    try {
      final result = await GlobalService.yktService!.getElectricityData(
        level: '1',
        feeItemId: widget.payApp.feeItemId,
        campus: campusValue,
      );

      if (result.status != Status.ok) {
        showErrorToast(result.value ?? '获取楼栋数据失败');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _buildingList =
            (result.value as List<dynamic>).map<Map<String, String>>((item) {
          return {
            'name': item['name'],
            'value': item['value'],
          };
        }).toList();
        _isLoading = false;
      });

      // 设置默认楼栋（仅当用户尚未手动选择时）
      if (_pendingBuilding != null && !_hasBuildingManuallySelected) {
        // 在返回的列表中查找匹配的楼栋
        for (var building in _buildingList) {
          if (building['name'] == _pendingBuilding) {
            setState(() {
              _selectedBuilding = building['value'];
            });
            _loadFloors(_selectedBuilding!);
            break;
          }
        }
      }
    } catch (e) {
      showErrorToast('加载楼栋数据失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 加载楼层数据
  Future<void> _loadFloors(String buildingValue) async {
    setState(() {
      _isLoading = true;
      if (!_hasFloorManuallySelected) {
        _selectedFloor = null;
        _selectedRoom = null;
      }
      _floorList = [];
      _roomList = [];
    });

    try {
      final result = await GlobalService.yktService!.getElectricityData(
        level: '2',
        feeItemId: widget.payApp.feeItemId,
        campus: _selectedCampus!,
        building: buildingValue,
      );

      if (result.status != Status.ok) {
        showErrorToast(result.value ?? '获取楼层数据失败');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _floorList =
            (result.value as List<dynamic>).map<Map<String, String>>((item) {
          return {
            'name': item['name'],
            'value': item['value'],
          };
        }).toList();
        _isLoading = false;
      });

      // 设置默认楼层（仅当用户尚未手动选择时）
      if (_pendingFloor != null && !_hasFloorManuallySelected) {
        // 在返回的列表中查找匹配的楼层
        for (var floor in _floorList) {
          // 可能是"4楼"或其他格式，需要根据实际数据格式调整
          if (floor['name']!.startsWith(_pendingFloor!)) {
            setState(() {
              _selectedFloor = floor['value'];
            });
            _loadRooms(_selectedFloor!);
            break;
          }
        }
      }
    } catch (e) {
      showErrorToast('加载楼层数据失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 加载房间数据
  Future<void> _loadRooms(String floorValue) async {
    setState(() {
      _isLoading = true;
      if (!_hasRoomManuallySelected) {
        _selectedRoom = null;
      }
      _roomList = [];
    });

    try {
      final result = await GlobalService.yktService!.getElectricityData(
        level: '3',
        feeItemId: widget.payApp.feeItemId,
        campus: _selectedCampus!,
        building: _selectedBuilding!,
        floor: floorValue,
      );

      if (result.status != Status.ok) {
        showErrorToast(result.value ?? '获取房间数据失败');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _roomList =
            (result.value as List<dynamic>).map<Map<String, String>>((item) {
          return {
            'name': item['name'],
            'value': item['value'],
          };
        }).toList();
        _isLoading = false;
      });

      // 设置默认房间（仅当用户尚未手动选择时）
      if (_pendingRoom != null && !_hasRoomManuallySelected) {
        // 在返回的列表中查找匹配的房间
        for (var room in _roomList) {
          // 房间可能是完整格式如"西4-404"或只是"404"，需要根据实际返回数据调整
          if (room['name']!.contains(_pendingRoom!)) {
            setState(() {
              _selectedRoom = room['value'];
            });
            _loadFinalData();
            break;
          }
        }
      }
    } catch (e) {
      showErrorToast('加载房间数据失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFinalData() async {
    setState(() {
      _isLoading = true;
    });

    final result = await GlobalService.yktService!.getElectricityFinalData(
      feeItemId: widget.payApp.feeItemId,
      campus: _selectedCampus!,
      building: _selectedBuilding!,
      floor: _selectedFloor!,
      room: _selectedRoom!,
    );

    if (result.status != Status.ok) {
      showErrorToast(result.value ?? '获取最终数据失败');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final data = result.value as Map<String, dynamic>;
    setState(() {
      _showData = data['showData'] as Map<String, dynamic>;
      _finalData = data['data'] as Map<String, dynamic>;
      _isLoading = false;
    });

    // 设置默认房间（仅当用户尚未手动选择时）
    if (_pendingRoom != null && !_hasRoomManuallySelected) {
      // 在返回的列表中查找匹配的房间
      for (var room in _roomList) {
        // 房间可能是完整格式如"西4-404"或只是"404"，需要根据实际返回数据调整
        if (room['name']!.contains(_pendingRoom!)) {
          setState(() {
            _selectedRoom = room['value'];
          });
          _loadFinalData();
          break;
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 处理缴费提交
  Future<void> _handleSubmit() async {
    // 检查所有必须字段是否已选择
    if (_selectedCampus == null ||
        _selectedBuilding == null ||
        _selectedFloor == null ||
        _selectedRoom == null) {
      showErrorToast('请完成所有必要的选择');
      return;
    }

    if (_payerName.isEmpty) {
      showErrorToast('缴费人姓名未知');
      return;
    }

    if (_amount <= 0) {
      showErrorToast('请输入有效的缴费金额');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await YKTPaymentService.processPayment(
        context: context,
        feeItemId: widget.payApp.feeItemId,
        amount: _amount,
        roomData: _finalData,
        additionalInfo: {'支付项目': widget.payApp.name},
        onSuccess: () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // 选择校区
  void _onCampusSelected(String value) {
    _hasCampusManuallySelected = true;
    setState(() {
      _selectedCampus = value;
    });
    _loadBuildings(value);
  }

  // 选择楼栋
  void _onBuildingSelected(String value) {
    _hasBuildingManuallySelected = true;
    setState(() {
      _selectedBuilding = value;
    });
    _loadFloors(value);
  }

  // 选择楼层
  void _onFloorSelected(String value) {
    _hasFloorManuallySelected = true;
    setState(() {
      _selectedFloor = value;
    });
    _loadRooms(value);
  }

  // 选择房间
  void _onRoomSelected(String value) {
    _hasRoomManuallySelected = true;
    setState(() {
      _selectedRoom = value;
    });
    _loadFinalData();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(title: '${widget.payApp.name}缴费'),
      content: SafeArea(
        top: false,
        child: Material(
          color: Colors.transparent,
          // 添加点击空白区域取消焦点
          child: GestureDetector(
            onTap: () {
              // 点击空白区域时移除焦点
              _amountFocusNode.unfocus();
              _payerFocusNode.unfocus();
            },
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      if (_useCard != null &&
                          _useCard?.accountInfos.isNotEmpty == true)
                        YKTCardInfoPanel(
                          card: _useCard!,
                          account: _useCard!.accountInfos.first,
                        ),
                      _buildInfoCard(),
                      YKTPaymentAmountCard(
                        amountController: _amountController,
                        amountFocusNode: _amountFocusNode,
                        onAmountChanged: (value) =>
                            setState(() => _amount = value),
                        currentAmount: _amount,
                      ),
                      const SizedBox(height: 12),
                      YKTPaymentTotalCard(amount: _amount),
                      const SizedBox(height: 60), // 为底部浮动按钮留出空间
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: YKTPaymentSubmitButton(
                    onPressed: _handleSubmit,
                    isSubmitting: _isSubmitting,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 信息卡片 - 校区、楼栋、楼层、房间选择与显示
  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MTheme.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 校区选择
          _buildSelectionItem(
            label: '选择校区',
            value: _getCampusName(),
            isLoading: _isLoading && _campusList.isEmpty,
            onTap: () => _showSelectionDialog(
              title: '选择校区',
              items: _campusList,
              onSelected: _onCampusSelected,
            ),
          ),

          // 楼栋选择
          _buildSelectionItem(
            label: '选择楼栋',
            value: _getBuildingName(),
            isLoading:
                _isLoading && _selectedCampus != null && _buildingList.isEmpty,
            onTap: _selectedCampus == null
                ? null
                : () => _showSelectionDialog(
                      title: '选择楼栋',
                      items: _buildingList,
                      onSelected: _onBuildingSelected,
                    ),
          ),

          // 楼层选择
          _buildSelectionItem(
            label: '选择楼层',
            value: _getFloorName(),
            isLoading:
                _isLoading && _selectedBuilding != null && _floorList.isEmpty,
            onTap: _selectedBuilding == null
                ? null
                : () => _showSelectionDialog(
                      title: '选择楼层',
                      items: _floorList,
                      onSelected: _onFloorSelected,
                    ),
          ),

          // 房间选择
          _buildSelectionItem(
            label: '选择房间',
            value: _getRoomName(),
            isLoading:
                _isLoading && _selectedFloor != null && _roomList.isEmpty,
            onTap: _selectedFloor == null
                ? null
                : () => _showSelectionDialog(
                      title: '选择房间',
                      items: _roomList,
                      onSelected: _onRoomSelected,
                    ),
          ),

          // 显示已选择的信息
          _buildInfoSummary(),

          // 缴费人
          _buildPayerInput(),
        ],
      ),
    );
  }

  // 选择项构建
  Widget _buildSelectionItem({
    required String label,
    required String value,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
              const Spacer(),
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(MTheme.primary2),
                  ),
                )
              else
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        onTap == null ? Colors.grey : const Color(0xFF666666),
                  ),
                ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: onTap == null
                    ? Colors.grey.withValues(alpha: 0.5)
                    : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 信息汇总显示
  Widget _buildInfoSummary() {
    bool hasAllInfo = _selectedCampus != null &&
        _selectedBuilding != null &&
        _selectedFloor != null &&
        _selectedRoom != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '信息',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const Spacer(),
          hasAllInfo && _isLoading && _showData.isEmpty
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(MTheme.primary2),
                  ),
                )
              : Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        hasAllInfo
                            ? _showData.isNotEmpty
                                ? _showData['房间名称']
                                : ''
                            : '请选择房间后确认信息',
                        style: TextStyle(
                          fontSize: 15,
                          color: hasAllInfo ? MTheme.primary2 : Colors.grey,
                          fontWeight:
                              hasAllInfo ? FontWeight.w500 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      if (hasAllInfo && _showData.isNotEmpty)
                        Text(
                          '房间号: ${_showData['房间号']}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.right,
                        ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  // 缴费人显示
  Widget _buildPayerInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            '缴费人',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const Spacer(),
          Text(
            _payerName,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  // 显示选择对话框
  Future<void> _showSelectionDialog({
    required String title,
    required List<Map<String, String>> items,
    required Function(String) onSelected,
  }) async {
    // 在显示对话框前先取消焦点
    _amountFocusNode.unfocus();
    _payerFocusNode.unfocus();

    if (items.isEmpty) {
      showErrorToast('暂无数据可选择');
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              Container(
                height: 1,
                color: Colors.grey.shade100,
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            item['name'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF333333),
                            ),
                          ),
                          onTap: () {
                            onSelected(item['value'] ?? '');
                            Navigator.pop(context);
                          },
                        ),
                        if (index < items.length - 1)
                          Container(
                            height: 1,
                            color: Colors.grey.shade100,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // 获取校区名称
  String _getCampusName() {
    if (_selectedCampus == null) return '请选择';
    final campus = _campusList.firstWhere(
      (item) => item['value'] == _selectedCampus,
      orElse: () => {'name': '请选择', 'value': ''},
    );
    return campus['name'] ?? '请选择';
  }

  // 获取楼栋名称
  String _getBuildingName() {
    if (_selectedBuilding == null) return '请选择';
    final building = _buildingList.firstWhere(
      (item) => item['value'] == _selectedBuilding,
      orElse: () => {'name': '请选择', 'value': ''},
    );
    return building['name'] ?? '请选择';
  }

  // 获取楼层名称
  String _getFloorName() {
    if (_selectedFloor == null) return '请选择';
    final floor = _floorList.firstWhere(
      (item) => item['value'] == _selectedFloor,
      orElse: () => {'name': '请选择', 'value': ''},
    );
    return floor['name'] ?? '请选择';
  }

  // 获取房间名称
  String _getRoomName() {
    if (_selectedRoom == null) return '请选择';
    final room = _roomList.firstWhere(
      (item) => item['value'] == _selectedRoom,
      orElse: () => {'name': '请选择', 'value': ''},
    );
    return room['name'] ?? '请选择';
  }
}
