import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Hiển thị ảnh lưu dạng base64 trong trường `image`.
/// Giải mã một lần rồi nhớ lại để cuộn danh sách không bị giật.
class AnhSanPham extends StatelessWidget {
  const AnhSanPham(this.base64, {super.key, this.fit = BoxFit.cover, this.iconSize = 40});

  final String base64;
  final BoxFit fit;
  final double iconSize;

  static final Map<int, Uint8List> _cache = {};

  static Uint8List? giaiMa(String b64) {
    if (b64.isEmpty) return null;
    final key = b64.hashCode ^ b64.length;
    return _cache.putIfAbsent(key, () {
      try {
        // Chấp nhận cả dạng "data:image/jpeg;base64,...."
        final i = b64.indexOf(',');
        return base64Decode(i >= 0 && b64.startsWith('data:') ? b64.substring(i + 1) : b64);
      } catch (_) {
        return Uint8List(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = giaiMa(base64);
    final scheme = Theme.of(context).colorScheme;
    if (bytes == null || bytes.isEmpty) {
      return Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.inventory_2_outlined, size: iconSize, color: scheme.outline),
      );
    }
    return Image.memory(bytes, fit: fit, gaplessPlayback: true);
  }
}
