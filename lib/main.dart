
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'db.dart';
import 'excel.dart';
import 'merge.dart';
import 'export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تشغيل السيرفر المحلي (أكثر استقراراً في الـ release)
  final localhostServer = InAppLocalhostServer(documentRoot: 'assets', port: 8080);
  await localhostServer.start();

  await Permission.camera.request();
  await Permission.storage.request();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نسيم للإحصاء 2026',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),   // شاشة تحميل
    );
  }
}

// شاشة تحميل بسيطة
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // يمكنك إضافة تأخير إذا أردت
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WebApp()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'نظام الإحصاء 2026',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(),
          ],
        ),
      ),
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

            // JavaScript Handlers (كلها)
            controller.addJavaScriptHandler(handlerName: 'getAll', callback: (args) async => await DB.getAllRecords());

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

            controller.addJavaScriptHandler(handlerName: 'importExcel', callback: (args) async {
              await importExcel();
              return {"status": "imported"};
            });

            controller.addJavaScriptHandler(handlerName: 'mergeData', callback: (args) async {
              await mergeData();
              return {"status": "merged"};
            });

            controller.addJavaScriptHandler(handlerName: 'exportExcel', callback: (args) async {
              await exportToExcel(args[0] as List<dynamic>);
              return {"status": "exported"};
            });

            controller.addJavaScriptHandler(handlerName: 'exportImagesZip', callback: (args) async {
              await exportImagesToZip(args[0] as List<dynamic>);
              return {"status": "done"};
            });

            controller.addJavaScriptHandler(handlerName: 'exportFullDB', callback: (args) async {
              await exportFullJson();
              return {"status": "exported"};
            });
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
}              handlerName: 'exportFullDB',
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
