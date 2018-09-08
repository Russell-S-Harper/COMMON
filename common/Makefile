XAPP=../xa-pre-process/xapp

system.obj: common.obj page6.obj
	cat common.obj page6.obj > system.obj

common.obj: rom.h common.h common.asm
	xa -C -M common.asm -l common.lbl -o common.obj

page6.obj: rom.h macros.h globals.h page6.src
	cpp -P page6.src | $(XAPP) > page6.asm
	xa -C -M page6.asm -l page6.lbl -o page6.obj

globals.h: common.obj
	grep -E -v '^(_|CMN_CD|CMN_DT|FN_FX)' common.lbl | sed -e 's/, 0, 0x0000//' -e 's/, / = /' -e 's/ 0x/ \x24/' > globals.h

clean:
	rm -f globals.h page6.asm common.obj page6.obj common.lbl page6.lbl system.obj
