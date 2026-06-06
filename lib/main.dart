import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const FileLocatorApp());

class FileLocatorApp extends StatelessWidget {
  const FileLocatorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '文件快速定位', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true, brightness: Brightness.dark),
    home: const LocatorHomePage(),
  );
}

class FavoritePath {
  String id, name, path, icon;
  FavoritePath({required this.id, required this.name, required this.path, this.icon = '📁'});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'path': path, 'icon': icon};
  factory FavoritePath.fromJson(Map<String, dynamic> j) => FavoritePath(id: j['id'], name: j['name'], path: j['path'], icon: j['icon'] ?? '📁');
}

class LocatorHomePage extends StatefulWidget {
  const LocatorHomePage({super.key});
  @override
  State<LocatorHomePage> createState() => _LocatorHomePageState();
}

class _LocatorHomePageState extends State<LocatorHomePage> {
  List<FavoritePath> _favorites = [];
  String _currentPath = '~';
  List<String> _breadcrumb = ['~'];
  final _pathCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  final _mockDirs = {
    '~': ['Documents', 'Pictures', 'Music', 'Videos', 'Downloads', 'Desktop', 'Projects', 'Backups'],
    '~/Documents': ['工作', '个人', '学习', '报告.docx', '表格.xlsx'],
    '~/Documents/工作': ['项目计划.docx', '会议记录.docx', '数据.xlsx'],
    '~/Pictures': ['相册', '截图', '壁纸', '照片_2024.jpg'],
    '~/Music': ['流行', '古典', '录音', '歌曲.mp3'],
    '~/Downloads': ['软件安装包', '文件.zip', '图片.jpg'],
    '~/Projects': ['Flutter', 'Web', 'Python', 'README.md'],
    '~/Projects/Flutter': ['main.dart', 'pubspec.yaml', 'lib/', 'android/'],
  };

  final _dirIcons = {'Documents': '📄', 'Pictures': '🖼️', 'Music': '🎵', 'Videos': '🎬', 'Downloads': '⬇️', 'Desktop': '🖥️', 'Projects': '💻', 'Backups': '💾'};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('favorite_paths');
    if (d != null) setState(() => _favorites = (json.decode(d) as List).map((e) => FavoritePath.fromJson(e)).toList());
    else {
      _favorites = [
        FavoritePath(id: '1', name: '文档', path: '~/Documents', icon: '📄'),
        FavoritePath(id: '2', name: '下载', path: '~/Downloads', icon: '⬇️'),
        FavoritePath(id: '3', name: '项目', path: '~/Projects', icon: '💻'),
        FavoritePath(id: '4', name: '图片', path: '~/Pictures', icon: '🖼️'),
      ];
      _save();
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('favorite_paths', json.encode(_favorites.map((e) => e.toJson()).toList()));
  }

  void _navigate(String dir) {
    setState(() {
      _currentPath = _currentPath == '~' ? '~/$dir' : '$_currentPath/$dir';
      _breadcrumb.add(_currentPath);
    });
  }

  void _navigateTo(String path) {
    setState(() {
      _currentPath = path;
      _breadcrumb = ['~'];
      if (path != '~') {
        final parts = path.replaceFirst('~/', '').split('/');
        String built = '~';
        for (final p in parts) { built += '/$p'; _breadcrumb.add(built); }
      }
    });
  }

  void _goUp() {
    if (_currentPath == '~') return;
    final parts = _currentPath.split('/');
    parts.removeLast();
    final newPath = parts.join('/');
    _navigateTo(newPath.isEmpty ? '~' : newPath);
  }

  List<String> get _currentItems => _mockDirs[_currentPath] ?? [];

  void _addFavorite() {
    _pathCtrl.text = _currentPath;
    _nameCtrl.text = _currentPath.split('/').last;
    final icons = ['📁', '📄', '🖼️', '🎵', '🎬', '💻', '⬇️', '💾', '🖥️', '⚙️'];
    String selectedIcon = '📁';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('添加收藏'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '名称', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _pathCtrl, decoration: const InputDecoration(labelText: '路径', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: icons.map((ic) => GestureDetector(onTap: () => setS(() => selectedIcon = ic), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: selectedIcon == ic ? Colors.teal.withOpacity(0.2) : Colors.transparent, border: Border.all(color: selectedIcon == ic ? Colors.teal : Colors.transparent), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(ic, style: const TextStyle(fontSize: 20)))))).toList()),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () { setState(() => _favorites.add(FavoritePath(id: DateTime.now().millisecondsSinceEpoch.toString(), name: _nameCtrl.text, path: _pathCtrl.text, icon: selectedIcon))); _save(); Navigator.pop(ctx); }, child: const Text('添加')),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📂 文件快速定位'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.bookmark_add), onPressed: _addFavorite, tooltip: '收藏当前路径'),
      ]),
      body: Column(children: [
        // 收藏栏
        Container(height: 72, padding: const EdgeInsets.symmetric(vertical: 8), child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _favorites.length, itemBuilder: (ctx, i) {
          final f = _favorites[i];
          return GestureDetector(onLongPress: () => setState(() => _favorites.removeAt(i)), child: Padding(padding: const EdgeInsets.only(right: 12), child: Column(children: [Text(f.icon, style: const TextStyle(fontSize: 28)), Text(f.name, style: const TextStyle(fontSize: 11), maxLines: 1)]), onTap: () => _navigateTo(f.path)));
        })),
        const Divider(height: 1),
        // 路径面包屑
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back, size: 20), onPressed: _goUp, visualDensity: VisualDensity.compact),
          Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _breadcrumb.asMap().entries.map((e) => Row(children: [
            if (e.key > 0) const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_right, size: 16, color: Colors.grey)),
            GestureDetector(onTap: () => _navigateTo(e.value), child: Text(e.value == '~' ? '🏠 根目录' : e.value.split('/').last, style: TextStyle(fontSize: 13, color: _currentPath == e.value ? Theme.of(context).colorScheme.primary : null, fontWeight: _currentPath == e.value ? FontWeight.bold : null))),
          ])).toList()))),
          IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已复制: $_currentPath'), behavior: SnackBarBehavior.floating)), visualDensity: VisualDensity.compact),
        ])),
        const Divider(height: 1),
        // 文件列表
        Expanded(child: _currentItems.isEmpty ? const Center(child: Text('空文件夹', style: TextStyle(color: Colors.grey))) : ListView.builder(itemCount: _currentItems.length, itemBuilder: (ctx, i) {
          final item = _currentItems[i];
          final isDir = !item.contains('.');
          final icon = isDir ? (_dirIcons[item] ?? '📁') : (item.endsWith('.docx') ? '📄' : item.endsWith('.xlsx') ? '📊' : item.endsWith('.jpg') ? '🖼️' : item.endsWith('.mp3') ? '🎵' : item.endsWith('.zip') ? '📦' : item.endsWith('.dart') ? '💎' : '📄');
          return ListTile(leading: Text(icon, style: const TextStyle(fontSize: 24)), title: Text(item), trailing: isDir ? const Icon(Icons.chevron_right) : null, onTap: isDir ? () => _navigate(item) : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('打开: $_currentPath/$item'), behavior: SnackBarBehavior.floating)));
        })),
      ]),
    );
  }
}
