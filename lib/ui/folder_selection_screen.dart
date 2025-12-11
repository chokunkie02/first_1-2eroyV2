import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/scan_history_service.dart';
import '../core/constants.dart';

class FolderSelectionScreen extends StatefulWidget {
  const FolderSelectionScreen({super.key});

  @override
  State<FolderSelectionScreen> createState() => _FolderSelectionScreenState();
}

class _FolderSelectionScreenState extends State<FolderSelectionScreen> {
  List<AssetPathEntity> _albums = [];
  Set<String> _selectedAlbumIds = {};
  bool _isLoading = true;
  bool _showAllFolders = false;
  final ScanHistoryService _historyService = ScanHistoryService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Load saved selection
    final savedIds = await _historyService.getSelectedAlbumIds();
    _selectedAlbumIds = savedIds.toSet();

    // 2. Request Permissions
    bool hasPermission = false;
    if (Platform.isLinux) {
      hasPermission = true; // Skip permission handler on Linux
    } else if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        hasPermission = photos.isGranted || videos.isGranted;
      } else {
        final storage = await Permission.storage.request();
        hasPermission = storage.isGranted;
      }
    } else {
      final photos = await Permission.photos.request();
      hasPermission = photos.isGranted || await Permission.photos.isLimited;
    }

    if (!hasPermission) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show dialog or just return
      }
      return;
    }

    // 3. Fetch Albums
    await PhotoManager.requestPermissionExtend();
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    
    // Sort alphabetically
    albums.sort((a, b) => a.name.compareTo(b.name));

    if (mounted) {
      setState(() {
        _albums = albums;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndExit() async {
    await _historyService.saveSelectedAlbumIds(_selectedAlbumIds.toList());
    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate saved
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Folders to Scan"),
        actions: [
          TextButton(
            onPressed: _saveAndExit,
            child: const Text("Save", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _getDisplayedAlbums().length,
                    itemBuilder: (context, index) {
                      final album = _getDisplayedAlbums()[index];
                      final isSelected = _selectedAlbumIds.contains(album.id);

                      return CheckboxListTile(
                        title: Text(album.name),
                        subtitle: FutureBuilder<int>(
                          future: album.assetCountAsync,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text("${snapshot.data} images");
                            }
                            return const Text("...");
                          },
                        ),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedAlbumIds.add(album.id);
                            } else {
                              _selectedAlbumIds.remove(album.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                // Toggle Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -2),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAllFolders = !_showAllFolders;
                      });
                    },
                    icon: Icon(_showAllFolders ? Icons.filter_list : Icons.folder_open),
                    label: Text(_showAllFolders ? "Show Only Bank Folders" : "Show All Folders"),
                  ),
                ),
              ],
            ),
    );
  }

  List<AssetPathEntity> _getDisplayedAlbums() {
    if (_showAllFolders) return _albums;
    
    return _albums.where((album) {
      final name = album.name.toLowerCase();
      return AppConstants.kBankFolderKeywords.any((keyword) => name.contains(keyword));
    }).toList();
  }
}
