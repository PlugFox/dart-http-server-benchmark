import 'dart:async';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:l/l.dart';

typedef _IsolateConfig = ({io.InternetAddress address, int port, int count});

void main([List<String>? args]) => runZonedGuarded(() async {
      final config = _parseArguments(args);
      final isolates = config.isolates.clamp(1, config.count);
      List<int> distributePayload(int total, int isolates) {
        final remainder = total % isolates;
        final distribution = List<int>.filled(isolates, total ~/ isolates);
        for (var i = 0; i < remainder; i++) distribution[i]++;
        return distribution;
      }

      final payload = distributePayload(config.count, isolates);
      l.i('Sending $config.count requests to ${config.address.host}:${config.port} using $isolates isolates.');
      for (final count in payload) {
        Isolate.spawn<_IsolateConfig>(
          _makeRequests,
          (address: config.address, port: config.port, count: count),
          debugName: 'Isolate $count',
          errorsAreFatal: true,
        ).ignore();
      }
    }, l.e);

void _makeRequests(_IsolateConfig config) => runZonedGuarded(() async {
      final client = http.Client();
      final futures = List<Future<void>>.generate(
          config.count, (_) => client.get(Uri.http('${config.address.host}:${config.port}', '/long-polling')));
      await Future.wait(futures);
      l.i('Requests completed.');
      Isolate.exit();
    }, l.e);

({
  io.InternetAddress address,
  int port,
  int isolates,
  int count,
}) _parseArguments(List<String>? arguments) {
  final argResult = (ArgParser()
        ..addOption(
          'address',
          abbr: 'a',
          valueHelp: '127.0.0.1:8080',
          help: 'Address to send requests.',
          defaultsTo:
              io.Platform.environment['ADDRESS'] ?? const String.fromEnvironment('ADDRESS', defaultValue: '127.0.0.1'),
        )
        ..addOption(
          'port',
          abbr: 'p',
          valueHelp: '8080',
          help: 'Port to send requests.',
          defaultsTo: io.Platform.environment['PORT'] ?? const String.fromEnvironment('PORT', defaultValue: '8080'),
        )
        ..addOption(
          'isolates',
          abbr: 'i',
          valueHelp: '6',
          help: 'Number of isolates to run.',
          defaultsTo:
              io.Platform.environment['ISOLATES'] ?? const String.fromEnvironment('ISOLATES', defaultValue: '6'),
        )
        ..addOption(
          'count',
          abbr: 'c',
          valueHelp: '1000',
          help: 'Number of requests to send.',
          defaultsTo: io.Platform.environment['REQUESTS_COUNT'] ??
              const String.fromEnvironment('REQUESTS_COUNT', defaultValue: '1000'),
        ))
      .parse(arguments ?? const <String>[]);
  return (
    address: switch (argResult['address']) {
      'any' => io.InternetAddress.anyIPv4,
      '127.0.0.1' => io.InternetAddress.loopbackIPv4,
      '0.0.0.0' => io.InternetAddress.anyIPv4,
      'loopback' => io.InternetAddress.loopbackIPv4,
      'localhost' => io.InternetAddress.loopbackIPv4,
      'loopbackIPv4' => io.InternetAddress.loopbackIPv4,
      'loopbackIPv6' => io.InternetAddress.loopbackIPv6,
      'anyIPv4' => io.InternetAddress.anyIPv4,
      'anyIPv6' => io.InternetAddress.anyIPv6,
      String address => io.InternetAddress(address),
      _ => io.InternetAddress.anyIPv4,
    },
    port: (int.tryParse(argResult['port']?.toString() ?? '8080') ?? 8080).clamp(0, 65535),
    isolates: switch (int.tryParse(argResult['isolates']?.toString() ?? '6')) {
      int _ && < 1 => io.Platform.numberOfProcessors,
      int i && > 0 => i,
      null || _ => io.Platform.numberOfProcessors,
    },
    count: switch (int.tryParse(argResult['count']?.toString() ?? '1000')) {
      int _ && < 1 => 1000,
      int i && > 0 => i,
      null || _ => 1000,
    },
  );
}
