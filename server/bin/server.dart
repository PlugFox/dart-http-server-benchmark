import 'dart:async';
import 'dart:io' as io;

import 'package:benchmark_server/common/constant.dart';
import 'package:benchmark_server/common/cors.dart';
import 'package:benchmark_server/common/handle_errors.dart';
import 'package:benchmark_server/common/injector.dart';
import 'package:benchmark_server/common/log_pipeline.dart';
import 'package:benchmark_server/common/run_server.dart';
import 'package:benchmark_server/routes/health_check.dart';
import 'package:benchmark_server/routes/home.dart';
import 'package:benchmark_server/routes/not_found.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

void main([List<String>? args]) => runServer(
      config: null,
      serve: _serve,
      arguments: args,
    );

Future<void> _serve(io.InternetAddress address, int port, [config]) async {
  final pipeline = const shelf.Pipeline()
      .addMiddleware(handleErrors(showStackTrace: kDebugMode))
      .addMiddleware(logPipeline())
      .addMiddleware(cors())
      /* .addMiddleware(authorization()) */
      .addMiddleware(injector(<String, Object>{}))
      .addHandler($router);
  await shelf_io.serve(
    pipeline,
    address,
    port,
    poweredByHeader: 'Benchmark Server',
    shared: true,
  );
}

final shelf.Handler $router = Router(notFoundHandler: $notFound)
  ..get('/', $home)
  ..get('/health', $healthCheck);
