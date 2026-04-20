
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'db.dart';
import 'excel.dart';
import 'merge.dart';
import 'export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تشغيل السيرفر المحلي المستضاف في ملفات assets
  final localhostServer = InAppLocalhostServer(documentRoot: 'assets', port: 8080);
  await localhostServer.start();

  // طلب الصلاحيات
  await Permission.camera.request();
  await Permission.storage.request();
  await Permission.manageExternalStorage.request();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'نسيم للإحصاء 2026',
      debugShowCheckedModeBanner: false,
      home: WebApp(),
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          // استخدام الرابط المحلي كما في كودك الأصلي
          initialUrlRequest: URLRequest(url: WebUri('http://localhost:8080/app.html')),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            cacheEnabled: true,
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;

            // ================== JavaScript Handlers ==================
            
            controller.addJavaScriptHandler(
              handlerName: 'getAll',
              callback: (args) async => await DB.getAllRecords(),
            );

            controller.addJavaScriptHandler(
              handlerName: 'saveRecord',
              callback: (args) async {
                await DB.saveRecord(Map<String, dynamic>.from(args[0]));
                return {"status": "saved"};
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
          onLoadStop: (controller, url) {
            print("✅ WebView Loaded: $url");
          },
          onConsoleMessage: (controller, consoleMessage) {
            print("JS Console: [${consoleMessage.messageLevel}] ${consoleMessage.message}");
          },
          onReceivedError: (controller, request, error) {
            print("❌ WebView Error: ${error.description}");
          },
        ),
      ),
    );
  }
}
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
          onLoadStop: (controller, url) {
            print("✅ WebView Loaded: $url");
          },
          onConsoleMessage: (controller, consoleMessage) {
            print("JS Console: [${consoleMessage.messageLevel}] ${consoleMessage.message}");
          },
          onReceivedError: (controller, request, error) {
            print("❌ WebView Error: ${error.description}");
          },
        ),
      ),
    );
  }
}
              handlerName: 'exportFullDB',
              callback: (args) async {
                await exportFullJson();
                return {"status": "exported"};
              },
            );
          },
          onLoadStop: (controller, url) {
            print("✅ WebView Loaded: $url");
          },
          onConsoleMessage: (controller, consoleMessage) {
            print("JS Console: [${consoleMessage.messageLevel}] ${consoleMessage.message}");
          },
          onReceivedError: (controller, request, error) {
            print("❌ WebView Error: ${error.description}");
          },
        ),
      ),
    );
  }
}
