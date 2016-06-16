OPEN_ONCE_NAME = open_once
OPEN_ONCE_VERSION = 1.0
OPEN_ONCE_SITE_METHOD = file
OPEN_ONCE_SOURCE = $(OPEN_ONCE_NAME)-$(OPEN_ONCE_VERSION).tar.gz
OPEN_ONCE_SITE = ./dl/$(OPEN_ONCE_SOURCE)
TEMPALTE_INSTALL_TARGET = YES

define OPEN_ONCE_INSTALL_TARGET_CMDS
	$(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) M=$(@D) modules_install
	$(INSTALL) -m 0755 -D $(@D)/test_$(OPEN_ONCE_NAME).sh $(TARGET_DIR)/usr/bin/test_$(OPEN_ONCE_NAME).sh
endef

$(eval $(kernel-module))
$(eval $(generic-package))