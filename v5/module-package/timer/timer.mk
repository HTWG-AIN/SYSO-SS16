TIMER_NAME = timer
TIMER_VERSION = 1.0
TIMER_SITE_METHOD = file
TIMER_SOURCE = $(TIMER_NAME)-$(TIMER_VERSION).tar.gz
TIMER_SITE = ./dl/$(TIMER_SOURCE)
TEMPALTE_INSTALL_TARGET = YES

define TIMER_INSTALL_TARGET_CMDS
	$(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) M=$(@D) modules_install
	$(INSTALL) -m 0755 -D $(@D)/test_$(TIMER_NAME).sh $(TARGET_DIR)/usr/bin/test_$(TIMER_NAME).sh
endef

$(eval $(kernel-module))
$(eval $(generic-package))