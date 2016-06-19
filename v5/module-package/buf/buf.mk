BUF_NAME = buf
BUF_VERSION = 1.0
BUF_SITE_METHOD = file
BUF_SOURCE = $(BUF_NAME)-$(BUF_VERSION).tar.gz
BUF_SITE = ./dl
TEMPALTE_INSTALL_TARGET = YES

define BUF_INSTALL_TARGET_CMDS
	$(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) M=$(@D) modules_install
	$(INSTALL) -m 0755 -D $(@D)/test_$(BUF_NAME).sh $(TARGET_DIR)/usr/bin/test_$(BUF_NAME).sh
endef

$(eval $(kernel-module))
$(eval $(generic-package))