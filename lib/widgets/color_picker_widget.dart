import 'package:flutter/material.dart';

/// Danh sách bảng màu pastel nhẹ nhàng, thanh lịch
const List<int> pastelColors = [
  0xFFFFF9E6, // Vàng bơ dịu (Butter Yellow)
  0xFFE8F5E9, // Xanh bạc hà (Mint Green)
  0xFFE3F2FD, // Xanh da trời nhạt (Soft Sky)
  0xFFF3E5F5, // Tím oải hương (Soft Lavender)
  0xFFFFEBEE, // Hồng phấn (Pastel Rose)
  0xFFFFF3E0, // Cam đào (Peach Cream)
  0xFFF1F5F9, // Xám khói sáng (Modern Slate)
];

/// Widget chọn màu sắc pastel cho thẻ ghi chú
class ColorPickerWidget extends StatelessWidget {
  final int selectedColor;
  final ValueChanged<int> onColorSelected;

  const ColorPickerWidget({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.palette_outlined, size: 18, color: Colors.black54),
              SizedBox(width: 6),
              Text(
                'Tông màu ghi chú:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: pastelColors.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final colorValue = pastelColors[index];
              final isSelected = colorValue == selectedColor;

              return GestureDetector(
                onTap: () => onColorSelected(colorValue),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 42 : 36,
                  height: isSelected ? 42 : 36,
                  decoration: BoxDecoration(
                    color: Color(colorValue),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black12,
                      width: isSelected ? 2.5 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? Colors.black.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
