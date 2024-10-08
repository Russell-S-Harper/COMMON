# COMMON

Advances some ideas using Steve Wozniak’s 6502 SWEET16 interpreted byte-code language as inspiration. While the goal of SWEET16 was brevity, the goal of COMMON is functionality. The intent is to make a platform suitable for many commercial, scientific, and engineering applications.

For example:

* native type is equivalent to fixed-point decimal ±######.###
* easier support for banked memory
* easier support for higher language compilers
* arithmetic operations add, subtract, multiply, divide, and modulus
* inherent overflow/underflow detection
* all control branching is 16-bit relative, for easier relocatable code
* support for custom system/user functions, akin to INT in x86

Why 6502 and not, for example, x86?

* 6502 assembler is very easy and has a large archive of existing functions
* existing 6502 SWEET16 already has the “hard work” done
* interesting to see it run in newer faster versions of 6502 processors
* how do you think [Bender](https://spectrum.ieee.org/the-truth-about-benders-brain) does what he does? (or the [Terminator](https://www.apl2bits.net/2016/07/18/terminator-6502/)!)

Completed:

* added all the instructions (see `common/common.h` for the list)

In progress:

* larger stack size, current stack size is only about 60 numbers, 250 or so would be better
* emulation of serial ports to allow standard I/O
* a unit test suite to ensure each instruction is correct
* a proof-of-concept application with decoupled system and application files

The meat of the project:

* `common/common.h`: details of instructions
* `common/common.asm`: assembler code for the instructions
* `common/macros.h`: macros used to define the interpreted byte-code
* `common/appl.src`: sample source file using the macros

Auxiliary:

* `emulator/*`: 6502 emulator (borrowed Mike Chambers’ Fake6502 CPU emulator v1.1 ©2011)
* `xa-pre-process/*`: my utility `xapp` to convert 32-bit fixed decimal quantities so that `xa` can use them

Right now, for testing purposes, the code builds everything into one file `system.obj` and runs the code in the last block loaded, in this case, the code corresponding to `appl.src`. Eventually will support decoupling of system and application files. Application files will be inherently relocatable.

To build and run:

    make all
    make run

The makefiles use `re2c`, `flex`, `bison`, `gcc`, `cpp`, `xa`, `grep`, and `sed`. Will eventually provide a `./configure`.
