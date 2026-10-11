import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/note_model.dart';
import '../widgets/note_card.dart';
import '../widgets/pin_dialog.dart';
import '../widgets/search_bar_widget.dart';
import 'note_editor_screen.dart';

/// Màn hình chính của ứng dụng Ghi chú cá nhân (HomeScreen)
/// Quản lý danh sách ghi chú, tìm kiếm, lọc, mở khóa mã PIN và điều hướng tạo/sửa.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Note> _notes = [];
  bool _isLoading = true;
  String _currentFilter = 'all'; // 'all', 'locked', 'unlocked'
  bool _isGridView = false; // Chuyển đổi linh hoạt giữa Dạng Danh sách và Dạng Lưới

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Tải danh sách ghi chú từ SQLite với từ khóa tìm kiếm và bộ lọc hiện tại
  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await DatabaseHelper.instance.getAllNotes(
      searchQuery: _searchController.text,
      filterMode: _currentFilter,
    );
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  /// Xử lý sự kiện khi người dùng bấm vào một thẻ ghi chú:
  /// - Nếu ghi chú có mã PIN -> Hiện PinDialog yêu cầu nhập mã. Nhập đúng mới mở màn hình sửa.
  /// - Nếu không có mã PIN -> Mở thẳng màn hình sửa.
  Future<void> _handleNoteTap(Note note) async {
    if (note.isLocked && note.pinCode != null && note.pinCode!.isNotEmpty) {
      // Hiển thị hộp thoại nhập mã PIN
      final bool? isUnlocked = await PinDialog.show(
        context,
        correctPin: note.pinCode!,
      );

      // Nếu mở khóa thành công (isUnlocked == true), tiến hành chuyển sang màn hình chỉnh sửa
      if (isUnlocked == true && mounted) {
        _navigateToEditor(note);
      }
    } else {
      // Ghi chú không có mật khẩu, mở trực tiếp
      _navigateToEditor(note);
    }
  }

  /// Điều hướng sang màn hình thêm/sửa và tải lại danh sách sau khi quay về
  Future<void> _navigateToEditor([Note? note]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: note),
      ),
    );

    // Nếu có thao tác lưu/xóa (trả về true), cập nhật lại danh sách ngay lập tức
    if (result == true) {
      _loadNotes();
    }
  }

  /// Xóa ghi chú khỏi database và hiển thị thông báo
  Future<void> _deleteNote(Note note) async {
    if (note.id != null) {
      await DatabaseHelper.instance.deleteNote(note.id!);
      _loadNotes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa ghi chú "${note.title.isNotEmpty ? note.title : 'Ghi chú'}"'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Nền Slate nhạt cao cấp
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ghi chú cá nhân',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            Text(
              '${_notes.length} ghi chú${_currentFilter != 'all' ? ' (đang lọc)' : ''}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          // Nút chuyển đổi giao diện Danh sách / Lưới
          IconButton(
            tooltip: _isGridView ? 'Chuyển sang dạng Danh sách' : 'Chuyển sang dạng Lưới',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                _isGridView ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                color: const Color(0xFF334155),
                size: 20,
              ),
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Thanh tìm kiếm ghi chú
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SearchBarWidget(
                controller: _searchController,
                onChanged: (val) => _loadNotes(),
                onClear: () {
                  _searchController.clear();
                  _loadNotes();
                },
              ),
            ),

            // Dải Chip Lọc ghi chú: Tất cả / Đã khóa / Không khóa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Tất cả', Icons.list_alt_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('locked', 'Có mật khẩu', Icons.lock_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('unlocked', 'Không mật khẩu', Icons.lock_open_rounded),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Danh sách hiển thị ghi chú
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : _notes.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadNotes,
                          child: _isGridView ? _buildGridView() : _buildListView(),
                        ),
            ),
          ],
        ),
      ),

      // Nút FAB mở rộng (Extended Floating Action Button)
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToEditor(),
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 2,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            'Thêm ghi chú',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  /// Chip bộ lọc nhanh danh sách ghi chú
  Widget _buildFilterChip(String filterKey, String label, IconData icon) {
    final isSelected = _currentFilter == filterKey;
    final primaryColor = Theme.of(context).primaryColor;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : const Color(0xFF64748B),
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      backgroundColor: Colors.white,
      selectedColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onSelected: (selected) {
        setState(() {
          _currentFilter = filterKey;
        });
        _loadNotes();
      },
    );
  }

  /// Giao diện dạng Danh sách (ListView bo cong)
  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 90),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return NoteCard(
          note: note,
          onTap: () => _handleNoteTap(note),
          onDelete: () => _deleteNote(note),
        );
      },
    );
  }

  /// Giao diện dạng Lưới 2 cột (GridView)
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 90),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return NoteCard(
          note: note,
          isGrid: true,
          onTap: () => _handleNoteTap(note),
          onDelete: () => _deleteNote(note),
        );
      },
    );
  }

  /// Giao diện trạng thái rỗng khi chưa có ghi chú nào hoặc không tìm thấy
  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                isSearching ? Icons.search_off_rounded : Icons.note_alt_outlined,
                size: 56,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'Không tìm thấy ghi chú' : 'Chưa có ghi chú nào',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Hãy thử tìm kiếm với từ khóa khác nhé!'
                  : 'Hãy nhấn nút "Thêm ghi chú" bên dưới để bắt đầu lưu lại những ý tưởng tuyệt vời của bạn!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
