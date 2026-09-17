import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class MyProviderObserver extends ProviderObserver {
  String _info(ProviderObserverContext ctx) =>
      ctx.provider.name ?? ctx.provider.runtimeType.toString();

  @override
  void didUpdateProvider(
      ProviderObserverContext context,
      Object? previousValue,
      Object? newValue,
      ) {
    debugPrint('🔁 Provider updated: ${_info(context)}');
    debugPrint('➡️  New value: $newValue');
  }

  @override
  void providerDidFail(
      ProviderObserverContext context,
      Object error,
      StackTrace stackTrace,
      ) {
    debugPrint('🔁 Provider failed: ${_info(context)}');
    debugPrint('➡️  Error: $error');
    debugPrint('     $stackTrace');
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    debugPrint('➕ Provider added: ${_info(context)}');
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    debugPrint('🗑️ Provider disposed: ${_info(context)}');
  }
}
