import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageViewerScreen extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final String? title;
  final String heroTag;

  const ImageViewerScreen({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.title,
    required this.heroTag,
  }) : assert(imageUrl != null || imageFile != null);

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    if (imageFile != null) {
      imageProvider = FileImage(imageFile!);
    } else {
      imageProvider = CachedNetworkImageProvider(imageUrl!);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: title != null ? Text(title!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: Hero(
          tag: heroTag,
          child: PhotoView(
            imageProvider: imageProvider,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
