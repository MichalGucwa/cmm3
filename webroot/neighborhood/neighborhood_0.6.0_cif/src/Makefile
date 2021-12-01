SYSTEM_NAME="NEIGHBORHOOD"
CC = gcc
LIBS = -lm


EXEC = neighborhood
HDRS = util.h csymlib.h PDBheader.h AtomInfo.h Hash.h main.h
OBJECTS = util.o csymlib.o PDBheader.o AtomInfo.o Hash.o main.o

$(EXEC): $(OBJECTS)
	${CC} -o $(EXEC) $(OBJECTS) $(LIBS)

util.o:		util.c util.h
csymlib.o:	csymlib.c csymlib.h
PDBheader.o:	PDBheader.c PDBheader.h main.h
AtomInfo.o:	AtomInfo.c AtomInfo.h main.h
Hash.o: 	Hash.c Hash.h
main.o: 	main.c main.h csymlib.h

.PHONY: clean
clean:
	rm *.o neighborhood

