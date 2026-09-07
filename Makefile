SRC_DIR := src
BIN_DIR := bin

all: $(BIN_DIR)/disk.img

$(BIN_DIR)/boot.bin: $(SRC_DIR)/boot.asm | $(BIN_DIR)
	nasm -f bin $(SRC_DIR)/boot.asm -o $(BIN_DIR)/boot.bin

$(BIN_DIR)/stage2.bin: $(SRC_DIR)/stage2.asm | $(BIN_DIR)
	nasm -f bin $(SRC_DIR)/stage2.asm -o $(BIN_DIR)/stage2.bin

$(BIN_DIR)/disk.img: $(BIN_DIR)/boot.bin $(BIN_DIR)/stage2.bin
	cat $(BIN_DIR)/boot.bin $(BIN_DIR)/stage2.bin > $(BIN_DIR)/disk.img

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

run: $(BIN_DIR)/disk.img
	qemu-system-x86_64 -drive format=raw,file=$(BIN_DIR)/disk.img

clean:
	rm -rf $(BIN_DIR)

.PHONY: all run clean