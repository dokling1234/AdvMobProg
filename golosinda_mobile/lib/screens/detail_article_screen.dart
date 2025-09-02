import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/article_model.dart';
import '../services/article_service.dart';
import '../widgets/custom_text.dart';
 
class ArticleDetailScreen extends StatefulWidget {
  final Article article;
 
  const ArticleDetailScreen({super.key, required this.article});
 
  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}
 
class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool isEdit = false;
  bool isSaving = false;
 
  late TextEditingController titleController;
  late TextEditingController authorController;
  late TextEditingController contentController;
  bool isActive = true;
 
  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.article.title);
    authorController = TextEditingController(text: widget.article.name);
    contentController = TextEditingController(
      text: widget.article.content.join("\n"),
    );
    isActive = widget.article.isActive;
  }
 
  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    contentController.dispose();
    super.dispose();
  }
 
  Future<void> _saveChanges() async {
    setState(() => isSaving = true);
    try {
      final payload = {
        "title": titleController.text.trim(),
        "name": authorController.text.trim(),
        "content": contentController.text
            .split(RegExp(r'[\n,]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        "isActive": isActive,
      };
 
      await ArticleService().updateArticle(widget.article.aid, payload);
 
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Article updated ✅")));
        Navigator.pop(context, true); // refresh parent
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update ❌ $e")));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }
 
  void _cancelEdit() {
    setState(() {
      isEdit = false;
      // reset values back to original
      titleController.text = widget.article.title;
      authorController.text = widget.article.name;
      contentController.text = widget.article.content.join("\n");
      isActive = widget.article.isActive;
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Article" : "Article Detail"),
        actions: [
          IconButton(
            icon: Icon(isEdit ? Icons.close : Icons.edit),
            onPressed: () {
              if (isEdit) {
                _cancelEdit();
              } else {
                setState(() => isEdit = true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: isEdit
            ? Column(
                children: [
                  // 🖼️ Placeholder with X (always visible)
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Title"),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: authorController,
                    decoration: const InputDecoration(labelText: "Author"),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(labelText: "Content"),
                    maxLines: 5,
                  ),
                  SwitchListTile.adaptive(
                    title: const Text("Active"),
                    value: isActive,
                    onChanged: (val) => setState(() => isActive = val),
                  ),
                  SizedBox(height: 20.h),
                  isSaving
                      ? const CircularProgressIndicator()
                      : Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _saveChanges,
                              icon: const Icon(Icons.save),
                              label: const Text("Save Changes"),
                            ),
                            SizedBox(height: 10.h),
                            OutlinedButton.icon(
                              onPressed: _cancelEdit,
                              icon: const Icon(Icons.cancel),
                              label: const Text("Cancel"),
                            ),
                          ],
                        ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🖼️ Placeholder also in view mode
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    CustomText(
                      text: widget.article.title,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 6.h),
                    CustomText(text: "By ${widget.article.name}"),
                    SizedBox(height: 6.h),
                    Wrap(
                      children: widget.article.content
                          .map(
                            (c) => Padding(
                              padding: EdgeInsets.only(bottom: 4.h),
                              child: CustomText(text: c, fontSize: 14.sp),
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: 12.h),
                    Chip(
                      label: Text(
                        widget.article.isActive ? "Active" : "Inactive",
                      ),
                      backgroundColor: widget.article.isActive
                          ? Colors.green.shade100
                          : Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
 