/// App in debug mode
const bool kDebugMode = !kReleaseMode;

/// Whether the application is running in release mode
const bool kReleaseMode = bool.fromEnvironment('dart.vm.product');
