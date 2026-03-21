import 'dart:io';

void main() async {
  final file = File('lib/providers/app_state.dart');
  final lines = await file.readAsLines();

  final productsFile = File('products.txt');
  final productsContent = await productsFile.readAsString();

  final outLines = <String>[];
  bool inInventoryBlock = false;
  bool skipLines = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    
    if (line.contains('final initialInventory = [')) {
      outLines.add(line);
      outLines.add(productsContent.trimRight());
      skipLines = true;
      continue;
    }

    if (skipLines) {
      if (line.trim() == '];') {
        skipLines = false;
        outLines.add('    ];');
      }
      continue;
    }

    outLines.add(line);
  }

  await file.writeAsString(outLines.join('\n'));
}
