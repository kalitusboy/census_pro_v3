
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'db.dart';
import 'excel.dart';
import 'merge.dart';
import 'export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    _initApp();
  }

  Future<void> _initApp() async {
    // نطلب إذن الكاميرا فقط. التخزين يُدار عبر FilePicker دون أذونات خاصة.
    await Permission.camera.request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          // تحميل ملف HTML من assets
          initialFile: "assets/app.html",
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            mediaPlaybackRequiresUserGesture: false,
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;

            // ========== JavaScript Handlers ==========
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
        ),
      ),
    );
  }
}