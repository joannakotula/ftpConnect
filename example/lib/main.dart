import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter FTP Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final ValueNotifier<String> _logNotifier = ValueNotifier('');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Example FTP")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                onPressed: _uploadStepByStep,
                child: Text("Upload step by step"),
                color: Theme.of(context).primaryColorDark,
              ),
              RaisedButton(
                onPressed: _uploadWithRetry,
                child: Text("Upload with retry"),
                color: Theme.of(context).primaryColorDark,
              )
            ],
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                onPressed: _downloadStepByStep,
                child: Text("Download step by step"),
                color: Theme.of(context).primaryColor,
              ),
              RaisedButton(
                onPressed: _downloadWithRetry,
                child: Text("Download with retry"),
                color: Theme.of(context).primaryColor,
              )
            ],
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                onPressed: _uploadWithCompress,
                child: Text("Compress & Upload Zip"),
                color: Theme.of(context).primaryColorLight,
              ),
              RaisedButton(
                onPressed: _downloadZipAndUnZip,
                child: Text("Download Zip & decompress"),
                color: Theme.of(context).primaryColorLight,
              )
            ],
          ),
          RaisedButton(
            child: Text("Download Directory"),
            onPressed: () => _downloadDirectory(),
          ),
          ValueListenableBuilder(
              valueListenable: _logNotifier,
              builder: (context, String text, widget) {
                return Text(text ?? '');
              })
        ],
      ),
    );
  }

  Future<void> _uploadStepByStep() async {
    FTPConnect ftpConnect =
        FTPConnect("example.net", user: 'user', pass: 'pass');

    try {
      await _log('Connecting to FTP ...');
      await ftpConnect.connect();
      File fileToUpload = await _fileMock(
          fileName: 'uploadStepByStep.txt', content: 'uploaded Step By Step');
      await _log('Uploading ...');
      await ftpConnect.uploadFile(fileToUpload);
      await _log('file uploaded sucessfully');
      await ftpConnect.disconnect();
    } catch (e) {
      await _log('Error: ${e.toString()}');
    }
  }

  Future<void> _uploadWithRetry() async {
    try {
      FTPConnect ftpConnect =
          FTPConnect("example.net", user: 'user', pass: 'pass');

      File fileToUpload = await _fileMock(
          fileName: 'uploadwithRetry.txt', content: 'uploaded with Retry');
      await _log('Uploading ...');
      bool res =
          await ftpConnect.uploadFileWithRetry(fileToUpload, pRetryCount: 2);
      await _log('file uploaded: ' + (res ? 'SUCCESSFULLY' : 'FAILED'));
    } catch (e) {
      await _log('Downloading FAILED: ${e.toString()}');
    }
  }

  Future<void> _downloadWithRetry() async {
    try {
      await _log('Downloading ...');
      FTPConnect ftpConnect =
          FTPConnect("example.net", user: 'user', pass: 'pass');

      String fileName = 'flutter/test.txt';
      //here we just prepare a file as a path for the downloaded file
      File downloadedFile = await _fileMock(fileName: 'downloadwithRetry.txt');
      bool res = await ftpConnect
          .downloadFileWithRetry(fileName, downloadedFile, pRetryCount: 2);
      await _log('file downloaded  ' +
          (res ? 'path: ${downloadedFile.path}' : 'FAILED'));
    } catch (e) {
      await _log('Downloading FAILED: ${e.toString()}');
    }
  }

  Future<void> _downloadStepByStep() async {
    try {
      await _log('Connecting to FTP ...');
      FTPConnect ftpConnect =
          FTPConnect("example.net", user: 'user', pass: 'pass');

      await ftpConnect.connect();

      await _log('Downloading ...');
      String fileName = 'flutter/test.txt';

      //here we just prepare a file as a path for the downloaded file
      File downloadedFile = await _fileMock(fileName: 'downloadStepByStep.txt');
      await ftpConnect.downloadFile(fileName, downloadedFile);
      await _log('file downloaded path: ${downloadedFile.path}');
      await ftpConnect.disconnect();
    } catch (e) {
      await _log('Downloading FAILED: ${e.toString()}');
    }
  }

  Future<void> _uploadWithCompress({String filename = 'flutterZip.zip'}) async {
    try {
      FTPConnect ftpConnect =
          FTPConnect("example.net", user: 'user', pass: 'pass');

      await _log('Compressing file ...');

      File fileToCompress = await _fileMock(
          fileName: 'fileToCompress.txt', content: 'uploaded into a zip file');
      final zipPath = (await getTemporaryDirectory()).path + '/$filename';

      await FTPConnect.zipFiles([fileToCompress.path], zipPath);

      await _log('Uploading Zip file ...');
      bool res =
          await ftpConnect.uploadFileWithRetry(File(zipPath), pRetryCount: 2);
      await _log('Zip file uploaded: ' + (res ? 'SUCCESSFULLY' : 'FAILED'));
    } catch (e) {
      await _log('Upload FAILED: ${e.toString()}');
    }
  }

  Future<void> _downloadZipAndUnZip() async {
    try {
      //this will upload a flutterZip.zip file (create a ftp file to be downloaded)
      String ftpFileName = 'flutterZip.zip';
      await _uploadWithCompress(filename: ftpFileName);
      //we delete the file locally
      File((await getTemporaryDirectory()).path + '/$ftpFileName').deleteSync();
      //start downloading the zip file
      await _log('Downloading Zip file...');

      FTPConnect ftpConnect =
          FTPConnect("example.net", user: 'user', pass: 'pass');

      //here we just prepare a file as a path for the downloaded file
      File downloadedZipFile = await _fileMock(fileName: 'ZipDownloaded.zip');
      bool res = await ftpConnect.downloadFileWithRetry(
          ftpFileName, downloadedZipFile);
      if (res) {
        await _log('Zip file downloaded  path: ${downloadedZipFile.path}');
        await _log('UnZip files...');
        await _log('origin zip file\n' +
            downloadedZipFile.path +
            '\n\n\n Extracted files\n' +
            (await FTPConnect.unZipFile(
                    downloadedZipFile, downloadedZipFile.parent.path))
                .reduce((v, e) => v + '\n' + e));
      } else {
        await _log('Zip file downloaded FAILED');
      }
    } catch (e) {
      await _log('Downloading FAILED: ${e.toString()}');
    }
  }

  Future<void> _downloadDirectory() async {
    try {
      FTPConnect ftpConnect =
          FTPConnect("example.net", user: 'user', pass: 'pass');

      await _log('Download Directory  ...');

      var localDir =
          Directory((await getExternalStorageDirectory()).path + '/flutter')
            ..createSync(recursive: true);
      var res = await ftpConnect.downloadDirectory(
          'entrant/ND2/TabErwan/DashBoard', localDir);

      await _log('Downloading directory: ' + (res ? 'SUCCESSFULLY' : 'FAILED'));
    } catch (e) {
      await _log('Downloading directory FAILED: ${e.toString()}');
    }
  }

  ///an auxiliary function that manage showed log to UI
  Future<void> _log(String log) async {
    _logNotifier.value = log;
    await Future.delayed(Duration(seconds: 1));
  }

  ///mock a file for the demonstration example
  Future<File> _fileMock({fileName = 'FlutterTest.txt', content = ''}) async {
    final Directory directory =
        Directory((await getExternalStorageDirectory()).path + '/test')
          ..createSync(recursive: true);
    final File file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }
}
