import 'package:flutter/material.dart';

import '../models/san_pham.dart';
import '../services/kho_service.dart';
import '../utils/dinh_dang.dart';
import '../widgets/anh_san_pham.dart';
import 'chi_tiet_screen.dart';
import 'form_san_pham_screen.dart';

enum SapXep { tenAZ, giaTang, giaGiam, tonItNhat }

const _tenSapXep = {
  SapXep.tenAZ: 'Tên A → Z',
  SapXep.giaTang: 'Giá thấp → cao',
  SapXep.giaGiam: 'Giá cao → thấp',
  SapXep.tonItNhat: 'Tồn kho ít nhất',
};

class DsSanPhamScreen extends StatefulWidget {
  const DsSanPhamScreen({super.key});

  @override
  State<DsSanPhamScreen> createState() => _DsSanPhamScreenState();
}

class _DsSanPhamScreenState extends State<DsSanPhamScreen> {
  final _svc = KhoService.instance;
  final _tim = TextEditingController();
  late final Stream<List<SanPham>> _stream = _svc.dsSanPham();
  SapXep _sapXep = SapXep.tenAZ;
  bool _chiSapHet = false;

  @override
  void dispose() {
    _tim.dispose();
    super.dispose();
  }

  List<SanPham> _locVaSapXep(List<SanPham> ds) {
    final tuKhoa = khongDau(_tim.text.trim());
    final kq = ds.where((sp) {
      if (_chiSapHet && sp.soluong > 5) return false;
      return tuKhoa.isEmpty || khongDau(sp.name).contains(tuKhoa);
    }).toList();
    switch (_sapXep) {
      case SapXep.tenAZ:
        kq.sort((a, b) => khongDau(a.name).compareTo(khongDau(b.name)));
      case SapXep.giaTang:
        kq.sort((a, b) => a.price.compareTo(b.price));
      case SapXep.giaGiam:
        kq.sort((a, b) => b.price.compareTo(a.price));
      case SapXep.tonItNhat:
        kq.sort((a, b) => a.soluong.compareTo(b.soluong));
    }
    return kq;
  }

  Future<void> _xoa(SanPham sp) async {
    final ok = await xacNhanXoa(context, sp);
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await _svc.xoa(sp.id);
    messenger.showSnackBar(SnackBar(
      content: Text('Đã xóa "${sp.name}"'),
      duration: const Duration(seconds: 5),
      persist: false, // co nut Hoan tac nhung van tu tat sau 5 giay
      action: SnackBarAction(label: 'Hoàn tác', onPressed: () => _svc.khoiPhuc(sp)),
    ));
  }

  Future<void> _dangXuat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: Text('Tài khoản: ${_svc.hienTai?.email ?? ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Ở lại')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    await _svc.dangXuat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kho Tạp Hóa', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('admin · huyln-23IT102', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                MediaQuery.sizeOf(context).width > 600 ? (_svc.hienTai?.email ?? '') : '',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: _dangXuat,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FormSanPhamScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm'),
      ),
      body: StreamBuilder<List<SanPham>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tatCa = snap.data!;
          final ds = _locVaSapXep(tatCa);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    sliver: SliverToBoxAdapter(child: _ThongKe(tatCa)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    sliver: SliverToBoxAdapter(child: _thanhCongCu(tatCa)),
                  ),
                  if (ds.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(tatCa.isEmpty
                            ? 'Kho đang trống. Bấm "Thêm sản phẩm" để nhập hàng.'
                            : 'Không có sản phẩm nào khớp.'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _TheSanPham(
                            sp: ds[i],
                            onXoa: () => _xoa(ds[i]),
                          ),
                          childCount: ds.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _thanhCongCu(List<SanPham> tatCa) {
    final soSapHet = tatCa.where((e) => e.soluong <= 5).length;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: _tim,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Tìm theo tên (gõ không dấu cũng được)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _tim.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(_tim.clear),
                    ),
            ),
          ),
        ),
        PopupMenuButton<SapXep>(
          tooltip: 'Sắp xếp',
          initialValue: _sapXep,
          onSelected: (v) => setState(() => _sapXep = v),
          itemBuilder: (_) => [
            for (final e in SapXep.values) PopupMenuItem(value: e, child: Text(_tenSapXep[e]!)),
          ],
          child: Chip(
            avatar: const Icon(Icons.sort, size: 18),
            label: Text(_tenSapXep[_sapXep]!),
          ),
        ),
        FilterChip(
          selected: _chiSapHet,
          onSelected: (v) => setState(() => _chiSapHet = v),
          avatar: _chiSapHet ? null : const Icon(Icons.warning_amber, size: 18),
          label: Text('Sắp hết hàng ($soSapHet)'),
        ),
      ],
    );
  }
}

class _ThongKe extends StatelessWidget {
  const _ThongKe(this.ds);
  final List<SanPham> ds;

  @override
  Widget build(BuildContext context) {
    final tongSoLuong = ds.fold<int>(0, (s, e) => s + e.soluong);
    final tongGiaTri = ds.fold<int>(0, (s, e) => s + e.thanhTien);
    Widget o(IconData icon, String nhan, String giaTri) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nhan, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(giaTri,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return Row(
      children: [
        o(Icons.category_outlined, 'Mặt hàng', soViet(ds.length)),
        o(Icons.inventory_outlined, 'Tổng tồn kho', soViet(tongSoLuong)),
        o(Icons.payments_outlined, 'Giá trị kho', tienViet(tongGiaTri)),
      ],
    );
  }
}

class _TheSanPham extends StatelessWidget {
  const _TheSanPham({required this.sp, required this.onXoa});
  final SanPham sp;
  final VoidCallback onXoa;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChiTietScreen(id: sp.id)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(tag: 'anh-${sp.id}', child: AnhSanPham(sp.image)),
                  Positioned(left: 6, top: 6, child: NhanTonKho(sp.soluong)),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: PopupMenuButton<String>(
                      icon: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white70,
                        child: Icon(Icons.more_vert, size: 18, color: Colors.black87),
                      ),
                      onSelected: (v) {
                        if (v == 'sua') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => FormSanPhamScreen(sanPham: sp)),
                          );
                        } else {
                          onXoa();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'sua',
                          child: ListTile(leading: Icon(Icons.edit), title: Text('Sửa')),
                        ),
                        PopupMenuItem(
                          value: 'xoa',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline, color: Colors.red),
                            title: Text('Xóa'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sp.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, height: 1.25)),
                  const SizedBox(height: 4),
                  Text(tienViet(sp.price),
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nhãn nhỏ góc ảnh: xanh = còn hàng, cam = sắp hết, đỏ = hết.
class NhanTonKho extends StatelessWidget {
  const NhanTonKho(this.soluong, {super.key});
  final int soluong;

  @override
  Widget build(BuildContext context) {
    final (mau, chu) = soluong == 0
        ? (Colors.red.shade600, 'Hết hàng')
        : soluong <= 5
            ? (Colors.orange.shade700, 'Còn $soluong')
            : (const Color(0xFF2F6B4F), 'SL: ${soViet(soluong)}');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: mau, borderRadius: BorderRadius.circular(20)),
      child: Text(chu,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

Future<bool> xacNhanXoa(BuildContext context, SanPham sp) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.delete_forever, color: Colors.red, size: 36),
      title: const Text('Xóa sản phẩm?'),
      content: Text('"${sp.name}" sẽ bị xóa khỏi kho. Ngay sau khi xóa vẫn có thể bấm Hoàn tác.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(c, true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  return ok == true;
}
