import 'package:flutter/material.dart';
import '../responsive/nano_page_padding.dart';

class NanoScaffold extends StatelessWidget {
  const NanoScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padBody = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool padBody;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: padBody ? NanoPagePadding(child: body) : body,
    );
  }
}
