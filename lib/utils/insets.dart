import 'package:flutter/widgets.dart';

/// Returns [base] with the system's bottom inset added to its bottom edge.
///
/// A `BoxScrollView` (`ListView`, `GridView`) inserts `MediaQuery.padding` on
/// its main axis **only when its `padding` argument is null**. Every root
/// scrollable that passes an explicit padding therefore loses that
/// compensation, and its last row cannot be scrolled clear of the system
/// navigation bar — the app is edge-to-edge on `targetSdk` 36 and cannot opt
/// out. Wrapping the padding in this helper reproduces exactly what Flutter
/// would have done on its own.
///
/// Only the bottom edge is compensated: these screens all sit under an
/// `AppBar`, which consumes the top inset already.
///
/// Uses `MediaQuery.paddingOf` rather than `MediaQuery.of(context).padding`,
/// so the subtree is not rebuilt on every unrelated metric change (the
/// keyboard opening, an orientation change, a text-scale change).
EdgeInsets withBottomInset(BuildContext context, EdgeInsets base) =>
    base.copyWith(bottom: base.bottom + MediaQuery.paddingOf(context).bottom);
