import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/profile.dart';
import '../state/app_state_scope.dart';
import '../widgets/avatar.dart';

/// Create a new profile (when [profile] is null) or edit an existing one.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.profile});

  final Profile? profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  String? _avatarPath;
  bool _saving = false;

  bool get _isEdit => widget.profile != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile?.name ?? '');
    _bio = TextEditingController(text: widget.profile?.bio ?? '');
    _avatarPath = widget.profile?.avatarPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 720,
      maxHeight: 720,
      imageQuality: 85,
    );
    if (img == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final avatars = Directory(p.join(dir.path, 'avatars'));
    if (!await avatars.exists()) await avatars.create(recursive: true);
    final dest = p.join(
      avatars.path,
      'av_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await File(img.path).copy(dest);

    if (!mounted) return;
    setState(() => _avatarPath = dest);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name likhun')),
      );
      return;
    }
    setState(() => _saving = true);
    final state = AppStateScope.read(context);

    if (_isEdit) {
      final updated = widget.profile!.copy()
        ..name = name
        ..bio = _bio.text.trim()
        ..avatarPath = _avatarPath;
      await state.updateProfile(updated);
    } else {
      final created = await state.createProfile(
        name: name,
        bio: _bio.text.trim(),
        avatarPath: _avatarPath,
      );
      await state.setActiveProfile(created.id);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: const Text('Delete profile?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Profile muche jabe. Video gulo abar For You te chole ashbe.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFFF2D78))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AppStateScope.read(context).deleteProfile(widget.profile!.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF2D78);
    return Scaffold(
      backgroundColor: const Color(0xFF111114),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111114),
        title: Text(_isEdit ? 'Edit profile' : 'New profile'),
        foregroundColor: Colors.white,
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save',
                    style: TextStyle(color: pink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  Avatar(path: _avatarPath, name: _name.text, size: 104, ring: true),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: pink, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _pickAvatar,
              child: const Text('Change photo',
                  style: TextStyle(color: pink, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          _field('Name', _name, 'Profile er naam'),
          const SizedBox(height: 14),
          _field('Bio', _bio, 'Kichu likhun...', maxLines: 4),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, String hint,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF1B1B21),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
