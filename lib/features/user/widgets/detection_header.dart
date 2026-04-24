import 'package:flutter/material.dart';
import '../../../../core/utils/bounding_box.dart';
import '../../../../model/model.dart';

class DetectionHeader extends StatefulWidget {
  final String imageUrl;
  final List<BoundingBoxes> detections;
  final String? activeLabel;

  const DetectionHeader({
    super.key,
    required this.imageUrl,
    required this.detections,
    this.activeLabel,
  });

  @override
  State<DetectionHeader> createState() => _DetectionHeaderState();
}

class _DetectionHeaderState extends State<DetectionHeader> {
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  void _loadImageSize() {
    final ImageStream stream = Image.network(widget.imageUrl)
        .image
        .resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener((ImageInfo info, bool _) {
      if (mounted) {
        setState(() {
          _imageSize =
              Size(info.image.width.toDouble(), info.image.height.toDouble());
        });
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    if (_imageSize == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: AspectRatio(
        aspectRatio: _imageSize!.width / _imageSize!.height,
        child: LayoutBuilder(builder: (context, constraints) {
          return Stack(
            children: [
              // Use fit: BoxFit.fill to ensure the coordinates map 1:1 to the widget size
              Image.network(
                widget.imageUrl,
                fit: BoxFit.fill,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: BoundingBoxPainter(
                  widget.detections,
                  _imageSize!, // Use the actual loaded image size for scaling
                  activeLabel: widget.activeLabel,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

void getImageSize(String url, void Function(Size size) onResult) {
  final image = Image.network(url);
  final ImageStream stream = image.image.resolve(const ImageConfiguration());

  stream.addListener(
    ImageStreamListener((ImageInfo info, bool _) {
      final mySize =
          Size(info.image.width.toDouble(), info.image.height.toDouble());
      onResult(mySize);
    }),
  );
}

class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
