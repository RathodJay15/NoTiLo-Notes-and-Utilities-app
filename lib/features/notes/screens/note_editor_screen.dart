import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/password_prompt_dialog.dart';
import '../controllers/note_page_controller.dart';
import '../widgets/collab_dialog.dart';

class NoteEditorScreen extends StatefulWidget {
  final DocumentSnapshot? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late NotePageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotePageController(widget.note);
    _controller.setStateCallback(setState);
    _controller.init();
    _controller.requestStoragePermission();
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<bool> _verifyPassword() async {
    return PasswordPromptDialog.show(
      context,
      expectedCustomPassword: _controller.customPassword,
    );
  }

  Future<void> _showPasswordOptionsDialog() async {
    final passwordController = TextEditingController();
    int selectedOption = 0;
    bool obscurePassword = true;

    final result = await showDialog<String?>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 500,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Set Password Protection',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RadioListTile<int>(
                      title: Text(
                        'Use login password',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      value: 0,
                      groupValue: selectedOption,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => selectedOption = val!),
                    ),
                    RadioListTile<int>(
                      title: Text(
                        'Set new password',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      value: 1,
                      groupValue: selectedOption,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => selectedOption = val!),
                    ),
                    if (selectedOption == 1) const SizedBox(height: 10),
                    if (selectedOption == 1)
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        style: GoogleFonts.poppins(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: GoogleFonts.poppins(
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.primary,
                            ),
                            onPressed: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                actionsPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.cancelGrey,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (selectedOption == 1) {
                        if (passwordController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password cannot be empty!'),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context, passwordController.text.trim());
                      } else {
                        Navigator.pop(context, '');
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Confirm',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      _controller.setPasswordProtection(result);
    }
  }

  Future<void> _showShareMenu() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Share Options',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download, color: AppColors.primary),
              title: Text('Export', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _exportNote();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.primary),
              title: Text('Share', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _shareNote();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportNote() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Export Note',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Choose a format to export your note.',
          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _controller.exportAsPDF(_showSnackBar);
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: Text('PDF', style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _controller.exportAsTXT(_showSnackBar);
            },
            icon: const Icon(Icons.description, color: Colors.white),
            label: Text('TXT', style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareNote() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Share Note',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Choose a format to share your note.',
          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _controller.shareAsPDF(_showSnackBar);
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: Text('PDF', style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _controller.shareAsTXT(_showSnackBar);
            },
            icon: const Icon(Icons.description, color: Colors.white),
            label: Text('TXT', style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote() async {
    if (widget.note != null) {
      final confirm = await AppDialog.showConfirmation(
        context,
        title: 'Confirm Delete',
        content: 'Do you want to delete this note?',
        positiveText: 'Yes',
        negativeText: 'No',
        positiveColor: AppColors.error,
      );

      if (confirm) {
        await _controller.deleteNote(context, _verifyPassword);
      }
    }
  }

  void _pickColor(bool isBackground) {
    final colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.brown,
      Colors.grey,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isBackground ? 'Pick Background Color' : 'Pick Text Color',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                _controller.applyColor(color, isBackground);
                Navigator.of(context).pop();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    Color? iconColor,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 26),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_controller.isEdited) {
      if (widget.note == null) {
        final shouldSave = await AppDialog.showConfirmation(
          context,
          title: 'Save Changes?',
          content: 'You have unsaved changes. Would you like to save before exiting?',
          positiveText: 'Save',
          negativeText: 'Discard',
          positiveColor: AppColors.primary,
        );

        if (shouldSave) {
          await _controller.saveNote(context);
          return false;
        }
      } else {
        await _controller.saveNote(context);
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.white),
          title: GestureDetector(
            onTap: () {
              if (!isEditing) return;
              _controller.startEditingAppBarTitle();
            },
            child: Text(
              isEditing
                  ? (_controller.titleController.text.isEmpty
                      ? 'Untitled'
                      : _controller.titleController.text)
                  : 'New Note',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {
                if (value == 'save') {
                  await _controller.saveNote(context);
                } else if (value == 'lock') {
                  if (_controller.isSecured) {
                    final verified = await _verifyPassword();
                    if (!verified) return;
                    _controller.removePasswordProtection();
                  } else {
                    await _showPasswordOptionsDialog();
                  }
                } else if (value == 'share') {
                  await _showShareMenu();
                } else if (value == 'collab') {
                  showDialog(
                    context: context,
                    builder: (context) => const CollabDialog(),
                  );
                } else if (value == 'delete') {
                  await _deleteNote();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'save',
                  child: Row(
                    children: [
                      const Icon(Icons.save, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text('Save', style: GoogleFonts.poppins()),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                if (isEditing)
                  PopupMenuItem(
                    value: 'lock',
                    child: Row(
                      children: [
                        Icon(
                          _controller.isSecured
                              ? Icons.lock
                              : Icons.lock_open,
                          color: _controller.isSecured
                              ? AppColors.lockAmber
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _controller.isSecured
                              ? 'Unlock Note'
                              : 'Lock Note',
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    ),
                  ),
                if (isEditing)
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        const Icon(Icons.share, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text('Share', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                if (isEditing)
                  PopupMenuItem(
                    value: 'collab',
                    child: Row(
                      children: [
                        const Icon(Icons.group, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text('Collab Note', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                if (isEditing) const PopupMenuDivider(),
                if (isEditing)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: AppColors.error),
                        const SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: GoogleFonts.poppins(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (_controller.isNewNote)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: TextField(
                      controller: _controller.titleController,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _controller.markEdited(),
                    ),
                  ),
                if (_controller.isNewNote)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Text',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                if (_controller.isEditingAppBarTitle && !_controller.isNewNote)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller.appBarTitleController,
                                autofocus: true,
                                style: GoogleFonts.poppins(color: Colors.black),
                                decoration: const InputDecoration(
                                  labelText: 'Title',
                                  labelStyle: TextStyle(color: AppColors.primary),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: AppColors.primary,
                              ),
                              onPressed: () => _controller.updateAppBarTitle(),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 12.0,
                      left: 12.0,
                      right: 12.0,
                      bottom: 0.0,
                    ),
                    child: quill.QuillEditor.basic(
                      controller: _controller.quillController,
                      focusNode: _controller.editorFocusNode,
                      scrollController: _controller.editorScrollController,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolbarButton(
                      Icons.format_bold,
                      'Bold',
                      () => _controller.toggleAttribute(quill.Attribute.bold),
                      isActive: _controller.isAttributeActive(
                        quill.Attribute.bold,
                      ),
                    ),
                    _buildToolbarButton(
                      Icons.format_italic,
                      'Italic',
                      () => _controller.toggleAttribute(quill.Attribute.italic),
                      isActive: _controller.isAttributeActive(
                        quill.Attribute.italic,
                      ),
                    ),
                    _buildToolbarButton(
                      Icons.format_underline,
                      'Underline',
                      () =>
                          _controller.toggleAttribute(quill.Attribute.underline),
                      isActive: _controller.isAttributeActive(
                        quill.Attribute.underline,
                      ),
                    ),
                    _buildToolbarButton(
                      Icons.format_color_text,
                      'Color',
                      () => _pickColor(false),
                      iconColor: _controller.selectedTextColor,
                    ),
                    _buildToolbarButton(
                      Icons.format_color_fill,
                      'Bg Color',
                      () => _pickColor(true),
                      iconColor: _controller.selectedBgColor == Colors.transparent
                          ? Colors.white
                          : _controller.selectedBgColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
