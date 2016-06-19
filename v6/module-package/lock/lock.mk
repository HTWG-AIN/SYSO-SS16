LOCK_NAME = lock
LOCK_VERSION = 1.0
LOCK_SITE_METHOD = file
LOCK_SOURCE = $(LOCK_NAME)-$(LOCK_VERSION).tar.gz
LOCK_SITE = ./dl/$(LOCK_SOURCE)
TEMPALTE_INSTALL_TARGET = YES

define LOCK_INSTALL_TARGET_CMDS
	$(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) M=$(@D) modules_install
	$(INSTALL) -m 0755 -D $(@D)/test_$(LOCK_NAME).sh $(TARGET_DIR)/usr/bin/test_$(LOCK_NAME).sh
endef

$(eval $(kernel-module))
$(eval $(generic-package))