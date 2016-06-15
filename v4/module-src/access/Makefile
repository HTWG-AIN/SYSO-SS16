ifeq ($(PROGRAMS_DIR),)
PROGRAMS_DIR := .
endif

CC=$(CROSS_COMPILE)gcc

access: access.c
	$(CC) --static -g -pthread access.c -o $(PROGRAMS_DIR)/access

clean:
	rm -f access

all: access
