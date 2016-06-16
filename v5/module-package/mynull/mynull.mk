MYNULL_NAME = mynull
MYNULL_VERSION = 1.0
MYNULL_SITE_METHOD = file
MYNULL_SOURCE = $(MYNULL_NAME)-$(MYNULL_VERSION).tar.gz
MYNULL_SITE = ./dl/$(MYNULL_SOURCE)
TEMPALTE_INSTALL_TARGET = YES

define MYNULL_INSTALL_TARGET_CMDS
	$(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) M=$(@D) modules_install
	$(INSTALL) -m 0755 -D $(@D)/test_$(MYNULL_NAME).sh $(TARGET_DIR)/usr/bin/test_$(MYNULL_NAME).sh
endef

$(eval $(kernel-module))
$(eval $(generic-package))