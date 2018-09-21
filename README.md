# SarcASM
SarcASM is an interpreter for a stack-based language. The interpreter is written in x86 assembly.

## Basic Tutorial
The following is a basic tutorial on how to use the SarcASM language.

### Integer Literals
Simply typing an integer literal such as `10` will push that value to the stack. There are no negative integer literals in SarcASM so one must subtract an integer literal from zero.

### Arithmetic
Once enough values have been pushed to the stack, RPN (Reverse-Polish Notation) / Postfix can be used.
```
10 2 +
```
```
0 17 -
```
```
8 4 *
```
```
32 4 /
```
```
8 3 %
```

### Duplicating Stack Values
To duplicate a value on the stack simply use the operator `@`
```
10 @
```

### Labels
SarcASM is sort-of like assembly with slightly different syntax. There are no functions, there are only labels.  

To define a label use `:labelname` (label names can only consist of lowercase alphabetical characters)
```
:main
  10 2 +
```

To push the address of a label to the stack use `#labelname`
```
:label
  9 3 +
  
:main
  10 #label
```

To call the label as a function (similar to the `call` instruction in assembly where the return address is pushed to the stack) use `#labelname .`
```
:label
  9 3 +
  
:main
  10 #label .
```

To return (similar to the `ret` instruction in assembly) use `~`. This will return to wherever the label was called from, but will keep the stack modifications done by the label. This allows for returning a value (or multiple values) on the stack. Arguments are from the stack before the label was called and can be used in operations and can be duplicated if multiple references are needed.
```
:label
  9 3 + ~
  
:main
  10 #label .
```

### Conditions Jumps
To jump to a label based on the comparison of two stack values, use the operators `=`, `>`, and `<`. The address to jump to is the topmost value in the stack and the values to compare are the two values below it. If the comparison is true, it works the same as calling a label. If the comparison is false, it continues execution. In both cases, all three values (the address and two values to be compared) are popped off the stack before execution continues.
```
:label
  9 3 + ~
  
:main
  10 10 #label =
```

### Example Program
```
:fact
  @ 1 #factbase =
  @ 1 - #fact . * ~
:factbase
  1 ~
:main
  10 #fact .
```
