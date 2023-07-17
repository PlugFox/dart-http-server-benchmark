.PHONY: clean get codegen build run outdated format

clean:
	@dart run build_runner clean

get:
	@dart pub get

codegen: get
	@dart run build_runner build --delete-conflicting-outputs

# dart compile exe bin/main.dart -o build/server.exe
build: codegen
	@dart compile exe bin/main.dart -o build/server

# ./build/server.exe --address=127.0.0.1 --port=88 --isolates=24 --verbose=3 --environment=local
run: build
	@./build/server --address=127.0.0.1 --port=88 --isolates=24 --verbose=3 --environment=local

outdated:
	@dart pub outdated --dev-dependencies --up-to-date --dependency-overrides --prereleases --show-all

format:
	@dart format -l 120 --fix .
	@dart fix --apply .