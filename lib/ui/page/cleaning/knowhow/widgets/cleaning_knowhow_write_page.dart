import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../cleaning_knowhow_controller.dart';

class CleaningKnowhowWritePage extends StatelessWidget {
  const CleaningKnowhowWritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CleaningKnowhowController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '노하우 공유하기',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() => TextButton(
            onPressed: controller.isUploading.value
                ? null
                : () => controller.createKnowhow(),
            child: controller.isUploading.value
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '등록',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
          )),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Picker
            GestureDetector(
              onTap: () => controller.pickImage(),
              child: Obx(() {
                final image = controller.selectedImage.value;
                return Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    image: image != null
                        ? DecorationImage(
                            image: FileImage(image),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 40, color: Colors.grey[400]),
                            SizedBox(height: 8),
                            Text(
                              '사진 추가하기',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  controller.selectedImage.value = null;
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                );
              }),
            ),
            SizedBox(height: 24),
            
            // Title Input
            TextField(
              controller: controller.titleController,
              decoration: InputDecoration(
                hintText: '제목을 입력해주세요',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.bold),
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(height: 32),
            
            // Content Input
            TextField(
              controller: controller.contentController,
              decoration: InputDecoration(
                hintText: '나만의 청소 노하우를 자유롭게 작성해주세요.\n(예: 화장실 물때 제거하는 법, 창틀 먼지 쉽게 닦는 법 등)',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16, height: 1.5),
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 16, height: 1.5),
              maxLines: null,
              minLines: 10,
            ),
          ],
        ),
      ),
    );
  }
}
