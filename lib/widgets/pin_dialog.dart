import 'package:flutter/material.dart';

/// Hộp thoại xác thực mã PIN / Mật khẩu khi mở hoặc xóa ghi chú được khóa.
/// Trả về `true` nếu người dùng nhập đúng mật khẩu, ngược lại trả về `false` hoặc `null`.
class PinDialog extends StatefulWidget {
  final String correctPin;
  final String title;
  final String description;
  final String confirmButtonText;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color? confirmButtonColor;

  const PinDialog({
    super.key,
    required this.correctPin,
    this.title = 'Ghi chú được bảo vệ',
    this.description = 'Vui lòng nhập mã PIN của bạn để mở khóa và xem nội dung ghi chú này.',
    this.confirmButtonText = 'Mở khóa',
    this.icon = Icons.lock_rounded,
    this.iconColor = const Color(0xFFD97706),
    this.iconBgColor = const Color(0xFFFEF3C7),
    this.confirmButtonColor,
  });

  /// Phương thức tĩnh hiển thị Dialog tiện lợi
  static Future<bool?> show(
    BuildContext context, {
    required String correctPin,
    String title = 'Ghi chú được bảo vệ',
    String description = 'Vui lòng nhập mã PIN của bạn để mở khóa và xem nội dung ghi chú này.',
    String confirmButtonText = 'Mở khóa',
    IconData icon = Icons.lock_rounded,
    Color iconColor = const Color(0xFFD97706),
    Color iconBgColor = const Color(0xFFFEF3C7),
    Color? confirmButtonColor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PinDialog(
        correctPin: correctPin,
        title: title,
        description: description,
        confirmButtonText: confirmButtonText,
        icon: icon,
        iconColor: iconColor,
        iconBgColor: iconBgColor,
        confirmButtonColor: confirmButtonColor,
      ),
    );
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _obscureText = true;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  /// Kiểm tra mã PIN khi người dùng bấm xác nhận
  void _verifyPin() {
    final enteredPin = _pinController.text.trim();
    if (enteredPin == widget.correctPin) {
      // Đúng mã PIN: Đóng dialog và trả về true
      Navigator.of(context).pop(true);
    } else {
      // Sai mã PIN: Cập nhật giao diện thông báo lỗi màu đỏ
      setState(() {
        _errorMessage = 'Mã PIN không chính xác! Vui lòng thử lại.';
      });
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryBtnColor = widget.confirmButtonColor ?? Theme.of(context).primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon bảo mật với vòng tròn viền nổi bật
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.iconBgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.iconColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                size: 36,
                color: widget.iconColor,
              ),
            ),
            const SizedBox(height: 18),

            // Tiêu đề
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),

            // Mô tả
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Ô nhập mã PIN
            TextField(
              controller: _pinController,
              autofocus: true,
              obscureText: _obscureText,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Nhập mã PIN...',
                hintStyle: const TextStyle(
                  letterSpacing: 0,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.black38,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _errorMessage != null ? Colors.red : Colors.black12,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _errorMessage != null
                        ? Colors.red
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _errorMessage != null
                        ? Colors.red
                        : primaryBtnColor,
                    width: 2,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
              onSubmitted: (_) => _verifyPin(),
            ),

            // Hiển thị thông báo lỗi màu đỏ nếu nhập sai
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Hàng nút thao tác Hủy và Xác nhận
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: const Text(
                      'Hủy bỏ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _verifyPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBtnColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      widget.confirmButtonText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
