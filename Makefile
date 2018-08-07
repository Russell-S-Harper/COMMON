all:
	cd common-post-process ; make ; cd ..
	cd common ; make ; cd ..
	cd emulator ; make ; cd ..

run:
	./emulator/emulator < common/system.obj

clean:
	cd common-post-process ; make clean ; cd ..
	cd common ; make clean ; cd ..
	cd emulator ; make clean ; cd ..
