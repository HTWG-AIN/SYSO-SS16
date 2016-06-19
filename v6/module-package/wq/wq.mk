WQ_NAME = wq
WQ_VERSION = 1.0
WQ_SITE_METHOD = file
WQ_SOURCE = $(WQ_NAME)-$(WQ_VERSION).tar.gz
WQ_SITE = ./dl/$(WQ_SOURCE)
TEMPALTE_INSTALL_TARGET = YES

define WQ_INSTALL_TARGET_CMDS
	$(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) M=$(@D) modules_install
	$(INSTALL) -m 0755 -D $(@D)/test_$(WQ_NAME).sh $(TARGET_DIR)/usr/bin/test_$(WQ_NAME).sh
endef

$(eval $(kernel-module))
$(eval $(generic-package))