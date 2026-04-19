
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'db.dart';
import 'excel.dart';
import 'merge.dart';
import 'export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // طلب الصلاحيات عند التشغيل
  await Permission.camera.request();
  await Permission.storage.request();
  // للأجهزة الحديثة جداً
  await Permission.manageExternalStorage.request();

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialFile: "assets/app.html",
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

            // Handler: Import Excel
            controller.addJavaScriptHandler(
              handlerName: 'importExcel',
              callback: (args) async {
                await importExcel();
                return {"status": "imported"};
              },
            );

            // Handler: Merge Data
            controller.addJavaScriptHandler(
              handlerName: 'mergeData',
              callback: (args) async {
                await mergeData();
                return {"status": "merged"};
              },
            );

            // Handler: Export Excel
            controller.addJavaScriptHandler(
              handlerName: 'exportExcel',
              callback: (args) async {
                await exportToExcel(args[0] as List<dynamic>);
                return {"status": "exported"};
              },
            );

            // Handler: Export Images Zip
            controller.addJavaScriptHandler(
              handlerName: 'exportImagesZip',
              callback: (args) async {
                await exportImagesToZip(args[0] as List<dynamic>);
                return {"status": "done"};
              },
            );

            // Handler: Export Full DB JSON
            controller.addJavaScriptHandler(
              handlerName: 'exportFullDB',
              callback: (args) async {
                await exportFullJson();
                return {"status": "exported"};
              },
            );
          }, // نهاية onWebViewCreated
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
