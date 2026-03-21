import 'dart:io';

void main() {
  final dir = Directory('lib');
  for (var file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      var newContent = content
          .replaceAll('AppTheme.background', 'AppTheme.background(context)')
          .replaceAll('AppTheme.cardBg', 'AppTheme.cardBg(context)')
          .replaceAll('AppTheme.textBody', 'AppTheme.textBody(context)')
          .replaceAll('AppTheme.textHeading', 'AppTheme.textHeading(context)')
          .replaceAll('AppTheme.divider', 'AppTheme.divider(context)')
          .replaceAll('AppTheme.background(context)(context)', 'AppTheme.background(context)') // clean double replace just in case
          .replaceAll('AppTheme.cardBg(context)(context)', 'AppTheme.cardBg(context)')
          .replaceAll('AppTheme.textBody(context)(context)', 'AppTheme.textBody(context)')
          .replaceAll('AppTheme.textHeading(context)(context)', 'AppTheme.textHeading(context)')
          .replaceAll('AppTheme.divider(context)(context)', 'AppTheme.divider(context)')
          .replaceAll('Colors.white10', 'AppTheme.divider(context)');

      // Deal with Colors.white representing text or icons in some places, 
      // replace with Theme.of(context).iconTheme.color or text color.
      // But let's only do safe replacements first.

      if (content != newContent) {
        file.writeAsStringSync(newContent);
        print('Updated \${file.path}');
      }
    }
  }
}
