import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Flutter Web network image using a native HTML `<img>` element.
///
/// Firebase Storage download URLs load in Chrome but can fail through
/// [Image.network] on Flutter Web 3.44; the browser element avoids that path.
Widget buildVenueNetworkImage({
  required String url,
  required BoxFit fit,
  double? width,
  double? height,
  Alignment alignment = Alignment.center,
  Widget? errorWidget,
}) {
  return _WebHtmlNetworkImage(
    url: url,
    fit: fit,
    width: width,
    height: height,
    alignment: alignment,
    errorWidget: errorWidget,
  );
}

class _WebHtmlNetworkImage extends StatefulWidget {
  const _WebHtmlNetworkImage({
    required this.url,
    required this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.errorWidget,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Widget? errorWidget;

  @override
  State<_WebHtmlNetworkImage> createState() => _WebHtmlNetworkImageState();
}

class _WebHtmlNetworkImageState extends State<_WebHtmlNetworkImage> {
  static int _nextViewId = 0;
  static final _elements = <String, web.HTMLImageElement>{};

  late final String _viewType = 'venue-network-image-${_nextViewId++}';
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final img = web.HTMLImageElement();
      _elements[_viewType] = img;
      _apply(img);
      img.onError.listen((web.Event event) {
        if (kDebugMode) {
          debugPrint(
            '[VenueNetworkImage:web] HTML img failed url=${widget.url}',
          );
        }
        if (mounted) {
          setState(() => _failed = true);
        }
      });
      return img;
    });
  }

  @override
  void didUpdateWidget(covariant _WebHtmlNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _failed = false;
      final img = _elements[_viewType];
      if (img != null) {
        _apply(img);
      }
    } else if (oldWidget.fit != widget.fit ||
        oldWidget.alignment != widget.alignment) {
      final img = _elements[_viewType];
      if (img != null) {
        _apply(img);
      }
    }
  }

  void _apply(web.HTMLImageElement img) {
    img.src = widget.url;
    img.style
      ..width = '100%'
      ..height = '100%'
      ..display = 'block'
      ..border = '0'
      ..objectFit = _cssObjectFit(widget.fit)
      ..objectPosition = _cssObjectPosition(widget.alignment);
  }

  @override
  Widget build(BuildContext context) {
    final fallback =
        widget.errorWidget ??
        SizedBox(width: widget.width, height: widget.height);

    if (_failed) {
      return fallback;
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}

String _cssObjectFit(BoxFit fit) {
  return switch (fit) {
    BoxFit.contain => 'contain',
    BoxFit.cover => 'cover',
    BoxFit.fill => 'fill',
    BoxFit.fitWidth => 'scale-down',
    BoxFit.fitHeight => 'scale-down',
    BoxFit.none => 'none',
    BoxFit.scaleDown => 'scale-down',
  };
}

String _cssObjectPosition(Alignment alignment) {
  final x = ((alignment.x + 1) / 2 * 100).clamp(0, 100);
  final y = ((alignment.y + 1) / 2 * 100).clamp(0, 100);
  return '${x.toStringAsFixed(0)}% ${y.toStringAsFixed(0)}%';
}
