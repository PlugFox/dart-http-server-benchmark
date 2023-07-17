import 'dart:async';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:l/l.dart';

typedef _IsolateConfig = ({io.InternetAddress address, int port, int count, SendPort sendPort});

void main([List<String>? args]) => l.capture(
    () => runZonedGuarded(() async {
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
          var i = 0;
          for (final count in payload) {
            final completer = Completer<void>();
            final receivePort = ReceivePort()
              ..listen((msg) {
                switch (msg) {
                  case String msg:
                    l.s(msg); // Message from isolate
                  case true:
                    completer.complete(); // Spawned
                  default:
                    l.e('Unknown message: $msg');
                }
              });
            await Isolate.spawn<_IsolateConfig>(
              _makeRequests,
              (address: config.address, port: config.port, count: count, sendPort: receivePort.sendPort),
              debugName: 'Isolate #$i',
              errorsAreFatal: true,
            );
            await completer.future;
            i++;
          }
          l.i('All isolates spawned.');
          await Future<void>.delayed(const Duration(minutes: 5));
          io.exit(0);
        }, l.e),
    const LogOptions(
      printColors: true,
      outputInRelease: true,
    ));

void _makeRequests(_IsolateConfig config) => runZonedGuarded(() async {
      final client = http.Client();
      final futures = <Future<http.Response>>[];
      for (var i = 0; i < config.count; i++) {
        futures.add(
          client.get(
            Uri.http(
              '${config.address.host}:${config.port}',
              '/long-polling',
              <String, String>{'duration': '120000'},
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      config.sendPort.send(true); // All requests sent
      l.i('Isolate ${Isolate.current.debugName} sent ${config.count} requests.');
      final result = await Future.wait(futures);
      for (final response in result) {
        if (response.statusCode != 200) l.e('Request failed: ${response.statusCode} ${response.reasonPhrase}');
      }
      config.sendPort.send('Isolate ${Isolate.current.debugName} completed ${config.count} requests.');
      await Future<void>.delayed(const Duration(seconds: 1));
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
