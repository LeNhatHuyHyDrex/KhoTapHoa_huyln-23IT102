import 'package:flutter/material.dart';

import '../services/kho_service.dart';

class DangNhapScreen extends StatefulWidget {
  const DangNhapScreen({super.key});

  @override
  State<DangNhapScreen> createState() => _DangNhapScreenState();
}

class _DangNhapScreenState extends State<DangNhapScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _matKhau = TextEditingController();
  final _nhapLai = TextEditingController();
  bool _anMatKhau = true;
  bool _cheDoDangKy = false;
  bool _dangXuLy = false;
  String? _loi;

  @override
  void dispose() {
    _email.dispose();
    _matKhau.dispose();
    _nhapLai.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _dangXuLy = true;
      _loi = null;
    });
    try {
      if (_cheDoDangKy) {
        await KhoService.instance.taoTaiKhoan(_email.text, _matKhau.text);
      } else {
        await KhoService.instance.dangNhap(_email.text, _matKhau.text);
      }
    } catch (e) {
      setState(() => _loi = KhoService.loiDangNhap(e));
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  Future<void> _quenMatKhau() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _loi = 'Nhập email trước rồi bấm "Quên mật khẩu".');
      return;
    }
    try {
      await KhoService.instance.guiEmailDatLaiMatKhau(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi link đặt lại mật khẩu tới $email')),
      );
    } catch (e) {
      setState(() => _loi = KhoService.loiDangNhap(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.storefront, color: Colors.white, size: 40),
                    ),
                  ),
                  Text('Kho Tạp Hóa',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700, color: scheme.primary)),
                  const SizedBox(height: 4),
                  Text(
                    _cheDoDangKy ? 'Tạo tài khoản quản trị mới' : 'Đăng nhập phân hệ admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Chưa nhập email';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _matKhau,
                    obscureText: _anMatKhau,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _anMatKhau ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                        icon: Icon(_anMatKhau ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _anMatKhau = !_anMatKhau),
                      ),
                    ),
                    onFieldSubmitted: (_) => _cheDoDangKy ? null : _gui(),
                    validator: (v) =>
                        (v ?? '').length < 6 ? 'Mật khẩu ít nhất 6 ký tự' : null,
                  ),
                  if (_cheDoDangKy) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nhapLai,
                      obscureText: _anMatKhau,
                      decoration: const InputDecoration(
                        labelText: 'Nhập lại mật khẩu',
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                      validator: (v) => v != _matKhau.text ? 'Hai mật khẩu chưa khớp' : null,
                    ),
                  ],
                  if (_loi != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_loi!, style: TextStyle(color: scheme.onErrorContainer)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _dangXuLy ? null : _gui,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: _dangXuLy
                        ? const SizedBox(
                            width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_cheDoDangKy ? 'Tạo tài khoản' : 'Đăng nhập'),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => setState(() {
                          _cheDoDangKy = !_cheDoDangKy;
                          _loi = null;
                        }),
                        child: Text(_cheDoDangKy ? 'Đã có tài khoản' : 'Tạo tài khoản'),
                      ),
                      if (!_cheDoDangKy)
                        TextButton(onPressed: _quenMatKhau, child: const Text('Quên mật khẩu?')),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('Lê Nhật Huy · huyln-23IT102',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.outline, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
