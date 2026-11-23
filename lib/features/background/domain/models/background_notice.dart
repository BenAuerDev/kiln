/// What the background notification shows, already in the app language.
/// The channel names are user-visible in the system settings.
class BackgroundNotice {
  const BackgroundNotice({
    required this.title,
    required this.text,
    required this.sessionChannel,
    required this.readyChannel,
  });

  final String title;
  final String text;
  final String sessionChannel;
  final String readyChannel;

  @override
  bool operator ==(Object other) =>
      other is BackgroundNotice &&
      other.title == title &&
      other.text == text &&
      other.sessionChannel == sessionChannel &&
      other.readyChannel == readyChannel;

  @override
  int get hashCode => Object.hash(title, text, sessionChannel, readyChannel);
}
