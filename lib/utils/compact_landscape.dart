import 'package:flutter/widgets.dart';

/// Below this height (dp), a window wider than it is tall takes the compact
/// landscape layout: a phone turned sideways (360 to about 450 dp high on its
/// side), never a tablet, whose short side is 600 dp or more. Height, not
/// width: a landscape phone is already wider than the width breakpoints
/// (`kHomeGridBreakpoint`), and what it lacks is height.
const double kCompactLandscapeMaxHeight = 500;

/// The app bar's height in the compact landscape layout: Material's toolbar
/// on a phone held sideways, 8 dp under the portrait `kToolbarHeight`.
const double kCompactLandscapeToolbarHeight = 48;

/// Whether a window of [size] gets the compact landscape layout: wider than
/// tall — `MediaQuery.orientationOf`'s own rule — and shorter than
/// [kCompactLandscapeMaxHeight].
bool isCompactLandscape(Size size) =>
    size.width > size.height && size.height < kCompactLandscapeMaxHeight;

/// [isCompactLandscape] for the window [context] is laid out in. Reads only
/// the size, so a keyboard or a text-scale change does not rebuild.
bool compactLandscapeOf(BuildContext context) =>
    isCompactLandscape(MediaQuery.sizeOf(context));

/// The `toolbarHeight` an `AppBar` takes: [kCompactLandscapeToolbarHeight] in
/// the compact landscape layout, null — the default — everywhere else.
double? compactToolbarHeightOf(BuildContext context) =>
    compactLandscapeOf(context) ? kCompactLandscapeToolbarHeight : null;
