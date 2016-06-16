MYZERO_NAME = myzero
MYZERO_VERSION = 1.0
MYZERO_SITE_METHOD = file
MYZERO_SOURCE = $(MYZERO_NAME)-$(MYZERO_VERSION).tar.gz
MYZERO_SITE = ./dl/$(MYZERO_SOURCE)
TEMPALTE_INSTALL_TARGET = YES

define MYZERO_INSTALL_TARGET_CMDS
	$(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) M=$(@D) modules_install
	$(INSTALL) -m 0755 -D $(@D)/test_$(MYZERO_NAME).sh $(TARGET_DIR)/usr/bin/test_$(MYZERO_NAME).sh
endef

$(eval $(kernel-module))
$(eval $(generic-package))