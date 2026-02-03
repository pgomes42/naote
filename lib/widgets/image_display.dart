import 'package:flutter/material.dart';

/// Widget responsável por carregar e exibir a imagem T.jpeg
class ImageDisplay extends StatefulWidget {
  final double width;
  final double height;

  const ImageDisplay({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  State<ImageDisplay> createState() => _ImageDisplayState();
}

class _ImageDisplayState extends State<ImageDisplay> {
  late Future<ImageProvider> _imageProvider;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() {
    _imageProvider = Future(() async {
      try {
        final provider = AssetImage('assets/T.jpeg');
        await provider.resolve(ImageConfiguration.empty);
        print('Imagem carregada com sucesso: assets/T.jpeg');
        return provider;
      } catch (e) {
        print('Erro ao carregar imagem: $e');
        rethrow;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider>(
      future: _imageProvider,
      builder: (context, snapshot) {
        print('FutureBuilder state: ${snapshot.connectionState}, hasError: ${snapshot.hasError}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Carregando...', style: TextStyle(fontSize: 10)),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.red[100],
              border: Border.all(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 24),
                const SizedBox(height: 4),
                Text(
                  'Erro: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: Colors.red),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }

        if (snapshot.hasData) {
          return Image(
            image: snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.contain,
          );
        }

        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.yellow[100],
          alignment: Alignment.center,
          child: const Text('?', style: TextStyle(fontSize: 20)),
        );
      },
    );
  }
}
