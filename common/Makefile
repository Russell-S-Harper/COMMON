TGT=common
XAPP=../xa-pre-process/xapp

system.obj: $(TGT).obj appl.obj
	cat $(TGT).obj appl.obj > system.obj

$(TGT).obj: rom.h $(TGT).h $(TGT).asm
	xa -XASM $(TGT).asm -l $(TGT).lbl -o $(TGT).obj

appl.obj: rom.h macros.h globals.h appl.src
	cpp -P appl.src | $(XAPP) > appl.asm
	xa -XASM appl.asm -l appl.lbl -o appl.obj

globals.h: $(TGT).obj
	grep -E '^(FN_XR|FN_0X|PLS_1|MNS_1|ADDR)' $(TGT).lbl | sed -e 's/, 0, 0x0000//' -e 's/, / = /' -e 's/ 0x/ \x24/' > globals.h

clean:
	rm -f globals.h appl.asm $(TGT).obj appl.obj $(TGT).lbl appl.lbl system.obj
