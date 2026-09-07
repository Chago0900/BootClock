SRC_DIR := src
BIN_DIR := bin

all: $(BIN_DIR)/boot.bin

$(BIN_DIR)/boot.bin: $(SRC_DIR)/boot.asm | $(BIN_DIR)
	nasm -f bin $(SRC_DIR)/boot.asm -o $(BIN_DIR)/boot.bin

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

run: $(BIN_DIR)/boot.bin
	qemu-system-x86_64 -drive format=raw,file=$(BIN_DIR)/boot.bin

clean:
	rm -rf $(BIN_DIR)

.PHONY: all run clean