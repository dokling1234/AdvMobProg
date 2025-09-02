import 'package:flutter/material.dart';
import 'package:golosinda_advmobprog/services/article_service.dart';
import 'package:golosinda_advmobprog/models/article_model.dart';
import '../widgets/custom_text.dart';

class AddArticleForm extends StatefulWidget {
  final Function(Article) onArticleAdded;

  const AddArticleForm({super.key, required this.onArticleAdded});

  @override
  State<AddArticleForm> createState() => _AddArticleFormState();
}

class _AddArticleFormState extends State<AddArticleForm> {
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final contentController = TextEditingController();
  bool isSaving = false;
  bool isActive = true;
  final formKey = GlobalKey<FormState>();

  // Convert raw content text into a list of strings
  List<String> _toList(String raw) {
    return raw.split(RegExp(r'[\n,]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  Future<void> save() async {
    if (isSaving) return;
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
    });

    try {
      final payload = {
        'title': titleController.text.trim(),
        'name': authorController.text.trim(),
        'content': _toList(contentController.text),
        'isActive': isActive,
      };

      final Map res = await ArticleService().createArticle(payload);

      final created = (res['article'] ?? res);
      final newArticle = Article.fromJson(created);

      widget.onArticleAdded(newArticle); // Notify the parent widget

      // Close the dialog after saving
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Article added. ✅')));
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add. ❌')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: authorController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Author / Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: contentController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Content (one item per line or comma-separated)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null) return 'At least one content item';
                final items = v.trim().split(RegExp(r'[\n,]')).where((s) => s.trim().isNotEmpty).toList();
                return items.isEmpty ? 'At least one content item' : null;
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: isActive,
              onChanged: (val) => setState(() => isActive = val),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isSaving ? null : save,
              icon: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(isSaving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
