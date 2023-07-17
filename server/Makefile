.PHONY: clean get codegen build run outdated format

clean:
	@dart run build_runner clean
	@rm -rf bin/main.dart

get:
	@dart pub get

codegen: get
	@dart run build_runner build --delete-conflicting-outputs

build: codegen
	@dart compile exe bin/main.dart -o build/server

run: build
	@./build/server --address=127.0.0.1 --port=8080 --isolates=4

outdated:
	@dart pub outdated --dev-dependencies --up-to-date --dependency-overrides --prereleases --show-all

format:
	@echo "Formatting the code"
	@dart format -l 120 --fix .
	@dart fix --apply .