ifeq ($(PROGRAMS_DIR),)
PROGRAMS_DIR := .
endif

access: access.o
	$(CC) --static -lpthread access.o -o $(PROGRAMS_DIR)/access
	rm *.o

access.o: access.c
	$(CC) -c access.c

clean:
	rm -f *.o access

all: access
