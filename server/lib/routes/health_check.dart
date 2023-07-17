import 'dart:async';

import 'package:benchmark_server/common/responses.dart';
import 'package:shelf/shelf.dart' as shelf;

FutureOr<shelf.Response> $healthCheck(shelf.Request request) => Responses.ok(null);
