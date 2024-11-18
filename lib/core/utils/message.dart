part of core;

class Message {
  void snackbar(
    BuildContext context, {
    required String text,
    Color? backgroundColor,
    Color? iconColor,
    EdgeInsets? margin,
    SnackBarBehavior? position,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration ?? const Duration(milliseconds: 1300),
        content: Semantics.fromProperties(
          properties: const SemanticsProperties(
            liveRegion: true,
          ),
          child: Text(text),
        ),
        backgroundColor: backgroundColor,
        behavior: position ?? SnackBarBehavior.floating,
        margin: margin,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        action: SnackBarAction(
          label: 'Close',
          textColor: iconColor ?? Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
