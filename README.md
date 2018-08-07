# COMMON
Advance some ideas using Steve Wozniak's SWEET16 interpreted byte-code language as inspiration. While the goal of SWEET16 was brevity, the goal of COMMON is functionality.

To build and run:
`cd common-post-process ; make ; cp common-post-process ../common ; cd ..`
`cd common ; make ; cd ..`
`cd emulator ; make ; ./emulator < ../common/system.obj`

The makefiles use `re2c`, `flex`, `bison`, `gcc`, `cpp`, and `xa`.
