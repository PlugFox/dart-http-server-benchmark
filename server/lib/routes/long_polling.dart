import 'dart:async';

import 'package:benchmark_server/common/responses.dart';
import 'package:shelf/shelf.dart' as shelf;

FutureOr<shelf.Response> $longPolling(shelf.Request request) async {
  final ms = switch (request.url.queryParameters['duration']) {
    String value => int.tryParse(value) ?? 12000,
    _ => 12000,
  };
  await Future<void>.delayed(Duration(milliseconds: ms));
  return Responses.ok(<String, Object?>{
    'now': DateTime.now().toUtc().toIso8601String(),
  });
}
