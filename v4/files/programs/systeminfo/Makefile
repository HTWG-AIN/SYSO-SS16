ifeq ($(PROGRAMS_DIR),)
PROGRAMS_DIR := .
endif

systeminfo: systeminfo.o
	$(CC) --static -lpthread systeminfo.o -o $(PROGRAMS_DIR)/systeminfo
	rm -f *.o

systeminfo.o: systeminfo.c
	$(CC) -c systeminfo.c

clean:
	rm -f *.o systeminfo

all: systeminfo
