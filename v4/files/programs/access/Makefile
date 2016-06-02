ifeq ($(PROGRAMS_DIR),)
PROGRAMS_DIR := .
endif

CC=gcc

access: access.c
	$(CC) --static -g -pthread access.c -o $(PROGRAMS_DIR)/access

clean:
	rm -f access

all: access
