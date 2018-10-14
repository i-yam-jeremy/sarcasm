NASM=nasm
EXECUTABLE=sarcasm
SOURCE=sarcasm.s


all: $(EXECUTABLE)

$(EXECUTABLE) : $(SOURCE)
	$(NASM) -g -f $(TARGET_FORMAT) $(SOURCE) -o sarcasm.o
	ld -e _main -no_pie -arch x86_64 sarcasm.o -lSystem -o $(EXECUTABLE)
