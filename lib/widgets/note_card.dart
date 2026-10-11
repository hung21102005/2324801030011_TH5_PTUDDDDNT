import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import 'pin_dialog.dart';

/// Widget hiển thị một thẻ ghi chú cá nhân với giao diện Pastel hiện đại.
/// Hỗ trợ cả 2 chế độ hiển thị: Dạng Danh sách (List) và Dạng Lưới (Grid).
class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isGrid;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    this.isGrid = false,
  });

  /// Hàm định dạng ngày giờ thân thiện theo chuẩn đề bài
  String _formatDateTime(DateTime dateTime) {
    if (isGrid) {
      // Dạng lưới hiển thị ngắn gọn hơn để không bị tràn viền
      return DateFormat('dd/MM HH:mm').format(dateTime);
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  /// Hộp thoại xác nhận trước khi xóa ghi chú vĩnh viễn
  /// NẾU ghi chú có mã PIN -> Bắt buộc nhập đúng mã PIN trước mới cho phép xóa!
  Future<bool> _showConfirmDeleteDialog(BuildContext context) async {
    // 1. Kiểm tra nếu ghi chú có mã PIN bảo mật
    if (note.isLocked && note.pinCode != null && note.pinCode!.isNotEmpty) {
      final bool? pinVerified = await PinDialog.show(
        context,
        correctPin: note.pinCode!,
        title: 'Xác thực mã PIN để xóa',
        description: 'Ghi chú này đã được đặt mật khẩu. Vui lòng nhập đúng mã PIN để xác nhận quyền xóa.',
        confirmButtonText: 'Xác nhận mã PIN',
        icon: Icons.shield_rounded,
        iconColor: const Color(0xFFEF4444),
        iconBgColor: const Color(0xFFFEE2E2),
        confirmButtonColor: const Color(0xFFEF4444),
      );

      // Nếu người dùng không nhập đúng mã PIN hoặc ấn hủy -> Không cho xóa!
      if (pinVerified != true) {
        return false;
      }
    }

    // 2. Sau khi đã nhập đúng mã PIN (hoặc ghi chú không có khóa), hiện dialog xác nhận lần cuối
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 8),
              Text(
                'Xác nhận xóa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa ghi chú "${note.title.isNotEmpty ? note.title : 'Không có tiêu đề'}" này không?',
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Hủy',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Xóa vĩnh viễn',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Color(note.colorValue);

    // Nội dung thẻ ghi chú
    final cardContent = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          onLongPress: () async {
            final confirm = await _showConfirmDeleteDialog(context);
            if (confirm) {
              onDelete();
            }
          },
          child: Padding(
            padding: EdgeInsets.all(isGrid ? 12 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:
                  isGrid ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
              children: [
                // Khối thông tin phần trên (Tiêu đề, Khóa và Tóm tắt nội dung)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề & Icon Khóa bảo mật (nếu có)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isNotEmpty ? note.title : 'Ghi chú không tiêu đề',
                            style: TextStyle(
                              fontSize: isGrid ? 15 : 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                              height: 1.25,
                            ),
                            maxLines: isGrid ? 2 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (note.isLocked) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isGrid ? 6 : 8,
                              vertical: isGrid ? 3 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(isGrid ? 8 : 12),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  size: 13,
                                  color: Color(0xFFD97706),
                                ),
                                if (!isGrid) ...[
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Đã khóa',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: isGrid ? 6 : 10),

                    // Tóm tắt nội dung ghi chú (tối đa 2 dòng)
                    if (note.isLocked)
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: isGrid ? 13 : 16,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isGrid
                                  ? 'Nội dung đã bảo mật'
                                  : 'Nội dung đã được bảo mật bằng mã PIN',
                              style: TextStyle(
                                fontSize: isGrid ? 12 : 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        note.content.isNotEmpty
                            ? note.content
                            : 'Không có nội dung...',
                        style: TextStyle(
                          fontSize: isGrid ? 13 : 14,
                          color: const Color(0xFF475569),
                          height: 1.35,
                        ),
                        maxLines: isGrid ? 2 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),

                if (!isGrid) const SizedBox(height: 14),

                // Badge ngày giờ cập nhật & Nút xóa nhanh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Khung thời gian (Dùng Expanded và Flexible để đảm bảo không bao giờ bị overflow)
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isGrid ? 6 : 10,
                          vertical: isGrid ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.04),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: isGrid ? 11 : 13,
                              color: Colors.black.withValues(alpha: 0.55),
                            ),
                            SizedBox(width: isGrid ? 3 : 5),
                            Flexible(
                              child: Text(
                                _formatDateTime(note.updatedAt),
                                style: TextStyle(
                                  fontSize: isGrid ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black.withValues(alpha: 0.65),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: isGrid ? 4 : 8),

                    // Nút xóa nhanh
                    InkWell(
                      onTap: () async {
                        final confirm = await _showConfirmDeleteDialog(context);
                        if (confirm) {
                          onDelete();
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: isGrid ? 16 : 18,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Ở chế độ Grid, trả về trực tiếp cardContent không có padding ngoài hoặc Dismissible
    if (isGrid) {
      return cardContent;
    }

    // Ở chế độ Danh sách (List), bọc thêm Dismissible để hỗ trợ vuốt xóa
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('note_${note.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await _showConfirmDeleteDialog(context);
        },
        onDismissed: (direction) {
          onDelete();
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Xóa',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
            ],
          ),
        ),
        child: cardContent,
      ),
    );
  }
}
