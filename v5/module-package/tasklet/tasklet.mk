TASKLET_NAME = tasklet
TASKLET_VERSION = 1.0
TASKLET_SITE_METHOD = file
TASKLET_SOURCE = $(TASKLET_NAME)-$(TASKLET_VERSION).tar.gz
TASKLET_SITE = ./dl/$(TASKLET_SOURCE)
TEMPALTE_INSTALL_TARGET = YES

define TASKLET_INSTALL_TARGET_CMDS
	$(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) M=$(@D) modules_install
	$(INSTALL) -m 0755 -D $(@D)/test_$(TASKLET_NAME).sh $(TARGET_DIR)/usr/bin/test_$(TASKLET_NAME).sh
endef

$(eval $(kernel-module))
$(eval $(generic-package))