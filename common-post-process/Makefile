TGT=common-post-process

$(TGT): main.c $(TGT).h $(TGT).re $(TGT).l $(TGT).y
	re2c -is $(TGT).re -o $(TGT).c
	flex --header-file=$(TGT).yy.h -o $(TGT).yy.c $(TGT).l
	bison -d $(TGT).y
	gcc main.c $(TGT).c $(TGT).tab.c $(TGT).yy.c -lfl -lm -o $(TGT)

clean: 
	rm -f $(TGT).c $(TGT).yy.h $(TGT).yy.c $(TGT).tab.h $(TGT).tab.c
