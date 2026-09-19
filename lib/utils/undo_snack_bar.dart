import 'package:flutter/material.dart';

/// How long an Undo stays on offer.
const Duration kUndoSnackBarDuration = Duration(seconds: 6);

/// A snackbar that says what just happened and offers it back for
/// [kUndoSnackBarDuration], then goes away on its own.
///
/// Flutter keeps a snackbar that has an action on screen until it is
/// dismissed (`persist` defaults to true then), and an Undo still offered long
/// after the action, with other changes made in between, is misleading.
SnackBar undoSnackBar({
  required String message,
  required String undoLabel,
  required VoidCallback onUndo,
}) {
  return SnackBar(
    content: Text(message),
    duration: kUndoSnackBarDuration,
    persist: false,
    action: SnackBarAction(label: undoLabel, onPressed: onUndo),
  );
}
