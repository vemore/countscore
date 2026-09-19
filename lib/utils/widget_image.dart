import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Draws [widget] off-screen — in a pipeline of its own, never shown — and
/// returns it as a PNG.
///
/// The widget is laid out under [constraints] (loose: it takes its own size
/// within them) and drawn at [pixelRatio] physical pixels per logical pixel.
/// It inherits nothing from the app's tree: [context] lends it the themes,
/// the localizations, the media query and the view, so it looks like the
/// screen it is shared from. Build, layout and paint run synchronously, before
/// the first `await`, so [context] is only read while it is still mounted.
///
/// In a widget test the returned future completes only under
/// `tester.runAsync`: `toImage` is answered by the engine, not by fake time.
Future<Uint8List> renderWidgetToPng(
  BuildContext context,
  Widget widget, {
  BoxConstraints constraints = const BoxConstraints(maxWidth: 400, maxHeight: 4000),
  double pixelRatio = 3,
}) async {
  final view = View.of(context);
  final boundary = RenderRepaintBoundary();
  final renderView = RenderView(
    view: view,
    child: boundary,
    configuration: ViewConfiguration(
      logicalConstraints: constraints,
      physicalConstraints: constraints * pixelRatio,
      devicePixelRatio: pixelRatio,
    ),
  );
  final pipelineOwner = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();

  final buildOwner = BuildOwner(focusManager: FocusManager());
  final wrapped = InheritedTheme.captureAll(
    context,
    Localizations.override(
      context: context,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(devicePixelRatio: pixelRatio),
        child: widget,
      ),
    ),
  );
  final root = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: wrapped,
  ).attachToRenderTree(buildOwner);
  buildOwner
    ..buildScope(root)
    ..finalizeTree();
  pipelineOwner
    ..flushLayout()
    ..flushCompositingBits()
    ..flushPaint();

  try {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('PNG encoding returned no bytes');
      return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    } finally {
      image.dispose();
    }
  } finally {
    // Unmount the widgets (their states are disposed), then drop the tree.
    RenderObjectToWidgetAdapter<RenderBox>(container: boundary)
        .attachToRenderTree(buildOwner, root);
    buildOwner.finalizeTree();
    pipelineOwner.rootNode = null;
    pipelineOwner.dispose();
  }
}
