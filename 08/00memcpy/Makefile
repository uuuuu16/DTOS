
.PHONY : all clean rebuild

SRC := boot.asm
OUT := boot.bin
IMG := data.img

RM := rm -fr

all : $(OUT) $(IMG)
	dd if=$(OUT) of=$(IMG) bs=512 count=1 conv=notrunc
	@echo "Success!"

$(OUT) : $(SRC)
	nasm $^ -o $@

$(IMG) :
	bximage $@ -q -fd -size=1.44

clean :
	$(RM) $(IMG) $(OUT)

rebuild :
	@$(MAKE) clean
	@$(MAKE) all
