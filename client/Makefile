.PHONY: clean get codegen build run outdated format

clean:
	@dart run build_runner clean

get:
	@dart pub get

codegen: get
	@dart run build_runner build --delete-conflicting-outputs

build: codegen
	@dart compile exe bin/client.dart -o build/client

run: build
	@./build/client --count=10000

outdated:
	@dart pub outdated --dev-dependencies --up-to-date --dependency-overrides --prereleases --show-all

format:
	@dart format -l 120 --fix .
	@dart fix --apply .