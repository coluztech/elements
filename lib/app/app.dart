import 'package:elements/app/router.dart';
import 'package:elements/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ElementShiftApp extends StatelessWidget {
  const ElementShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'Element Shift',
        theme: buildAppTheme(),
        routerConfig: appRouter,
      ),
    );
  }
}
