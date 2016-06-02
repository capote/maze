# exec locations

RASM  = /home/fac/wrc/bin/rasm
RLINK = /home/fac/wrc/bin/rlink
RSIM  = /home/fac/wrc/bin/rsim

.SUFFIXES:	.asm .obj .lst .out

OBJECTS = maze.obj io.obj tools.obj

.asm.obj:
	$(RASM) -l $*.asm > $*.lst

.obj.out:
	$(RLINK) -o $*.out $*.obj

maze.out:	$(OBJECTS)
	$(RLINK) -m -o maze.out $(OBJECTS) > maze.map

run:	maze.out
	$(RSIM) maze.out
