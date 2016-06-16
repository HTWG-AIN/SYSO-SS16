WQ_NAME = wq
WQ_VERSION = 1.0
WQ_SITE_METHOD = file
WQ_SITE = $(WQ_NAME)-$(WQ_VERSION).tar.gz

WQ_DEPENDENCIES = linux

define WQ_BUILD_CMDS
	$(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) M=$(@D) modules 
endef

define WQ_INSTALL_TARGET_CMDS
	$(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) M=$(@D) modules_install
	$(INSTALL) -m 0755 -D $(@D)/test_$(WQ_NAME).sh $(TARGET_DIR)/usr/bin/test_$(WQ_NAME).sh
endef

define WQ_CLEAN_CMDS
	$(MAKE) -C $(@D) clean
endef

define WQ_UNINSTALL_TARGET_CMDS
	rm $(TARGET_DIR)/usr/bin/test_$(WQ_NAME).sh
endef

$(eval $(generic-package))
