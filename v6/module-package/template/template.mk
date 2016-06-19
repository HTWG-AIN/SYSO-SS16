TEMPLATE_NAME = template
TEMPLATE_VERSION = 1.0
TEMPLATE_SITE_METHOD = file
TEMPLATE_SOURCE = $(TEMPLATE_NAME)-$(TEMPLATE_VERSION).tar.gz
TEMPLATE_SITE = ./dl
TEMPALTE_INSTALL_TARGET = YES

define TEMPLATE_INSTALL_TARGET_CMDS
	$(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) M=$(@D) modules_install
	$(INSTALL) -m 0755 -D $(@D)/test_$(TEMPLATE_NAME).sh $(TARGET_DIR)/usr/bin/test_$(TEMPLATE_NAME).sh
endef

$(eval $(kernel-module))
$(eval $(generic-package))