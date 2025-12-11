import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/scan_history_service.dart';

class SmartImagePicker extends StatefulWidget {
  const SmartImagePicker({super.key});

  @override
  State<SmartImagePicker> createState() => _SmartImagePickerState();
}

class _SmartImagePickerState extends State<SmartImagePicker> {
  List<AssetPathEntity> _albums = [];
  List<AssetEntity> _assets = [];
  Set<String> _selectedAssetIds = {}; // Track selected IDs
  AssetPathEntity? _currentAlbum;
  bool _isLoading = true;
  final ScanHistoryService _historyService = ScanHistoryService();
  DateTime? _cutoffDate;

  @override
  void initState() {
    super.initState();
    _fetchAlbums();
  }

  Future<void> _fetchAlbums() async {
    // 1. Request Permissions (Strict Android 14 Logic)
    bool hasPermission = false;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request(); // Optional but good for completeness
        hasPermission = photos.isGranted || videos.isGranted;
      } else {
        // Android < 13
        final storage = await Permission.storage.request();
        hasPermission = storage.isGranted;
      }
    } else {
      // iOS
      final photos = await Permission.photos.request();
      hasPermission = photos.isGranted || await Permission.photos.isLimited;
    }

    if (!hasPermission) {
      // Handle permission denied
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Permission Denied"),
            content: const Text("Please grant photo access in Settings to scan slips."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
        );
      }
      return;
    }

    // 2. Get Albums
    await PhotoManager.requestPermissionExtend(); 
    
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    setState(() {
      _albums = albums;
      _isLoading = false;
      if (albums.isNotEmpty) {
        _currentAlbum = albums.first;
        _fetchAssets(_currentAlbum!);
      }
    });
  }

  Future<void> _fetchAssets(AssetPathEntity album) async {
    setState(() => _isLoading = true);
    
    // Get cutoff date for this album
    _cutoffDate = await _historyService.getCutoffDate(album.id);
    
    final assetCount = await album.assetCountAsync;
    // Fetch more for batch processing
    final assets = await album.getAssetListRange(
      start: 0,
      end: assetCount > 500 ? 500 : assetCount, 
    );

    setState(() {
      _assets = assets;
      _currentAlbum = album;
      _isLoading = false;
    });
  }

  Future<void> _finishSelection() async {
    List<File> selectedFiles = [];
    for (final asset in _assets) {
      if (_selectedAssetIds.contains(asset.id)) {
        final file = await asset.file;
        if (file != null) selectedFiles.add(file);
      }
    }
    if (mounted) {
      Navigator.pop(context, {
        'files': selectedFiles,
        'albumId': _currentAlbum?.id,
      });
    }
  }

  void _selectAllNew() {
    if (_cutoffDate == null) return;
    final newIds = _assets
        .where((a) => a.createDateTime.isAfter(_cutoffDate!))
        .map((a) => a.id)
        .toSet();
    
    setState(() {
      _selectedAssetIds.addAll(newIds);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Selected ${newIds.length} new images")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: DropdownButton<AssetPathEntity>(
          value: _currentAlbum,
          dropdownColor: Colors.white,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          items: _albums.map((album) {
            return DropdownMenuItem(
              value: album,
              child: Text(
                album.name,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (AssetPathEntity? newAlbum) {
            if (newAlbum != null) {
              _fetchAssets(newAlbum);
            }
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _selectAllNew,
            child: const Text("Select New"),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blue),
            onPressed: _selectedAssetIds.isNotEmpty ? _finishSelection : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
              ? const Center(child: Text("No images found in this album"))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    if (asset.type != AssetType.image) return const SizedBox();
                    
                    final isSelected = _selectedAssetIds.contains(asset.id);
                    final isNew = _cutoffDate != null && asset.createDateTime.isAfter(_cutoffDate!);

                    return FutureBuilder<File?>(
                      future: asset.file,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedAssetIds.remove(asset.id);
                                } else {
                                  _selectedAssetIds.add(asset.id);
                                }
                              });
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                ),
                                if (isSelected)
                                  Container(
                                    color: Colors.blue.withOpacity(0.4),
                                    child: const Center(
                                      child: Icon(Icons.check_circle, color: Colors.white, size: 32),
                                    ),
                                  ),
                                if (isNew && !isSelected)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text("NEW", style: TextStyle(color: Colors.white, fontSize: 10)),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }
                        return Container(color: Colors.grey);
                      },
                    );
                  },
                ),
      floatingActionButton: _selectedAssetIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _finishSelection,
              label: Text("Scan (${_selectedAssetIds.length})"),
              icon: const Icon(Icons.receipt_long),
            )
          : null,
    );
  }
}
