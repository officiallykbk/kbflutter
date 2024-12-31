import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

String? imageUrl;
final picker = ImagePicker();

Future getImageGallery(imgsource, imgName) async {
  try {
    final pickedFile = await picker.pickImage(source: imgsource);

    if (pickedFile != null) {
      await uploadImageToFirebase(File(pickedFile.path), imgName);
    }
  } catch (e) {
    print('Failed to pick image ${e}');
  }
}

Future<String> uploadImageToFirebase(File image, imgName) async {
  try {
    final ref = FirebaseStorage.instance.ref().child(
        'images/${imgName}<>${DateTime.now().toString().substring(0, 10)}.png');
    await ref.putFile(image).whenComplete(() {});

    imageUrl = await ref.getDownloadURL();
    return imageUrl!;
  } catch (e) {
    print('Failed to upload image ${e}');
    return 'Upload Failed';
  }
}
