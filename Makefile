NASM=/usr/local/Cellar/nasm/2.13.03/bin/nasm
EXECUTABLE=sarcasm
SOURCE=sarcasm.s


all: $(EXECUTABLE)

$(EXECUTABLE) : $(SOURCE)
	$(NASM) -g -f macho64 $(SOURCE) -o sarcasm.o
	ld -e _main -no_pie -macosx_version_min 10.8 -arch x86_64 sarcasm.o -lSystem -o $(EXECUTABLE)
