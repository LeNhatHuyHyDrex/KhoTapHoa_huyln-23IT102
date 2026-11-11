import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/san_pham.dart';

/// Gom hết phần nói chuyện với Firebase vào một chỗ cho màn hình gọn.
class KhoService {
  KhoService._();
  static final KhoService instance = KhoService._();

  final _auth = FirebaseAuth.instance;
  final _col = FirebaseFirestore.instance.collection('sanpham');

  // ---------------- Đăng nhập ----------------
  Stream<User?> get nguoiDung => _auth.authStateChanges();
  User? get hienTai => _auth.currentUser;

  Future<void> dangNhap(String email, String matKhau) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: matKhau);

  Future<void> taoTaiKhoan(String email, String matKhau) => _auth
      .createUserWithEmailAndPassword(email: email.trim(), password: matKhau);

  Future<void> guiEmailDatLaiMatKhau(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> dangXuat() => _auth.signOut();

  /// Đổi mã lỗi của Firebase Auth sang câu tiếng Việt dễ hiểu.
  static String loiDangNhap(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Email không đúng định dạng.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Sai email hoặc mật khẩu.';
        case 'email-already-in-use':
          return 'Email này đã có tài khoản.';
        case 'weak-password':
          return 'Mật khẩu yếu quá, cần ít nhất 6 ký tự.';
        case 'too-many-requests':
          return 'Thử sai nhiều lần, đợi một lát rồi thử lại.';
        case 'network-request-failed':
          return 'Không có mạng.';
      }
      return e.message ?? e.code;
    }
    return e.toString();
  }

  // ---------------- Sản phẩm ----------------
  Stream<List<SanPham>> dsSanPham() => _col.snapshots().map(
      (s) => s.docs.map(SanPham.fromDoc).toList(growable: false));

  Future<void> them(SanPham sp) => _col.add(sp.toMap());

  Future<void> sua(SanPham sp) => _col.doc(sp.id).set(sp.toMap());

  Future<void> xoa(String id) => _col.doc(id).delete();

  /// Ghi lại đúng document vừa xóa (dùng cho nút Hoàn tác).
  Future<void> khoiPhuc(SanPham sp) => _col.doc(sp.id).set(sp.toMap());

  /// Nhập thêm / xuất bớt hàng. Dùng transaction để hai máy bấm cùng lúc
  /// không ghi đè lên nhau và số lượng không bao giờ âm.
  Future<int> doiSoLuong(String id, int delta) {
    return FirebaseFirestore.instance.runTransaction((tx) async {
      final ref = _col.doc(id);
      final snap = await tx.get(ref);
      final cu = (snap.data()?['soluong'] as num?)?.toInt() ?? 0;
      final moi = (cu + delta) < 0 ? 0 : cu + delta;
      tx.update(ref, {'soluong': moi});
      return moi;
    });
  }

  /// Kiểm tra trùng tên (không phân biệt hoa thường), bỏ qua chính nó khi sửa.
  Future<bool> trungTen(String name, {String boQuaId = ''}) async {
    final key = name.trim().toLowerCase();
    final s = await _col.get();
    return s.docs.any((d) =>
        d.id != boQuaId &&
        (d.data()['name'] ?? '').toString().trim().toLowerCase() == key);
  }
}
