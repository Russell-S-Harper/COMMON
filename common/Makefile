XAPP=../xa-pre-process/xapp

system.obj: common.obj page6.obj
	cat common.obj page6.obj > system.obj

common.obj: rom.h common.h common.asm
	xa -C -M common.asm -l common.lbl -o common.obj

page6.obj: rom.h macros.h page6.src
	cpp -P page6.src | $(XAPP) > page6.asm
	xa -C -M page6.asm -l page6.lbl -o page6.obj

clean:
	rm -f page6.asm common.obj page6.obj common.lbl page6.lbl system.obj
