ifneq ($(KERNELRELEASE),)
obj-m := timer.o

else
PWD     := $(shell pwd)

default:
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) modules

endif

clean:
	rm -rf .tmp* .*.cmd *.o *.ko *.mod.c Module.symvers modules.order
