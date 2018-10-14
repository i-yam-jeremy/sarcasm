# SarcASM
SarcASM is an interpreter for post-fix basic mathematical operations. The interpreter is written in x64 assembly.

## Building
```
make TARGET_FORMAT=target_format
```
where `target_format` is replaced with a valid 64-bit NASM format

### macOS
```
make TARGET_FORMAT=macho64
```

### Windows
```
make TARGET_FORMAT=win64
```

### Linux
```
make TARGET_FORMAT=elf64
```

## Usage
SarcASM reads input from STDIN. The easiest way to use SarcASM is to use redirect a file into STDIN.  
For example `sarcasm < test.sarc`

## Syntax
SarcASM uses post-fix notation (also known as Reverse-Polish Notation). This means operators occur after the operands.  
For example, `37 48 +`  
The basic arithmetic operators and modulus are supported `+`, `-`, `*`, `/`, `%`. 
Additionally, the `@` operator will duplicate the top element on the stack.  
  
And that's all there is to it. Enjoy playing around with it and feel free to extend it and implement more operators and functionality!
