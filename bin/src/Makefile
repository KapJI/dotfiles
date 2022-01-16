all: copy

clean:
	rm copy

copy: impbcopy.m
	gcc -Wall -g -O3 -ObjC -framework Foundation -framework AppKit -o copy impbcopy.m

install:
	cp copy ~/bin/copy
