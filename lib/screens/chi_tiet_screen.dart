import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/san_pham.dart';
import '../services/kho_service.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_san_pham.dart';
import 'ds_san_pham_screen.dart';
import 'form_san_pham_screen.dart';

/// Xem chi tiết một sản phẩm, nhập/xuất nhanh số lượng.
/// Nghe trực tiếp document nên sửa ở máy khác thì màn này cũng đổi theo.
class ChiTietScreen extends StatelessWidget {
  const ChiTietScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final svc = KhoService.instance;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('sanpham').doc(id).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.data!.exists) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Sản phẩm này đã bị xóa.')),
          );
        }
        final sp = SanPham.fromDoc(snap.data!);
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết sản phẩm'),
            actions: [
              IconButton(
                tooltip: 'Sửa',
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FormSanPhamScreen(sanPham: sp)),
                ),
              ),
              IconButton(
                tooltip: 'Xóa',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (!await xacNhanXoa(context, sp)) return;
                  await svc.xoa(sp.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // cao toi da ~45% man hinh de tren web khong phai cuon moi thay so luong
                    SizedBox(
                      height: (MediaQuery.sizeOf(context).height * 0.45).clamp(220.0, 420.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ColoredBox(
                          color: Colors.white,
                          child: Hero(
                            tag: 'anh-${sp.id}',
                            child: AnhSanPham(sp.image, fit: BoxFit.contain, iconSize: 80),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(sp.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(tienViet(sp.price),
                        style: TextStyle(
                            fontSize: 22, color: scheme.primary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Text('Tồn kho', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                NhanTonKho(sp.soluong),
                                const Spacer(),
                                IconButton.filledTonal(
                                  tooltip: 'Xuất 1',
                                  onPressed:
                                      sp.soluong == 0 ? null : () => svc.doiSoLuong(sp.id, -1),
                                  icon: const Icon(Icons.remove),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(soViet(sp.soluong),
                                      style: const TextStyle(
                                          fontSize: 22, fontWeight: FontWeight.w700)),
                                ),
                                IconButton.filled(
                                  tooltip: 'Nhập 1',
                                  onPressed: () => svc.doiSoLuong(sp.id, 1),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                const Text('Thành tiền tồn kho'),
                                const Spacer(),
                                Text(tienViet(sp.thanhTien),
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Mã document'),
                                const Spacer(),
                                SelectableText(sp.id,
                                    style: TextStyle(color: scheme.outline, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
