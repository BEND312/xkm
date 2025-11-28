import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/entity/apaertment/apartment_student_info.dart';
import 'package:swustmeow/entity/apaertment/electricity_bill.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/math.dart';
import 'package:swustmeow/utils/status.dart';
import 'package:swustmeow/utils/widget.dart';

import '../../services/boxes/apartment_box.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../utils/file.dart';

class ApartmentPage extends StatefulWidget {
  const ApartmentPage({super.key});

  @override
  State<StatefulWidget> createState() => _ApartmentPageState();
}

class _ApartmentPageState extends State<ApartmentPage> {
  bool _isLogin = false;
  bool _isLoading = true;
  ElectricityBill? _electricityBill;
  ApartmentStudentInfo? _studentInfo;
  String? _qrCodeUrl;
  Widget? _qrCode;
  List<Map<String, dynamic>> _images = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadImages();
  }

  Future<void> _load() async {
    if (GlobalService.apartmentService == null) return;
    _isLogin = GlobalService.apartmentService!.isLogin;
    if (!_isLogin) {
      _refresh(() => _isLoading = false);
      return;
    }

    await _loadElectricityBill();
    await _loadInfo().then((info) {
      if (info == null) return;

      _qrCodeUrl =
          'http://gydb.swust.edu.cn/AppApi/images/qrCode/${info.studentNumber}';
      _qrCode = _buildQRCode();
    });

    _refresh(() => _isLoading = false);
  }

  Future<void> _loadElectricityBill() async {
    final electricityBillResult =
        await GlobalService.apartmentService!.getElectricityBill();
    if (electricityBillResult.status == Status.ok) {
      _refresh(() =>
          _electricityBill = electricityBillResult.value as ElectricityBill);
    } else {
      showErrorToast('获取失败：${electricityBillResult.value}');
    }
  }

  Future<ApartmentStudentInfo?> _loadInfo() async {
    final cached = ApartmentBox.get('studentInfo') as ApartmentStudentInfo?;
    if (cached != null) {
      _refresh(() => _studentInfo = cached);
      return cached;
    }

    final result = await GlobalService.apartmentService!.getStudentInfo();
    if (result.status != Status.ok) {
      showErrorToast('获取信息失败：${result.value}');
      return null;
    }

    final info = result.value as ApartmentStudentInfo;
    _refresh(() => _studentInfo = info);
    return info;
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  Future<void> _refreshQRCode() async {
    _refresh(() => _qrCode = _buildQRCodeLoading());
    final bytes =
        (await NetworkAssetBundle(Uri.parse(_qrCodeUrl!)).load(_qrCodeUrl!))
            .buffer
            .asUint8List();
    _refresh(() => _qrCode = Image.memory(bytes));
  }

  Future<void> _loadImages() async {
    final savedImages = ApartmentBox.get<List>('apartmentImages');
    if (savedImages != null) {
      setState(() {
        _images = savedImages
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    }
  }

  Future<void> _saveImages() async {
    final List<Map<String, dynamic>> imagesToSave = _images
        .map((item) => {
              'fileName': item['fileName'] as String,
              'path': item['path'] as String,
              'addedAt': item['addedAt'] as String,
            })
        .toList();

    await ApartmentBox.put('apartmentImages', imagesToSave);
  }

  Future<void> _addImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    try {
      final fileName = 'apartment_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await image.readAsBytes();
      final file = await saveFileLocally(null, fileName, bytes);

      setState(() {
        _images.add({
          'fileName': fileName,
          'path': file.path,
          'addedAt': DateTime.now().toIso8601String(),
        });
      });

      await _saveImages();
      showSuccessToast('添加成功');
    } catch (e) {
      showErrorToast('添加失败：$e');
    }
  }

  Future<void> _deleteImage(int index) async {
    try {
      final image = _images[index];
      final file = File(image['path']);
      if (await file.exists()) {
        await file.delete();
      }

      setState(() {
        _images.removeAt(index);
      });

      await _saveImages();
      showSuccessToast('删除成功');
    } catch (e) {
      showErrorToast('删除失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(title: '宿舍事务'),
      content: _isLogin
          ? _buildContent()
          : Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '未登录公寓服务',
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
            Text(
              '请转到「设置」页面的「账号管理」选项进行登录',
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.normal),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shrinkWrap: true,
      children: joinGap(
        gap: 24,
        axis: Axis.vertical,
        widgets: [
          if (_electricityBill != null || _isLoading)
            Skeletonizer(
              enabled: _isLoading,
              child: _buildElectricityCard(),
            ),
          if (_studentInfo != null) _buildQRCodeCard(),
          _buildImagesCard(),
        ],
      ),
    );
  }

  Widget _buildElectricityCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: MTheme.primary2.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            SizedBox(width: 12),
            Text(
              '寝室电费',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '当前余额',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    '￥${_electricityBill?.remaining.intOrDouble}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: MTheme.primary2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '寝室房间：',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '${_electricityBill?.roomName}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: MTheme.primary2.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '个人二维码',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ),
            IconButton(
              onPressed: _refreshQRCode,
              icon: FaIcon(
                FontAwesomeIcons.rotateRight,
                size: 18,
                color: MTheme.primary2,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Text(
                '有效期三分钟',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _qrCode ?? _buildQRCodeLoading(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeLoading() {
    final size = MediaQuery.of(context).size;
    final dimension = size.width - 80;
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: MTheme.primary2,
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildQRCode() {
    return Image.network(
      _qrCodeUrl!,
      fit: BoxFit.fill,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return CircularProgressIndicator(color: MTheme.primary2);
      },
      errorBuilder: (context, child, err) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.circleExclamation,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                '加载失败',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagesCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: MTheme.primary2.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '自定义展示',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ),
            IconButton(
              onPressed: _addImage,
              icon: FaIcon(
                FontAwesomeIcons.plus,
                size: 18,
                color: MTheme.primary2,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (_images.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  FaIcon(
                    FontAwesomeIcons.images,
                    size: 48,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '暂无图片',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final image = _images[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Container(
                          color: Colors.white,
                          child: Image.file(
                            File(image['path']),
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Text(
                              DateTime.parse(image['addedAt'])
                                  .toLocal()
                                  .toString()
                                  .split('.')[0],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _deleteImage(index),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: FaIcon(
                                FontAwesomeIcons.xmark,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
