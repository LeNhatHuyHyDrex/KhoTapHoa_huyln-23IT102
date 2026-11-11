# Kho Tạp Hóa · huyln-23IT102

Bài giữa kỳ môn Lập trình đa nền tảng. App quản lý sản phẩm cho phân hệ admin của một tiệm tạp hóa nhỏ, viết bằng **Flutter**, dữ liệu nằm trên **Firebase Cloud Firestore**, đăng nhập bằng **Firebase Authentication**. Chạy được trên web và Android.

- Sinh viên: Lê Nhật Huy (huyln) - 23IT102
- Báo cáo: [`BaoCao_huyln-23IT102.docx`](BaoCao_huyln-23IT102.docx)
- Bản web: https://khotaphoa-huyln23it102.web.app
- File APK: [`release/KhoTapHoa_huyln-23IT102.apk`](release/KhoTapHoa_huyln-23IT102.apk)
- File CSDL xuất ra: [`database/sanpham.json`](database/sanpham.json)
- Video demo trên điện thoại: [`demo/demo_mobile_huyln-23IT102.mp4`](demo/demo_mobile_huyln-23IT102.mp4)

## CSDL

Collection `sanpham`, mỗi document đúng 4 trường, không thêm trường nào khác:

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `name` | string | tên sản phẩm |
| `price` | number | giá bán (VNĐ) |
| `soluong` | number (int) | số lượng tồn |
| `image` | string | ảnh JPEG đã thu nhỏ (≤600px), mã hóa base64 |

Ảnh lưu thẳng vào trường `image` dưới dạng base64 vì Firebase Storage giờ bắt buộc gói trả phí (Blaze). Ảnh được thu nhỏ còn khoảng 20–90 KB nên vừa trong giới hạn 1 MB của một document.

`firestore.rules` chặn ghi nếu chưa đăng nhập hoặc nếu document có trường lạ ngoài 4 trường trên.

## Tài khoản test

Xem `scripts/taikhoan_test.json` (tài khoản tạo riêng để chấm bài).

## Chức năng

- Đăng nhập / tạo tài khoản / quên mật khẩu / đăng xuất (Firebase Auth).
- Thêm, sửa, xóa sản phẩm. Xóa có hỏi lại và có nút **Hoàn tác** trong 5 giây.
- Danh sách cập nhật realtime, thẻ thống kê (số mặt hàng, tổng tồn, giá trị kho).
- Tìm theo tên (gõ không dấu vẫn ra), sắp xếp theo tên/giá/tồn kho, lọc hàng sắp hết (≤5).
- Màn chi tiết có nút +/− nhập xuất nhanh, dùng transaction để không bị âm.
- Chọn ảnh: web chọn file từ máy, điện thoại chụp camera hoặc lấy từ thư viện.
- Kiểm tra trùng tên, kiểm tra dữ liệu nhập, tự chèn dấu chấm nghìn khi gõ giá.

## Chạy lại

```bash
flutter pub get
flutter run -d chrome             # web
flutter run -d <id-dien-thoai>    # Android
flutter build web && firebase deploy --only hosting
flutter build apk --release
node scripts/seed.js              # tạo tài khoản test + dữ liệu mẫu
node scripts/export.js            # xuất Firestore -> database/sanpham.json
```

Ảnh mẫu trong `scripts/anh_mau/` lấy từ Wikimedia Commons.
