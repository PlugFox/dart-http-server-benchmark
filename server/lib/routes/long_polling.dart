import 'dart:async';

import 'package:benchmark_server/common/responses.dart';
import 'package:shelf/shelf.dart' as shelf;

FutureOr<shelf.Response> $longPolling(shelf.Request request) async {
  await Future<void>.delayed(const Duration(milliseconds: 12000));
  return Responses.ok(<String, Object?>{
    'now': DateTime.now().toUtc().toIso8601String(),
  });
}
