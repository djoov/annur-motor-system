import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';

/// Standard add/edit page: title, optional delete action in the app bar,
/// centered scrollable fields and a sticky save button.
class AppFormScaffold extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final String saveLabel;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  final String deleteTooltip;

  const AppFormScaffold({
    super.key,
    required this.title,
    required this.formKey,
    required this.children,
    required this.saveLabel,
    required this.isSaving,
    required this.onSave,
    this.onDelete,
    this.deleteTooltip = "Hapus",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onDelete != null)
            IconButton(
              tooltip: deleteTooltip,
              icon: const Icon(LucideIcons.trash2,
                  color: AppColors.destructiveStrong),
              onPressed: isSaving ? null : onDelete,
            ),
        ],
      ),
      body: Form(
        key: formKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: children,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.save, size: 20),
            label: Text(isSaving ? "Menyimpan..." : saveLabel),
          ),
        ),
      ),
    );
  }
}

/// Red-confirm dialog for destructive actions. Returns true when confirmed.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String action = "Hapus",
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Batal"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Floating error snackbar.
void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.destructiveStrong,
    ),
  );
}
