import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:epubx/epubx.dart';
import 'dart:io';

void main() {
  runApp(const BookReaderApp());
}

class BookReaderApp extends StatelessWidget {
  const BookReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Книжный плеер',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Главный экран с кнопкой выбора книги
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _filePath;
  String _status = 'Выберите EPUB-файл';

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );
    

      if (result != null && result.files.single.path != null) {
        setState(() {
          _filePath = result.files.single.path;
          _status = 'Файл выбран: ${result.files.single.name}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Ошибка: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Книжный плеер')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Выбрать EPUB'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_filePath != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReaderScreen(filePath: _filePath!),
                    ),
                  );
                },
                icon: const Icon(Icons.book),
                label: const Text('Читать'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Экран читалки
class ReaderScreen extends StatefulWidget {
  final String filePath;

  const ReaderScreen({super.key, required this.filePath});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  EpubBook? _epubBook;
  List<String> _allText = [];
  String _title = 'Загрузка...';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final file = File(widget.filePath);
      final epubBook = await EpubReader.readBook(file.readAsBytesSync());

      final chapters = <String>[];

      // Собираем текст из всех глав
      for (var chapter in epubBook.Chapters ?? <EpubChapter>[]) {
        if (chapter.HtmlContent != null) {
          // Простое извлечение текста из HTML (без зависимостей)
          String plainText = _stripHtmlTags(chapter.HtmlContent!);
          if (plainText.isNotEmpty) {
            chapters.add(plainText);
          }
        }
      }

      setState(() {
        _epubBook = epubBook;
        _allText = chapters;
        _title = epubBook.Title ?? 'Без названия';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  // Простая функция удаления HTML-тегов
  String _stripHtmlTags(String html) {
    // Удаляем все HTML-теги
    final regex = RegExp(r'<[^>]*>');
    String text = html.replaceAll(regex, '');
    // Заменяем HTML-пробелы
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    // Убираем лишние пробелы и пустые строки
    text = text.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    return text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title, overflow: TextOverflow.ellipsis)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_allText.isEmpty) {
      return const Center(child: Text('Книга пуста или не содержит текста'));
    }

    // Пока просто скроллимый список глав
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allText.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок главы
              if (_epubBook?.Chapters?[index].Title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _epubBook!.Chapters![index].Title!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // Текст главы
              Text(
                _allText[index],
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const Divider(height: 30),
            ],
          ),
        );
      },
    );
  }
}
