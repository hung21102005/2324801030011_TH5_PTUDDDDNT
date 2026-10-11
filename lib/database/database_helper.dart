import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/note_model.dart';

/// Lớp quản lý cơ sở dữ liệu SQLite cục bộ (DatabaseHelper).
/// Áp dụng mô hình Singleton Pattern để đảm bảo chỉ có một kết nối Database duy nhất.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Tên file cơ sở dữ liệu và tên bảng
  static const String _dbName = 'personal_notes.db';
  static const String _tableName = 'notes';

  /// Khởi tạo và lấy đối tượng Database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  /// Khởi tạo cơ sở dữ liệu và xử lý tương thích đa nền tảng (Android, iOS, Windows, Linux, macOS)
  Future<Database> _initDB(String filePath) async {
    // Nếu ứng dụng đang chạy trên Windows hoặc Linux, khởi tạo bộ thư viện FFI để sqflite hoạt động mượt mà
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Lấy đường dẫn thư mục lưu trữ cơ sở dữ liệu của thiết bị
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Mở cơ sở dữ liệu và tạo bảng nếu chưa tồn tại
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Hàm tạo bảng dữ liệu khi mở database lần đầu tiên
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_locked INTEGER NOT NULL,
        pin_code TEXT
      )
    ''');
  }

  /// 1. Thêm mới một ghi chú vào SQLite (Create)
  /// Trả về id vừa được tạo tự động
  Future<int> insertNote(Note note) async {
    final db = await instance.database;
    return await db.insert(
      _tableName,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 2. Lấy toàn bộ danh sách ghi chú, có hỗ trợ tìm kiếm và sắp xếp mới nhất lên đầu (Read All)
  Future<List<Note>> getAllNotes({String? searchQuery, String? filterMode}) async {
    final db = await instance.database;

    // Sắp xếp theo ngày cập nhật mới nhất trước
    String orderBy = 'updated_at DESC';

    List<Map<String, dynamic>> results;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      // Tìm kiếm theo tiêu đề hoặc nội dung
      results = await db.query(
        _tableName,
        where: 'title LIKE ? OR content LIKE ?',
        whereArgs: [query, query],
        orderBy: orderBy,
      );
    } else if (filterMode == 'locked') {
      // Chỉ lấy ghi chú có mật khẩu
      results = await db.query(
        _tableName,
        where: 'is_locked = ?',
        whereArgs: [1],
        orderBy: orderBy,
      );
    } else if (filterMode == 'unlocked') {
      // Chỉ lấy ghi chú không có mật khẩu
      results = await db.query(
        _tableName,
        where: 'is_locked = ?',
        whereArgs: [0],
        orderBy: orderBy,
      );
    } else {
      // Lấy toàn bộ không lọc
      results = await db.query(_tableName, orderBy: orderBy);
    }

    return results.map((map) => Note.fromMap(map)).toList();
  }

  /// 3. Lấy thông tin một ghi chú theo ID (Read One)
  Future<Note?> getNoteById(int id) async {
    final db = await instance.database;
    final results = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return Note.fromMap(results.first);
    }
    return null;
  }

  /// 4. Cập nhật nội dung một ghi chú (Update)
  /// Trả về số dòng bị ảnh hưởng (1 nếu thành công)
  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return await db.update(
      _tableName,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// 5. Xóa vĩnh viễn một ghi chú theo ID (Delete)
  /// Trả về số dòng bị xóa (1 nếu thành công)
  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Đóng kết nối Database khi không cần thiết
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
