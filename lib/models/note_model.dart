import 'package:flutter/material.dart';

/// Lớp đại diện cho một ghi chú cá nhân (Note Model).
/// Chứa đầy đủ các thuộc tính và phương thức chuyển đổi dữ liệu với SQLite.
class Note {
  final int? id; // Khóa chính (Primary Key), tự tăng trong SQLite
  final String title; // Tiêu đề ghi chú
  final String content; // Nội dung ghi chú
  final DateTime createdAt; // Thời điểm tạo ghi chú
  final DateTime updatedAt; // Thời điểm cập nhật ghi chú gần nhất
  final int colorValue; // Mã màu nền (ARGB) để hiển thị thẻ ghi chú pastel
  final bool isLocked; // Trạng thái ghi chú có khóa bảo mật hay không
  final String? pinCode; // Mã PIN / Mật khẩu nếu có đặt khóa

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.colorValue = 0xFFFFF8E7, // Màu pastel mặc định (vàng bơ nhạt)
    this.isLocked = false,
    this.pinCode,
  });

  /// Chuyển đổi đối tượng Note thành `Map<String, dynamic>` để lưu vào cơ sở dữ liệu SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'color_value': colorValue,
      'is_locked': isLocked ? 1 : 0, // SQLite lưu bool dạng 0 hoặc 1
      'pin_code': pinCode,
    };
  }

  /// Tạo đối tượng Note từ `Map<String, dynamic>` truy vấn từ SQLite
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
      colorValue: map['color_value'] as int? ?? 0xFFFFF8E7,
      isLocked: (map['is_locked'] as int? ?? 0) == 1,
      pinCode: map['pin_code'] as String?,
    );
  }

  /// Tạo bản sao có cập nhật các trường nhất định (hỗ trợ tính bất biến Immutability)
  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? colorValue,
    bool? isLocked,
    String? pinCode,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      colorValue: colorValue ?? this.colorValue,
      isLocked: isLocked ?? this.isLocked,
      pinCode: pinCode ?? this.pinCode,
    );
  }

  /// Thuộc tính tiện ích lấy màu Color từ int colorValue
  Color get color => Color(colorValue);
}
