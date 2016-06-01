CC=gcc

access: access.o
	$(CC) -lpthread access.o -o access

access.o: access.c
	$(CC) -c access.c

clean:
	rm -f *.o access

all: access
