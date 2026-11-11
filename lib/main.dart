// Kho Tạp Hóa - bài giữa kỳ Lập trình đa nền tảng
// Lê Nhật Huy (huyln) - 23IT102
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'screens/dang_nhap_screen.dart';
import 'screens/ds_san_pham_screen.dart';
import 'services/kho_service.dart';

const mauChu = Color(0xFF2F6B4F); // xanh lá kiểu bảng hiệu tiệm tạp hóa

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('vi_VN');
  runApp(const KhoTapHoaApp());
}

class KhoTapHoaApp extends StatelessWidget {
  const KhoTapHoaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: mauChu, primary: mauChu);
    return MaterialApp(
      title: 'Kho Tạp Hóa · huyln-23IT102',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF6F4EE),
        appBarTheme: const AppBarTheme(
          backgroundColor: mauChu,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: KhoService.instance.nguoiDung,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snap.data == null ? const DangNhapScreen() : const DsSanPhamScreen();
        },
      ),
    );
  }
}
