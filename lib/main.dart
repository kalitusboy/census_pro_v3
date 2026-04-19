
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'db.dart';
import 'excel.dart';
import 'merge.dart';
import 'export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تشغيل السيرفر المحلي لتحميل assets بطريقة أكثر أماناً في الـ release
  final InAppLocalhostServer localhostServer = InAppLocalhostServer(
    documentRoot: 'assets',
    port: 8080,
  );
  await localhostServer.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'نسيم للإحصاء 2026',
      home: WebApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WebApp extends StatefulWidget {
  const WebApp({super.key});

  @override
  State<WebApp> createState() => _WebAppState();
}

class _WebAppState extends State<WebApp> {
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
    // للأجهزة الحديثة
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri('http://localhost:8080/app.html'),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            cacheEnabled: true,
            javaScriptCanOpenWindowsAutomatically: true,
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;

            // JavaScript Handlers
            controller.addJavaScriptHandler(
              handlerName: 'getAll',
              callback: (args) async => await DB.getAllRecords(),
            );

            controller.addJavaScriptHandler(
              handlerName: 'saveRecord',
              callback: (args) async {
                try {
                  await DB.saveRecord(Map<String, dynamic>.from(args[0]));
                  return {"status": "saved"};
                } catch (e) {
                  return {"status": "error", "message": e.toString()};
                }
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'importExcel',
              callback: (args) async {
                await importExcel();
                return {"status": "imported"};
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'mergeData',
              callback: (args) async {
                await mergeData();
                return {"status": "merged"};
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'exportExcel',
              callback: (args) async {
                await exportToExcel(args[0] as List<dynamic>);
                return {"status": "exported"};
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'exportImagesZip',
              callback: (args) async {
                await exportImagesToZip(args[0] as List<dynamic>);
                return {"status": "done"};
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'exportFullDB',
              callback: (args) async {
                await exportFullJson();
                return {"status": "exported"};
              },
            );
          },
          onLoadStop: (controller, url) async {
            print("✅ WebView Loaded Successfully: $url");
          },
          onConsoleMessage: (controller, consoleMessage) {
            print("JS Console: ${consoleMessage.messageType} - ${consoleMessage.message}");
          },
          onReceivedError: (controller, request, error) {
            print("❌ WebView Error: ${error.description}");
          },
        ),
      ),
    );
  }
}
