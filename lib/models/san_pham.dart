import 'package:cloud_firestore/cloud_firestore.dart';

/// Một sản phẩm trong kho. Trên Firestore chỉ lưu đúng 4 trường
/// name, price, soluong, image theo yêu cầu đề. `id` là mã document,
/// không phải một trường dữ liệu.
class SanPham {
  final String id;
  final String name;
  final int price;
  final int soluong;

  /// Ảnh JPEG đã nén, mã hóa base64. Chuỗi rỗng nghĩa là chưa có ảnh.
  final String image;

  const SanPham({
    this.id = '',
    required this.name,
    required this.price,
    required this.soluong,
    this.image = '',
  });

  factory SanPham.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return SanPham(
      id: doc.id,
      name: (d['name'] ?? '').toString(),
      price: (d['price'] as num?)?.toInt() ?? 0,
      soluong: (d['soluong'] as num?)?.toInt() ?? 0,
      image: (d['image'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'soluong': soluong,
        'image': image,
      };

  int get thanhTien => price * soluong;
  bool get hetHang => soluong == 0;
  bool get sapHet => soluong > 0 && soluong <= 5;

  SanPham copyWith({String? name, int? price, int? soluong, String? image}) =>
      SanPham(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        soluong: soluong ?? this.soluong,
        image: image ?? this.image,
      );
}
