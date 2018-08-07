# COMMON
Advance some ideas using Steve Wozniak's SWEET16 interpreted byte-code language as inspiration.
While the goal of SWEET16 was brevity, the goal of COMMON is functionality.

To build:
```cd common-post-process ; make ; cp common-post-process ../common ; cd ..
cd common ; make ; cp system.obj ../emulator
cd emulator ; make ; cd ..```

To run:
```cd emulator ; ./emulator < system.obj```
