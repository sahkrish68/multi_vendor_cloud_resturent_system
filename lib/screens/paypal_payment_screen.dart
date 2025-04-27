import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PayPalPaymentScreen extends StatefulWidget {
  final double totalAmount;
  final Function(bool) onFinish; // callback if payment success or fail

  const PayPalPaymentScreen({Key? key, required this.totalAmount, required this.onFinish}) : super(key: key);

  @override
  State<PayPalPaymentScreen> createState() => _PayPalPaymentScreenState();
}

class _PayPalPaymentScreenState extends State<PayPalPaymentScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://sandbox.paypal.com'))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('success')) {
              widget.onFinish(true);
              Navigator.pop(context);
              return NavigationDecision.prevent;
            } else if (request.url.contains('cancel')) {
              widget.onFinish(false);
              Navigator.pop(context);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pay with PayPal'),
      ),
      body: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}
