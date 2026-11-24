
import 'dart:async';
import 'dart:html' as html;

Future<String?> pilihFailBackup() async {
  final input = html.FileUploadInputElement()
    ..accept = '.json,application/json';

  input.click();

  final completer = Completer<String?>();

  input.onChange.first.then((_) async {
    try {
      final fail = input.files?.isNotEmpty == true
          ? input.files!.first
          : null;

      if (fail == null) {
        completer.complete(null);
        return;
      }

      final reader = html.FileReader();
      reader.readAsText(fail);

      await reader.onLoad.first;

      if (reader.error != null) {
        throw StateError('Gagal membaca fail backup.');
      }

      completer.complete(reader.result as String);
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }
  });

  return completer.future;
}
