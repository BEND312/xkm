class UriListener {
  final String action;
  final String path;
  final Function(Uri uri) callback;

  const UriListener(
    this.action,
    this.path,
    this.callback,
  );
}
