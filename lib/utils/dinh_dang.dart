import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _vnd = NumberFormat.decimalPattern('vi_VN');

/// 15000 -> "15.000 đ"
String tienViet(num so) => '${_vnd.format(so)} đ';

/// 1234 -> "1.234"
String soViet(num so) => _vnd.format(so);

/// Bỏ dấu chấm phân cách nghìn rồi đổi ra số nguyên.
int? docSo(String s) => int.tryParse(s.replaceAll('.', '').replaceAll(',', '').trim());

/// Bỏ dấu tiếng Việt để tìm kiếm "mi tom" vẫn ra "Mì tôm".
String khongDau(String s) {
  const nhom = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  final buf = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    var thay = ch;
    nhom.forEach((goc, dau) {
      if (dau.contains(ch)) thay = goc;
    });
    buf.write(thay);
  }
  return buf.toString();
}

/// Tự chèn dấu chấm nghìn khi gõ giá: 25000 -> 25.000
class NhapTienFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = _vnd.format(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
