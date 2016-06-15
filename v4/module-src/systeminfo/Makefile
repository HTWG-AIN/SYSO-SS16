ifeq ($(PROGRAMS_DIR),)
PROGRAMS_DIR := .
endif

CC=$(CROSS_COMPILE)gcc

systeminfo: systeminfo.c
	$(CC) --static systeminfo.c -o $(PROGRAMS_DIR)/systeminfo

clean:
	rm -f systeminfo

all: systeminfo
