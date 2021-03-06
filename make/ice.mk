###########################################################
#
# ice
#
###########################################################

#
# ICE_VERSION, ICE_SITE and ICE_SOURCE define
# the upstream location of the source code for the package.
# ICE_DIR is the directory which is created when the source
# archive is unpacked.
#
ICE_SITE=http://xorg.freedesktop.org/releases/individual/lib
ICE_SOURCE=libICE-$(ICE_VERSION).tar.gz
ICE_VERSION=1.0.9
ICE_FULL_VERSION=release-$(ICE_VERSION)
ICE_DIR=libICE-$(ICE_VERSION)
ICE_MAINTAINER=NSLU2 Linux <nslu2-linux@yahoogroups.com>
ICE_DESCRIPTION=X inter-client library
ICE_SECTION=lib
ICE_PRIORITY=optional
ICE_DEPENDS=x11

#
# ICE_IPK_VERSION should be incremented when the ipk changes.
#
ICE_IPK_VERSION=1

#
# ICE_CONFFILES should be a list of user-editable files
ICE_CONFFILES=

#
# ICE_PATCHES should list any patches, in the the order in
# which they should be applied to the source code.
#
#ICE_PATCHES=$(ICE_SOURCE_DIR)/autogen.sh.patch

#
# If the compilation of the package requires additional
# compilation or linking flags, then list them here.
#
ICE_CPPFLAGS=
ICE_LDFLAGS=

#
# ICE_BUILD_DIR is the directory in which the build is done.
# ICE_SOURCE_DIR is the directory which holds all the
# patches and ipkg control files.
# ICE_IPK_DIR is the directory in which the ipk is built.
# ICE_IPK is the name of the resulting ipk files.
#
# You should not change any of these variables.
#
ICE_BUILD_DIR=$(BUILD_DIR)/ice
ICE_SOURCE_DIR=$(SOURCE_DIR)/ice
ICE_IPK_DIR=$(BUILD_DIR)/ice-$(ICE_FULL_VERSION)-ipk
ICE_IPK=$(BUILD_DIR)/ice_$(ICE_FULL_VERSION)-$(ICE_IPK_VERSION)_$(TARGET_ARCH).ipk

#
# Automatically create a ipkg control file
#
$(ICE_IPK_DIR)/CONTROL/control:
	@$(INSTALL) -d $(ICE_IPK_DIR)/CONTROL
	@rm -f $@
	@echo "Package: ice" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(ICE_PRIORITY)" >>$@
	@echo "Section: $(ICE_SECTION)" >>$@
	@echo "Version: $(ICE_FULL_VERSION)-$(ICE_IPK_VERSION)" >>$@
	@echo "Maintainer: $(ICE_MAINTAINER)" >>$@
	@echo "Source: $(ICE_SITE)/$(ICE_SOURCE)" >>$@
	@echo "Description: $(ICE_DESCRIPTION)" >>$@
	@echo "Depends: $(ICE_DEPENDS)" >>$@

#
# This is the dependency on the source code.  If the source is missing,
# then it will be fetched from the site using wget.
#
$(DL_DIR)/$(ICE_SOURCE):
	$(WGET) -P $(@D) $(ICE_SITE)/$(@F) || \
	$(WGET) -P $(@D) $(SOURCES_NLO_SITE)/$(@F)

ice-source: $(DL_DIR)/$(ICE_SOURCE) $(ICE_PATCHES)

#
# This target also configures the build within the build directory.
# Flags such as LDFLAGS and CPPFLAGS should be passed into configure
# and NOT $(MAKE) below.  Passing it to configure causes configure to
# correctly BUILD the Makefile with the right paths, where passing it
# to Make causes it to override the default search paths of the compiler.
#
# If the compilation of the package requires other packages to be staged
# first, then do that first (e.g. "$(MAKE) <bar>-stage <baz>-stage").
#
$(ICE_BUILD_DIR)/.configured: $(DL_DIR)/$(ICE_SOURCE) \
		$(ICE_PATCHES) make/ice.mk
	$(MAKE) xproto-stage
	$(MAKE) xtrans-stage
	$(MAKE) x11-stage
	rm -rf $(BUILD_DIR)/$(ICE_DIR) $(@D)
	tar -C $(BUILD_DIR) -xzf $(DL_DIR)/$(ICE_SOURCE)
	if test -n "$(ICE_PATCHES)" ; \
		then cat $(ICE_PATCHES) | \
		$(PATCH) -d $(BUILD_DIR)/$(ICE_DIR) -p1 ; \
	fi
	if test "$(BUILD_DIR)/$(ICE_DIR)" != "$(ICE_BUILD_DIR)" ; \
		then mv $(BUILD_DIR)/$(ICE_DIR) $(ICE_BUILD_DIR) ; \
	fi
	(cd $(ICE_BUILD_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		CPPFLAGS="$(STAGING_CPPFLAGS) $(ICE_CPPFLAGS)" \
		LDFLAGS="$(STAGING_LDFLAGS) $(ICE_LDFLAGS)" \
		PKG_CONFIG_PATH="$(STAGING_LIB_DIR)/pkgconfig" \
		PKG_CONFIG_LIBDIR="$(STAGING_LIB_DIR)/pkgconfig" \
		./configure \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--target=$(GNU_TARGET_NAME) \
		--prefix=$(TARGET_PREFIX) \
		--disable-static \
	)
	$(PATCH_LIBTOOL) $(ICE_BUILD_DIR)/libtool
	touch $@

ice-unpack: $(ICE_BUILD_DIR)/.configured

#
# This builds the actual binary.
#
$(ICE_BUILD_DIR)/.built: $(ICE_BUILD_DIR)/.configured
	rm -f $@
	$(MAKE) -C $(ICE_BUILD_DIR)
	touch $@

#
# This is the build convenience target.
#
ice: $(ICE_BUILD_DIR)/.built

#
# If you are building a library, then you need to stage it too.
#
$(ICE_BUILD_DIR)/.staged: $(ICE_BUILD_DIR)/.built
	rm -f $@
	$(MAKE) -C $(ICE_BUILD_DIR) DESTDIR=$(STAGING_DIR) install
	sed -ie 's|^prefix=.*|prefix=$(STAGING_PREFIX)|' \
		$(STAGING_LIB_DIR)/pkgconfig/ice.pc
	rm -f $(STAGING_LIB_DIR)/libICE.la
	touch $@

ice-stage: $(ICE_BUILD_DIR)/.staged

#
# This builds the IPK file.
#
$(ICE_IPK): $(ICE_BUILD_DIR)/.built
	rm -rf $(ICE_IPK_DIR) $(BUILD_DIR)/ice_*_$(TARGET_ARCH).ipk
	$(MAKE) -C $(ICE_BUILD_DIR) DESTDIR=$(ICE_IPK_DIR) install-strip
	$(MAKE) $(ICE_IPK_DIR)/CONTROL/control
	rm -f $(ICE_IPK_DIR)$(TARGET_PREFIX)/lib/*.la
	cd $(BUILD_DIR); $(IPKG_BUILD) $(ICE_IPK_DIR)

#
# This is called from the top level makefile to create the IPK file.
#
ice-ipk: $(ICE_IPK)

#
# This is called from the top level makefile to clean all of the built files.
#
ice-clean:
	rm -f $(ICE_BUILD_DIR)/.built
	-$(MAKE) -C $(ICE_BUILD_DIR) clean

#
# This is called from the top level makefile to clean all dynamically created
# directories.
#
ice-dirclean:
	rm -rf $(BUILD_DIR)/$(ICE_DIR) $(ICE_BUILD_DIR) $(ICE_IPK_DIR) $(ICE_IPK)
