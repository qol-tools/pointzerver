.PHONY: help build run check test clean release install

help:
	@echo "PointZerver - Rust server for remote PC control"
	@echo ""
	@echo "Commands:"
	@echo "  make build    - Build debug binary"
	@echo "  make release  - Build release binary"
	@echo "  make run      - Run server in debug mode"
	@echo "  make check    - Check code without building"
	@echo "  make test     - Run Rust tests"
	@echo "  make clean    - Clean build artifacts"
	@echo "  make install  - Install release binary to /usr/local/bin"

build:
	cargo build

release:
	cargo build --release

run:
	RUST_LOG=info cargo run

check:
	cargo check

test:
	cargo test

clean:
	cargo clean

install: release
	sudo cp target/release/pointzerver /usr/local/bin/
	@echo "Installed pointzerver to /usr/local/bin/"
