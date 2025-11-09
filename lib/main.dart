import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:logging/logging.dart';
import 'databasehelper.dart';
import 'code_snippet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  
  bool isConnected = await DatabaseHelper.instance.isDatabaseConnected();
  Logger('main').info('Database connection status: ${isConnected ? 'Connected' : 'Not connected'}');
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _languageController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<CodeSnippet> _snippets = [];
  String _searchQuery = '';

  final List<String> _languages = [
    'python',
    'javascript',
    'dart',
    'java',
    'cpp',
    'csharp',
    'html',
    'css',
    'sql',
    'kotlin',
    'swift'
  ];

  @override
  void initState() {
    super.initState();
    _loadSnippets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _languageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSnippets() async {
    final snippets = await DatabaseHelper.instance.getAllSnippets();
    setState(() {
      _snippets = snippets;
    });
  }

  void _searchSnippets(String query) async {
    setState(() {
      _searchQuery = query;
    });
    
    if (query.isEmpty) {
      await _loadSnippets();
    } else {
      final results = await DatabaseHelper.instance.searchSnippets(query);
      if (mounted && _searchQuery == query) { // Only update if this is still the current query
        setState(() {
          _snippets = results;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Code Snippet Manager",
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Code Snippet Manager"),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Search Snippets'),
                    content: TextField(
                      onChanged: _searchSnippets,
                      decoration: const InputDecoration(
                        hintText: 'Enter search term...',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadSnippets();
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _languageController.text.isEmpty ? null : _languageController.text,
                      decoration: const InputDecoration(
                        labelText: 'Programming Language',
                        border: OutlineInputBorder(),
                      ),
                      items: _languages.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        _languageController.text = newValue ?? '';
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a language';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Code',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final snippet = CodeSnippet(
                            title: _titleController.text,
                            code: _codeController.text,
                            language: _languageController.text,
                            description: _descriptionController.text,
                          );
                          await DatabaseHelper.instance.insertSnippet(snippet);
                          await _loadSnippets();
                          
                          _titleController.clear();
                          _codeController.clear();
                          _languageController.clear();
                          _descriptionController.clear();
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code snippet saved!')),
                            );
                          }
                        }
                      },
                      child: const Text('Save Snippet'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _snippets.isEmpty
                  ? const Center(child: Text('No code snippets found'))
                  : ListView.builder(
                      itemCount: _snippets.length,
                      itemBuilder: (context, index) {
                        final snippet = _snippets[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              child: Text(
                                snippet.language.isNotEmpty 
                                  ? snippet.language[0].toUpperCase() 
                                  : '?'
                              ),
                            ),
                            title: Text(snippet.title),
                            subtitle: Text(snippet.description),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: HighlightView(
                                  snippet.code,
                                  language: snippet.language,
                                  theme: draculaTheme,
                                  padding: const EdgeInsets.all(12),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                              ),
                              ButtonBar(
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      await DatabaseHelper.instance.deleteSnippet(snippet.id!);
                                      await _loadSnippets();
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}