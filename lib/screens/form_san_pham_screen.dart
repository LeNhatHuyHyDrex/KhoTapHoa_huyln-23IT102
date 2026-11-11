import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/san_pham.dart';
import '../services/kho_service.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_san_pham.dart';

/// Dùng chung cho Thêm (sanPham == null) và Sửa.
class FormSanPhamScreen extends StatefulWidget {
  const FormSanPhamScreen({super.key, this.sanPham});
  final SanPham? sanPham;

  @override
  State<FormSanPhamScreen> createState() => _FormSanPhamScreenState();
}

class _FormSanPhamScreenState extends State<FormSanPhamScreen> {
  final _form = GlobalKey<FormState>();
  late final _ten = TextEditingController(text: widget.sanPham?.name ?? '');
  late final _gia = TextEditingController(
      text: widget.sanPham == null ? '' : soViet(widget.sanPham!.price));
  late final _soLuong = TextEditingController(text: widget.sanPham?.soluong.toString() ?? '');
  late String _anh = widget.sanPham?.image ?? '';
  bool _dangLuu = false;
  bool _daBamLuu = false;

  bool get _laSua => widget.sanPham != null;

  @override
  void dispose() {
    _ten.dispose();
    _gia.dispose();
    _soLuong.dispose();
    super.dispose();
  }

  Future<void> _chonAnh(ImageSource nguon) async {
    // Thu nhỏ ngay lúc chọn: cạnh dài tối đa 600px, JPEG 70%.
    // Ảnh còn khoảng 40-90 KB nên nhét vừa trong 1 document Firestore.
    final file = await ImagePicker().pickImage(
      source: nguon,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 70,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _anh = base64Encode(bytes));
  }

  void _moChonNguonAnh() {
    if (kIsWeb) {
      _chonAnh(ImageSource.gallery);
      return;
    }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Chụp bằng camera'),
              onTap: () {
                Navigator.pop(c);
                _chonAnh(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn trong thư viện ảnh'),
              onTap: () {
                Navigator.pop(c);
                _chonAnh(ImageSource.gallery);
              },
            ),
            if (_anh.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.hide_image_outlined, color: Colors.red),
                title: const Text('Bỏ ảnh hiện tại'),
                onTap: () {
                  Navigator.pop(c);
                  setState(() => _anh = '');
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _luu() async {
    setState(() => _daBamLuu = true);
    if (!_form.currentState!.validate()) return;
    setState(() => _dangLuu = true);
    final svc = KhoService.instance;
    final sp = SanPham(
      id: widget.sanPham?.id ?? '',
      name: _ten.text.trim(),
      price: docSo(_gia.text)!,
      soluong: docSo(_soLuong.text)!,
      image: _anh,
    );
    try {
      if (await svc.trungTen(sp.name, boQuaId: sp.id)) {
        if (!mounted) return;
        final vanLuu = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Trùng tên'),
            content: Text('Trong kho đã có "${sp.name}". Vẫn lưu thêm?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Thôi')),
              FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Vẫn lưu')),
            ],
          ),
        );
        if (vanLuu != true) {
          setState(() => _dangLuu = false);
          return;
        }
      }
      _laSua ? await svc.sua(sp) : await svc.them(sp);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_laSua ? 'Đã cập nhật "${sp.name}"' : 'Đã thêm "${sp.name}" vào kho'),
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangLuu = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lưu không được: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_laSua ? 'Sửa sản phẩm' : 'Thêm sản phẩm')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _form,
              // sau khi bam Luu lan dau, sua o nao thi bao loi o do ngay
              autovalidateMode: _daBamLuu ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Khung ảnh: bấm vào để chọn
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Material(
                      clipBehavior: Clip.antiAlias,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _moChonNguonAnh,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AnhSanPham(_anh, fit: BoxFit.contain, iconSize: 64),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: FilledButton.tonalIcon(
                                onPressed: _moChonNguonAnh,
                                icon: Icon(kIsWeb ? Icons.upload : Icons.add_a_photo_outlined),
                                label: Text(_anh.isEmpty ? 'Chọn ảnh' : 'Đổi ảnh'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_anh.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Ảnh đã nén: ${(base64Decode(_anh).length / 1024).toStringAsFixed(0)} KB',
                        style: TextStyle(fontSize: 12, color: scheme.outline),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ten,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm (name)',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Chưa nhập tên sản phẩm';
                      if (s.length > 80) return 'Tên dài quá (tối đa 80 ký tự)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _gia,
                          keyboardType: TextInputType.number,
                          inputFormatters: [NhapTienFormatter()],
                          decoration: const InputDecoration(
                            labelText: 'Giá (price)',
                            suffixText: 'đ',
                            prefixIcon: Icon(Icons.sell_outlined),
                          ),
                          validator: (v) {
                            final n = docSo(v ?? '');
                            if (n == null) return 'Chưa nhập giá';
                            if (n <= 0) return 'Giá phải lớn hơn 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _soLuong,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Số lượng (soluong)',
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          validator: (v) {
                            final n = docSo(v ?? '');
                            if (n == null) return 'Chưa nhập số lượng';
                            if (n > 100000) return 'Số lượng quá lớn';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _dangLuu ? null : _luu,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    icon: _dangLuu
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: Text(_laSua ? 'Lưu thay đổi' : 'Thêm vào kho'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
