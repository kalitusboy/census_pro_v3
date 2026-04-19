
import 'dart:ui'; // ضروري لـ PlatformDispatcher

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'db.dart';
import 'excel.dart';
import 'merge.dart';
import 'export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // التقاط الأخطاء العامة وعرضها بدلاً من الإغلاق
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    runApp(ErrorApp(errorDetails: details));
  };

  // التقاط الأخطاء غير المتزامنة (مثل Future/Stream)
  PlatformDispatcher.instance.onError = (error, stack) {
    runApp(ErrorApp(errorDetails: FlutterErrorDetails(
      exception: error,
      stack: stack,
    )));
    return true;
  };

  runApp(const MyApp());
}

// شاشة لعرض الخطأ بالتفصيل
class ErrorApp extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const ErrorApp({super.key, required this.errorDetails});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ حدث خطأ غير متوقع',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 16),
                const Text('تفاصيل الخطأ:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      errorDetails.exceptionAsString(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('مكان الخطأ:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      errorDetails.toString(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'إحصاء 2026',
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
    try {
      await Permission.camera.request();
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    } catch (e) {
      debugPrint('خطأ في طلب الأذونات: $e');
    }
  }

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
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;

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
          onLoadError: (controller, url, code, message) {
            debugPrint('خطأ تحميل WebView: $code - $message');
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint('JS Console: ${consoleMessage.message}');
          },
        ),
      ),
    );
  }
}
