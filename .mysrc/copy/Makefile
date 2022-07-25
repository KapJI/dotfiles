all: copy

clean:
	rm -rf copy.dSYM copy

copy: impbcopy.m
	gcc -Wall -g -O3 -ObjC -framework Foundation -framework AppKit -o copy impbcopy.m

install:
	cp copy ~/bin/copy
