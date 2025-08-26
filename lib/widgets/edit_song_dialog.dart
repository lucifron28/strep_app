import 'package:flutter/material.dart';
import '../theme/dracula_theme.dart';
import '../models/song.dart';

class EditSongDialog extends StatefulWidget {
  final Song song;
  final Function(Song) onSave;

  const EditSongDialog({
    super.key,
    required this.song,
    required this.onSave,
  });

  @override
  State<EditSongDialog> createState() => _EditSongDialogState();
}

class _EditSongDialogState extends State<EditSongDialog> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _artistController = TextEditingController(text: widget.song.artist);
    _albumController = TextEditingController(text: widget.song.album);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DraculaTheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DraculaTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DraculaTheme.selection,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  Icons.edit,
                  color: DraculaTheme.purple,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Edit Song Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: DraculaTheme.foreground,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Song Title
                  _buildTextField(
                    controller: _titleController,
                    label: 'Song Title',
                    icon: Icons.music_note,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Song title cannot be empty';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Artist
                  _buildTextField(
                    controller: _artistController,
                    label: 'Artist',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Artist cannot be empty';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Album
                  _buildTextField(
                    controller: _albumController,
                    label: 'Album',
                    icon: Icons.album,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Album cannot be empty';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: DraculaTheme.comment,
                  ),
                  child: const Text('Cancel'),
                ),
                
                const SizedBox(width: 12),
                
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DraculaTheme.purple,
                    foregroundColor: DraculaTheme.background,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(color: DraculaTheme.foreground),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: DraculaTheme.comment),
        prefixIcon: Icon(icon, color: DraculaTheme.purple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DraculaTheme.selection),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DraculaTheme.selection),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DraculaTheme.purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DraculaTheme.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DraculaTheme.red, width: 2),
        ),
        filled: true,
        fillColor: DraculaTheme.currentLine,
        errorStyle: TextStyle(color: DraculaTheme.red),
      ),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // Create updated song with new details
      final updatedSong = widget.song.copyWith(
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        album: _albumController.text.trim(),
      );
      
      // Call the onSave callback
      widget.onSave(updatedSong);
      
      // Close the dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Song details updated successfully!',
            style: TextStyle(color: DraculaTheme.background),
          ),
          backgroundColor: DraculaTheme.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}
