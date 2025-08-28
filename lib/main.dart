import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al Maajid App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WebViewScreen(),
      debugShowCheckedModeBanner: false,
    );

  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  WebViewController? controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Only initialize WebViewController for Android/iOS
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _isLoading = progress < 100;
                });
              }
            },
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
              debugPrint('Page started loading: $url');
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
              debugPrint('Page finished loading: $url');
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
              ''');
            },
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.startsWith('https://almaajid.com/')) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
          ),
        )
        ..loadRequest(Uri.parse('https://almaajid.com/'));

      _clearWebViewCache();
    }
  }

  // Function to clear webview cache
  Future<void> _clearWebViewCache() async {
    await controller?.clearCache();
    await controller?.clearLocalStorage();
    debugPrint('WebView cache and local storage cleared.');
  }

  @override
  Widget build(BuildContext context) {
    // Fallback for Web / Desktop
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text(
            "WebView is only supported on Android and iOS.\n\n"
            "Please open https://almaajid.com in your browser.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Mobile (Android / iOS)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Al Maajid'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller?.reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await controller!.canGoBack()) {
                controller!.goBack();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No back history item')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () async {
              if (await controller!.canGoForward()) {
                controller!.goForward();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No forward history item')),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (controller != null) WebViewWidget(controller: controller!),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
