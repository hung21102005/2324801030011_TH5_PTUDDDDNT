import 'package:flutter_test/flutter_test.dart';
import 'package:ung_dung_ghi_chu_ca_nhan/main.dart';

void main() {
  testWidgets('PersonalNoteApp smoke test', (WidgetTester tester) async {
    // Xây dựng widget ứng dụng
    await tester.pumpWidget(const PersonalNoteApp());

    // Kiểm tra tiêu đề chính xuất hiện
    expect(find.text('Ghi chú cá nhân'), findsOneWidget);
  });
}
