ACCESS_NAME = access
ACCESS_VERSION = 1.0
ACCESS_SITE_METHOD = file
ACCESS_SITE = $(ACCESS_NAME)-$(ACCESS_VERSION).tar.gz

ACCESS_DEPENDENCIES = linux

define ACCESS_BUILD_CMDS
	$(MAKE) CC="$(TARGET_CC)" LD="$(TARGET_LD)" -C $(@D) all
endef

define ACCESS_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/$(ACCESS_NAME) $(TARGET_DIR)/usr/bin/$(ACCESS_NAME)
endef

define ACCESS_CLEAN_CMDS
	$(MAKE) -C $(@D) clean
endef

define ACCESS_UNINSTALL_TARGET_CMDS
	rm $(TARGET_DIR)/usr/bin/$(ACCESS_NAME)
endef

$(eval $(generic-package))
