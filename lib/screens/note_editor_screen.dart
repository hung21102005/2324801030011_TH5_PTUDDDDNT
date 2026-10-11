import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/note_model.dart';
import '../widgets/color_picker_widget.dart';
import '../widgets/pin_dialog.dart';

/// Màn hình Tạo mới & Chỉnh sửa ghi chú (NoteEditorScreen)
/// Phục vụ cả 2 luồng: Thêm ghi chú mới (note == null) hoặc Chỉnh sửa ghi chú hiện có (note != null).
class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _pinController;

  late int _selectedColor;
  late bool _isLocked;
  bool _obscurePin = true;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    final note = widget.note;

    // Khởi tạo các giá trị ban đầu (nếu là chỉnh sửa thì nạp dữ liệu cũ)
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _pinController = TextEditingController(text: note?.pinCode ?? '');

    _selectedColor = note?.colorValue ?? pastelColors.first;
    _isLocked = note?.isLocked ?? false;

    // Lắng nghe sự thay đổi để cảnh báo khi thoát chưa lưu
    _titleController.addListener(_markChanged);
    _contentController.addListener(_markChanged);
    _pinController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasChanged) {
      setState(() {
        _hasChanged = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  /// Định dạng ngày giờ hiển thị
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  /// Lưu ghi chú vào SQLite Database
  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final pin = _pinController.text.trim();

    // Kiểm tra dữ liệu: Phải có ít nhất tiêu đề hoặc nội dung
    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập ít nhất tiêu đề hoặc nội dung ghi chú!'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Kiểm tra nếu bật khóa thì bắt buộc phải nhập mã PIN
    if (_isLocked && pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mã PIN bảo mật cho ghi chú!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final now = DateTime.now();

    if (widget.note == null) {
      // 1. Thêm ghi chú mới vào Database
      final newNote = Note(
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        colorValue: _selectedColor,
        isLocked: _isLocked,
        pinCode: _isLocked ? pin : null,
      );
      await DatabaseHelper.instance.insertNote(newNote);
    } else {
      // 2. Cập nhật ghi chú hiện có vào Database
      final updatedNote = widget.note!.copyWith(
        title: title,
        content: content,
        updatedAt: now,
        colorValue: _selectedColor,
        isLocked: _isLocked,
        pinCode: _isLocked ? pin : null,
      );
      await DatabaseHelper.instance.updateNote(updatedNote);
    }

    if (!mounted) return;

    // Hiển thị thông báo thành công
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(widget.note == null
                ? 'Đã thêm ghi chú mới thành công!'
                : 'Đã lưu thay đổi ghi chú!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    // Trả về true để màn hình chính cập nhật lại danh sách ngay lập tức
    Navigator.of(context).pop(true);
  }

  /// Xác nhận xóa ghi chú khi đang mở ở chế độ chỉnh sửa
  Future<void> _deleteCurrentNote() async {
    if (widget.note?.id == null) return;

    // Nếu ghi chú có mã PIN bảo mật -> Yêu cầu nhập đúng mã PIN trước!
    if (widget.note!.isLocked &&
        widget.note!.pinCode != null &&
        widget.note!.pinCode!.isNotEmpty) {
      final bool? pinVerified = await PinDialog.show(
        context,
        correctPin: widget.note!.pinCode!,
        title: 'Xác thực mã PIN để xóa',
        description: 'Ghi chú này đã được đặt mật khẩu. Vui lòng nhập đúng mã PIN để xác nhận quyền xóa.',
        confirmButtonText: 'Xác nhận mã PIN',
        icon: Icons.shield_rounded,
        iconColor: const Color(0xFFEF4444),
        iconBgColor: const Color(0xFFFEE2E2),
        confirmButtonColor: const Color(0xFFEF4444),
      );

      // Nếu người dùng không nhập đúng mã PIN hoặc ấn hủy -> Không xóa
      if (pinVerified != true) {
        return;
      }
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn xóa ghi chú này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await DatabaseHelper.instance.deleteNote(widget.note!.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa ghi chú thành công!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    final primaryColor = Theme.of(context).primaryColor;

    return PopScope(
      canPop: !_hasChanged,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Hỏi người dùng trước khi thoát nếu có thay đổi chưa lưu
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Chưa lưu thay đổi'),
            content: const Text('Bạn có thay đổi chưa lưu. Bạn có chắc muốn thoát không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Ở lại'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Rời khỏi'),
              ),
            ],
          ),
        );

        if (shouldLeave == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Color(_selectedColor),
        appBar: AppBar(
          backgroundColor: Color(_selectedColor),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            isEditing ? 'Chỉnh sửa ghi chú' : 'Thêm ghi chú mới',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19,
              color: Color(0xFF1E293B),
            ),
          ),
          actions: [
            // Nút xóa (chỉ hiện khi đang chỉnh sửa)
            if (isEditing)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
                tooltip: 'Xóa ghi chú',
                onPressed: _deleteCurrentNote,
              ),

            // Nút Lưu ghi chú nổi bật
            Padding(
              padding: const EdgeInsets.only(right: 14, left: 4),
              child: ElevatedButton.icon(
                onPressed: _saveNote,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text(
                  'Lưu',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            physics: const BouncingScrollPhysics(),
            children: [
              // Thông tin thời gian tạo/cập nhật
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.note != null
                              ? 'Cập nhật: ${_formatDateTime(widget.note!.updatedAt)}'
                              : 'Hôm nay: ${_formatDateTime(DateTime.now())}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Trường nhập Tiêu đề
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                decoration: const InputDecoration(
                  hintText: 'Tiêu đề ghi chú...',
                  hintStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 14),

              // Bảng chọn màu sắc pastel
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: ColorPickerWidget(
                  selectedColor: _selectedColor,
                  onColorSelected: (color) {
                    setState(() {
                      _selectedColor = color;
                      _hasChanged = true;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Thẻ cài đặt Bảo mật / Khóa mã PIN
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isLocked
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.06),
                    width: _isLocked ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _isLocked,
                      activeThumbColor: const Color(0xFFD97706),
                      activeTrackColor: const Color(0xFFFEF3C7),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: const Row(
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF1E293B)),
                          SizedBox(width: 8),
                          Text(
                            'Khóa bằng mã PIN / Mật khẩu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        _isLocked
                            ? 'Ghi chú sẽ yêu cầu nhập mã PIN khi mở'
                            : 'Bật để bảo vệ quyền riêng tư cho ghi chú này',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isLocked ? const Color(0xFFD97706) : const Color(0xFF64748B),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isLocked = value;
                          _hasChanged = true;
                        });
                      },
                    ),

                    // Khung nhập mã PIN (hiện ra mượt mà khi switch được bật)
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _pinController,
                              obscureText: _obscurePin,
                              keyboardType: TextInputType.text,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.pin_rounded,
                                  color: Color(0xFFD97706),
                                  size: 22,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePin
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePin = !_obscurePin;
                                    });
                                  },
                                ),
                                labelText: 'Mã PIN bảo mật',
                                labelStyle: const TextStyle(
                                  letterSpacing: 0,
                                  fontSize: 14,
                                  color: Color(0xFFD97706),
                                ),
                                hintText: 'Nhập mã PIN hoặc mật khẩu...',
                                hintStyle: const TextStyle(
                                  letterSpacing: 0,
                                  fontSize: 14,
                                  color: Colors.black26,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFFFBEB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFFDE68A)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFFDE68A)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD97706),
                                    width: 1.8,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      crossFadeState: _isLocked
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Đường phân cách mờ thanh lịch
              Divider(
                color: Colors.black.withValues(alpha: 0.08),
                height: 1,
              ),
              const SizedBox(height: 12),

              // Trường nhập Nội dung ghi chú (Multiline)
              TextField(
                controller: _contentController,
                maxLines: null,
                minLines: 12,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF334155),
                ),
                decoration: const InputDecoration(
                  hintText: 'Bắt đầu viết nội dung ghi chú ở đây...',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
