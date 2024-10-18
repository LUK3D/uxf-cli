import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:tiny_storage/tiny_storage.dart';

void main(List<String> arguments) async {
  final storage = await TinyStorage.init('db.json', path: './tmp');

  final parser = ArgParser();

  parser.addCommand("add");
  parser.addCommand("auth");

  parser.addOption(
    "package",
    abbr: "p",
    help: 'Package name to download',
  );
  parser.addOption(
    "dir",
    abbr: "d",
    help: 'The Directory to install the package (optional)',
  );
  parser.addOption(
    "sid",
    abbr: "s",
    help: 'Set a subscription ID to be used when fetching the packages.',
  );
  parser.addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Show usage information',
  );
  parser.addFlag(
    'list',
    abbr: 'l',
    negatable: false,
    help: 'Show the current subscription ID',
  );

  final results = parser.parse(arguments);

  if (results.command?.name == 'add') {
    final packageName = results['package'];
    final installPath = results['dir'];
    await downloadAndExtractPackage(
        packageName, installPath, storage.get("sid"));
  } else if (results.command?.name == 'auth') {
    final subscriptionId = results['sid'];
    storage.set("sid", subscriptionId);
    print("✅ Subscription id Updated successfully!");
  } else if (results['list']) {
    print("Your current session id is:");
    print(storage.get("sid"));
  } else if (results['help']) {
    print(
        'Usage: dart run uxf.dart -p <package_name> [--path <installation_path>]');
    print(parser.usage);
  }
  Future.delayed(Duration(seconds: 1), () {
    exit(0);
  });
}

Future<void> downloadAndExtractPackage(
    String packageName, String? installPath, String? token) async {
  print('Downloading package: $packageName');

  final url = 'https://registry.uxflutter.com/packages/$packageName';
  // final url = 'http://localhost:3002/packages/$packageName';

  try {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    request.headers["sid"] = token ?? '';

    final response = await client.send(request);

    if (response.statusCode == 200) {
      Directory targetDir;
      if (installPath != null) {
        targetDir = Directory(installPath);
      } else {
        targetDir = Directory.current;
      }

      await targetDir.create(recursive: true);

      final tempZipFile = File(path.join(targetDir.path, '$packageName.zip'));
      final sink = tempZipFile.openWrite();

      // final contentLength = response.contentLength ?? 0;
      // var downloadedBytes = 0;

      await for (var chunk in response.stream) {
        sink.add(chunk);
        // downloadedBytes += chunk.length;
        // final progress =
        //     (downloadedBytes / contentLength * 100).toStringAsFixed(2);
        // stdout.write('\rDownloading: $progress% complete');
      }

      await sink.close();
      print('Extracting...');

      // Extract the contents of the zip file
      final bytes = await tempZipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File(path.join(targetDir.path, filename))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(path.join(targetDir.path, filename))
              .createSync(recursive: true);
        }
      }

      // Delete the temporary zip file
      await tempZipFile.delete();

      print('$packageName - Package added successfully');
    } else {
      print('Failed to download package. Status code: ${response.statusCode}');
      try {
        final responseBody = await response.stream.bytesToString();
        print("[ERROR]: ${json.decode(responseBody)["error"]}");
      } catch (_) {}
    }
  } catch (e) {
    if (e is HandshakeException) {
      print('Unable to connect with https://registry.uxflutter.com');
      return;
    }
    print('Error processing package: $e');
  }
}
