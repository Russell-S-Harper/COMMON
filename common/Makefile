XAPP=../xa-pre-process/xapp

system.obj: common.obj appl.obj
	cat common.obj appl.obj > system.obj

common.obj: rom.h common.h common.asm
	xa -C -M common.asm -l common.lbl -o common.obj

appl.obj: rom.h macros.h globals.h appl.src
	cpp -P appl.src | $(XAPP) > appl.asm
	xa -C -M appl.asm -l appl.lbl -o appl.obj

globals.h: common.obj
	grep -E '^(FN_XR|FN_0X|PLS_1|MNS_1|ADDR)' common.lbl | sed -e 's/, 0, 0x0000//' -e 's/, / = /' -e 's/ 0x/ \x24/' > globals.h

clean:
	rm -f globals.h appl.asm common.obj appl.obj common.lbl appl.lbl system.obj
