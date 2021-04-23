library image_util;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle, rootBundle;
import 'package:image/image.dart' as Imagee;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

class ImageUtil {
  static String _filePath;

  static Future<Uint8List> mergeImage(
    Uint8List imageBytes1,
    Uint8List imageBytes2, {
    int width = 2048,
    int height = 1024,
  }) async {
    final image3 = Imagee.decodeImage(imageBytes1);
    final image4 = Imagee.decodeImage(imageBytes2);

    final image1 = Imagee.copyResize(
      image3,
      width: width,
      height: height,
    );
    final image2 = Imagee.copyResize(
      image4,
      width: width,
      height: (height / 2).round(),
    );

    final mergedImage = Imagee.Image(
      max(image1.width, image2.width),
      image1.height + image2.height,
    );

    Imagee.copyInto(mergedImage, image1, blend: false);

    Imagee.copyInto(mergedImage, image2, dstY: image1.height, blend: false);

    // final documentDirectory = await getApplicationDocumentsDirectory();
    // _filePath = join(documentDirectory.path, 'merged_image.jpg');
    // final file = new File(_filePath);
    // file.writeAsBytesSync(Imagee.encodeJpg(mergedImage));

    //print(_filePath.toString());

    //return file.readAsBytesSync();
    return Uint8List.fromList(Imagee.encodeJpg(mergedImage));
  }

  static Future<Uint8List> frameImage(
    Uint8List imageBytes1,
    Uint8List imageBytes2, {
    int width = 2048,
    int height = 1024,
    double frameRatio = 0.1,
  }) async {
    final image3 = Imagee.decodeImage(imageBytes1);
    final image4 = Imagee.decodeImage(imageBytes2);

    final image1 = Imagee.copyResize(
      image3,
      width: width - (width * frameRatio * 2).toInt(),
      height: height - (height * frameRatio * 2).toInt(),
    );
    final image2 = Imagee.copyResize(image4, width: width, height: height);

    final mergedImage = Imagee.Image(
      width,
      height,
    );

    Imagee.copyInto(mergedImage, image2, blend: false);

    Imagee.copyInto(
      mergedImage,
      image1,
      dstX: (width * frameRatio).toInt(),
      dstY: (height * frameRatio).toInt(),
      blend: false,
    );

    return Uint8List.fromList(Imagee.encodeJpg(mergedImage));
  }

  static Future<Uint8List> mergeImageWithFooter(
    Uint8List imageBytes, {
    int width = 2048,
    int height = 1024,
  }) async {
    var whiteCanvas = Uint8List.fromList(List.filled(16, 255));

    Uint8List image = await mergeImage(
      imageBytes,
      whiteCanvas,
      width: width,
      height: height,
    );

    return image;
  }

  static Future<Uint8List> computeMergeImage(Map args) async {
    Uint8List originalImageBytes;
    Uint8List whiteImageBytes;

    originalImageBytes = args['imageData'];
    whiteImageBytes = args['whiteImage'];

    Uint8List image = await mergeImage(
      originalImageBytes,
      whiteImageBytes,
      width: (args['width'] as double).toInt(),
      height: (args['height'] as double).toInt(),
    ).catchError((error) {
      print(error.toString());
    });

    print('Done Merging');

    return image;
  }

  static Future<Uint8List> computeFrameImage(Map args) async {
    Uint8List originalImageBytes;
    Uint8List whiteImageBytes;

    originalImageBytes = args['imageData'];
    whiteImageBytes = args['whiteImage'];

    Uint8List image = await frameImage(
      originalImageBytes,
      whiteImageBytes,
      width: (args['width'] as double).toInt(),
      height: (args['height'] as double).toInt(),
    ).catchError((error) {
      print(error.toString());
    });

    print('Done Merging');

    return image;
  }

  static Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('assets/$path');

    final file = File('${(await getTemporaryDirectory()).path}/$path');
    await file.writeAsBytes(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );

    return file;
  }

  static Future getEmojisList(context) async {
    final manifestContent =
        await DefaultAssetBundle.of(context).loadString('AssetManifest.json');

    final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);

    final imagePaths = manifestMap.keys
        .where((String key) => key.contains('assets/emoji/'))
        .where((String key) => key.contains('.png'))
        .toList();

    return imagePaths;
  }

  static Future<void> saveToGalleryWithUrl(String url) async {
    final ByteData imageData =
        await NetworkAssetBundle(Uri.parse(url)).load('');
    saveToGalleryWithByteData(imageData);
  }

  static Future<void> saveToGalleryWithByteData(ByteData imageData) async {
    final Uint8List bytes = imageData.buffer.asUint8List();
    saveToGallery(bytes);
  }

  static Future<void> saveToGallery(Uint8List bytes) async {
    var appDocDir = await getTemporaryDirectory();
    String savePath = appDocDir.path + '/temp.png';

    final file = new File(savePath);
    file.writeAsBytesSync(bytes);

    final result = await ImageGallerySaver.saveFile(savePath);
    print(result);
  }

  static void showLoading(context) {
    AlertDialog alert = AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          Container(
            margin: EdgeInsets.only(left: 10),
            child: Text("Processing..."),
          ),
        ],
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static void showMergedFile(context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          key: Key('text_dialog'),
          content: FadeInImage(
            placeholder: ResizeImage(
              FileImage(
                File('assets/logo.png'),
              ),
              width: 200,
              height: 200,
            ),
            image: FileImage(
              File(_filePath),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
