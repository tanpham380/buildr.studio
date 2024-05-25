import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:volta/models/tool.dart';
import 'package:volta/models/variable.dart';
import 'package:volta/repositories/tool_repository.dart';

import 'file_explorer_section.dart';
import 'output_section.dart';
import 'sidebar.dart';
import 'variable_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ToolRepository _toolRepository;
  List<Tool> _tools = [];
  Tool? _selectedTool;
  List<Variable> _variables = [];
  bool _isSidebarVisible = false;
  int _selectedNavRailIndex = 0;
  String? _selectedFolderPath;
  List<FileSystemEntity> _files = [];

  @override
  void initState() {
    super.initState();
    _toolRepository = GetIt.I.get<ToolRepository>();
    _loadTools();
  }

  Future<void> _loadTools() async {
    try {
      _tools = await _toolRepository.getTools();
      if (_tools.isNotEmpty) {
        _selectedTool = _tools.first;
        await _loadVariables(_selectedTool!.id);
      }
      setState(() {});
    } catch (e) {
      // Log the error or display it to the UI
      print('Error loading tools: $e');
    }
  }

  Future<void> _loadVariables(String toolId) async {
    try {
      _variables = await _toolRepository.getVariables(toolId);
      setState(() {});
    } catch (e) {
      // Log the error or display it to the US
      print('Error loading variables for tool $toolId: $e');
      _variables = [];
      setState(() {});
    }
  }

  Future<void> _loadFiles(String folderPath) async {
    try {
      final directory = Directory(folderPath);
      final files = await directory.list().toList();
      setState(() {
        _selectedFolderPath = folderPath;
        _files = files;
      });
    } catch (e) {
      // Log the error or display it to the UI
      print('Error loading files: $e');
    }
  }

  void _openFolder() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        initialDirectory: directory.path,
      );
      if (selectedDirectory != null) {
        await _loadFiles(selectedDirectory);
      }
    } catch (e) {
      // Log the error or display it to the UI
      print('Error selecting folder: $e');
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  void _onNavRailItemTapped(int index) {
    final isLargeScreen = MediaQuery.of(context).size.width >= 1024;
    setState(() {
      if (!isLargeScreen) {
        if (_selectedNavRailIndex == index) {
          _isSidebarVisible = !_isSidebarVisible;
        } else {
          _isSidebarVisible = true;
        }
      }
      _selectedNavRailIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NavigationRail(
            selectedIndex: _selectedNavRailIndex,
            onDestinationSelected: _onNavRailItemTapped,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.build),
                label: Text('Build'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder),
                label: Text('File Explorer'),
              ),
            ],
          ),
          if (isLargeScreen)
            Sidebar(
              onClose: _toggleSidebar,
              child: _selectedNavRailIndex == 0
                  ? ListView.builder(
                      itemCount: _tools.length,
                      itemBuilder: (context, index) {
                        final tool = _tools[index];
                        return ListTile(
                          title: Text(tool.name),
                          trailing: Tooltip(
                            message: tool.description,
                            child: const Icon(Icons.info_outline),
                          ),
                          selected: _selectedTool == tool,
                          onTap: () {
                            setState(() {
                              _selectedTool = tool;
                            });
                            _loadVariables(tool.id);
                          },
                        );
                      },
                    )
                  : FileExplorerSection(
                      selectedFolderPath: _selectedFolderPath,
                      files: _files,
                      onOpenFolder: _openFolder,
                    ),
            ),
          Expanded(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedTool != null)
                      VariableSection(
                        selectedTool: _selectedTool!,
                        variables: _variables,
                      ),
                    const OutputSection(),
                  ],
                ),
                if (!isLargeScreen && _isSidebarVisible)
                  Positioned(
                    top: 0,
                    left: 0,
                    bottom: 0,
                    child: Sidebar(
                      onClose: _toggleSidebar,
                      child: _selectedNavRailIndex == 0
                          ? ListView.builder(
                              itemCount: _tools.length,
                              itemBuilder: (context, index) {
                                final tool = _tools[index];
                                return ListTile(
                                  title: Text(tool.name),
                                  trailing: Tooltip(
                                    message: tool.description,
                                    child: const Icon(Icons.info_outline),
                                  ),
                                  selected: _selectedTool == tool,
                                  onTap: () {
                                    setState(() {
                                      _selectedTool = tool;
                                    });
                                    _loadVariables(tool.id);
                                  },
                                );
                              },
                            )
                          : FileExplorerSection(
                              selectedFolderPath: _selectedFolderPath,
                              files: _files,
                              onOpenFolder: _openFolder,
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
