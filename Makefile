# Makefile

# --- Configuration ---
# Get git commit hash and date
GIT_COMMIT := $(shell git rev-parse --short HEAD)
GIT_DATE   := $(shell git log -1 --format=%cd --date=format:'%Y%m%d-%H%M%S')
VERSION    := $(GIT_COMMIT)-$(GIT_DATE)

# Go build flags to embed the version
LDFLAGS    := -ldflags="-X 'main.Version=$(VERSION)'"

# Find flutter executable and fail if not found
FLUTTER := $(shell which flutter)
ifeq ($(FLUTTER),)
$(error "The 'flutter' command was not found. Please ensure the Flutter SDK is in your PATH.")
endif

# Directories and names
CLIENT_DIR := client
SERVER_DIR := server
BINARY_NAME:= prismdb-server

# --- Build Targets ---

.PHONY: all build clean client-build server-build proto

all: build

# Target to compile and copy protofiles
proto:
	@echo ">>> Generating Proto buffers..."
	mkdir -p $(SERVER_DIR)/communication
	mkdir -p $(CLIENT_DIR)/lib/communication
	protoc --proto_path=interface \
		--go_out=$(SERVER_DIR) --go_opt=module=istDocument/server \
		--go-grpc_out=$(SERVER_DIR) --go-grpc_opt=module=istDocument/server \
		interface/*.proto
	protoc --proto_path=interface \
		--dart_out=grpc:$(CLIENT_DIR)/lib/communication \
		interface/*.proto

# Main build target
build: client-build server-build

# Target to build the Flutter web client
client-build:
	@echo ">>> Building Flutter web client for offline deployment..."
	(cd $(CLIENT_DIR) && $(FLUTTER) build web --no-web-resources-cdn)
	@echo ">>> Copying web assets to server..."
	rm -rf $(SERVER_DIR)/web
	cp -r $(CLIENT_DIR)/build/web $(SERVER_DIR)/web

# Target to build the Go server
server-build:
	@echo ">>> Building Go server with version $(VERSION)..."
	(cd $(SERVER_DIR) && go build $(LDFLAGS) -o ../$(BINARY_NAME))
	@echo ">>> Build complete: ../$(BINARY_NAME)"

# Target to clean up build artifacts
clean:
	@echo ">>> Cleaning up..."
	rm -rf $(CLIENT_DIR)/build
	rm -rf $(SERVER_DIR)/web
	rm -f $(BINARY_NAME)
