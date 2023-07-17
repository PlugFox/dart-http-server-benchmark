# Dart Server Benchmark

## Compile and run the server

```bash
cd server
dart pub get
mkdir -p build
dart compile exe bin/main.dart -o build/server
./build/server --address=127.0.0.1 --port=88 --isolates=24 --verbose=3 --environment=local
```

## Compile and run the client

```bash
cd client
dart pub get
mkdir -p build
dart compile exe bin/main.dart -o build/client
./build/client --address=127.0.0.1 --port=88 --isolates=24 --count=10000
```
