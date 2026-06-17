void main() {
  final ytRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?.*v=|shorts\/|embed\/)|youtu\.be\/)([\w\-]+)',
    caseSensitive: false,
  );
  final url = 'https://youtube.com/watch?v=FtXO5WrOqFg&t=10s';
  print(ytRegex.hasMatch(url));
}
