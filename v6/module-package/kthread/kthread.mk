KTHREAD_NAME = kthread
KTHREAD_VERSION = 1.0
KTHREAD_SITE_METHOD = file
KTHREAD_SOURCE = $(KTHREAD_NAME)-$(KTHREAD_VERSION).tar.gz
KTHREAD_SITE = ./dl
TEMPALTE_INSTALL_TARGET = YES

define KTHREAD_INSTALL_TARGET_CMDS
	$(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) M=$(@D) modules_install
	$(INSTALL) -m 0755 -D $(@D)/test_$(KTHREAD_NAME).sh $(TARGET_DIR)/usr/bin/test_$(KTHREAD_NAME).sh
endef

$(eval $(kernel-module))
$(eval $(generic-package))