all: build serve

build:
	zig build-lib main.zig -target wasm32-freestanding -dynamic -rdynamic

serve:
	python3 -m http.server
