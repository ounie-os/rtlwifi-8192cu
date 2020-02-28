SHELL := /bin/sh
ARCH ?= arm
CROSS_COMPILE ?=
CC ?= gcc
KVER ?= $(shell uname -r)
KSRC ?= /lib/modules/$(KVER)/build
FIRMWAREDIR := /lib/firmware/
PWD := $(shell pwd)
SYMBOL_FILE := Module.symvers

MOD_INSTALL_PATH ?= $(shell pwd)/output

# Handle the move of the entire rtlwifi tree
ifneq ("","$(wildcard /lib/modules/$(KVER)/kernel/drivers/net/wireless/realtek)")
MODDESTDIR := /lib/modules/$(KVER)/kernel/drivers/net/wireless/realtek/rtlwifi
else
MODDESTDIR := /lib/modules/$(KVER)/kernel/drivers/net/wireless/rtlwifi
endif
#Handle the compression option for modules in 3.18+
ifneq ("","$(wildcard $(MODDESTDIR)/*.ko.gz)")
COMPRESS_GZIP := y
endif
ifneq ("","$(wildcard $(MODDESTDIR)/*.ko.xz)")
COMPRESS_XZ := y
endif

EXTRA_CFLAGS += -O2
obj-m := rtlwifi.o
rtlwifi-objs	:=	\
		base.o	\
		cam.o	\
		core.o	\
		debug.o	\
		efuse.o	\
		ps.o	\
		rc.o	\
		regd.o	\
		stats.o

obj-m	+= rtl_usb.o
rtl_usb-objs	:=		usb.o

obj-m	+= rtl8192c/
obj-m	+= rtl8192cu/

ccflags-y += -D__CHECK_ENDIAN__

all:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KSRC) M=$(shell pwd)  modules
	find . -name '*.ko' | xargs $(CROSS_COMPILE)strip --strip-unneeded
	
install:
	[ -d $(MOD_INSTALL_PATH) ] || mkdir -p $(MOD_INSTALL_PATH)
	mkdir -p $(MOD_INSTALL_PATH)/rtl8192c
	mkdir -p $(MOD_INSTALL_PATH)/rtl8192cu
	install -p -D -m 644 rtl_usb.ko $(MOD_INSTALL_PATH)
	install -p -D -m 644 rtlwifi.ko $(MOD_INSTALL_PATH)
	install -p -D -m 644 ./rtl8192c/rtl8192c-common.ko $(MOD_INSTALL_PATH)/rtl8192c
	install -p -D -m 644 ./rtl8192cu/rtl8192cu.ko $(MOD_INSTALL_PATH)/rtl8192cu
	[ -z $(INSTALL_MOD_PATH) ] || $(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KSRC) M=$(shell pwd) INSTALL_MOD_PATH=$(INSTALL_MOD_PATH) modules_install
	
install_old: all
ifeq (,$(wildcard ./backup_drivers.tar))
	@echo Making backups
	@tar cPf backup_drivers.tar $(MODDESTDIR)
endif

	@mkdir -p $(MODDESTDIR)/btcoexist
	@mkdir -p $(MODDESTDIR)/rtl8188ee
	@mkdir -p $(MODDESTDIR)/rtl8192c
	@mkdir -p $(MODDESTDIR)/rtl8192ce
	@mkdir -p $(MODDESTDIR)/rtl8192cu
	@mkdir -p $(MODDESTDIR)/rtl8192de
	@mkdir -p $(MODDESTDIR)/rtl8192ee
	@mkdir -p $(MODDESTDIR)/rtl8192se
	@mkdir -p $(MODDESTDIR)/rtl8723ae
	@mkdir -p $(MODDESTDIR)/rtl8723be
	@mkdir -p $(MODDESTDIR)/rtl8723com
	@mkdir -p $(MODDESTDIR)/rtl8821ae
	@install -p -D -m 644 rtl_pci.ko $(MODDESTDIR)	
	@install -p -D -m 644 rtl_usb.ko $(MODDESTDIR)	
	@install -p -D -m 644 rtlwifi.ko $(MODDESTDIR)
	@install -p -D -m 644 ./btcoexist/btcoexist.ko $(MODDESTDIR)/btcoexist
	@install -p -D -m 644 ./rtl8188ee/rtl8188ee.ko $(MODDESTDIR)/rtl8188ee
	@install -p -D -m 644 ./rtl8192c/rtl8192c-common.ko $(MODDESTDIR)/rtl8192c
	@install -p -D -m 644 ./rtl8192ce/rtl8192ce.ko $(MODDESTDIR)/rtl8192ce
	@install -p -D -m 644 ./rtl8192cu/rtl8192cu.ko $(MODDESTDIR)/rtl8192cu
	@install -p -D -m 644 ./rtl8192de/rtl8192de.ko $(MODDESTDIR)/rtl8192de
	@install -p -D -m 644 ./rtl8192ee/rtl8192ee.ko $(MODDESTDIR)/rtl8192ee
	@install -p -D -m 644 ./rtl8192se/rtl8192se.ko $(MODDESTDIR)/rtl8192se
	@install -p -D -m 644 ./rtl8723ae/rtl8723ae.ko $(MODDESTDIR)/rtl8723ae
	@install -p -D -m 644 ./rtl8723be/rtl8723be.ko $(MODDESTDIR)/rtl8723be
	@install -p -D -m 644 ./rtl8723com/rtl8723-common.ko $(MODDESTDIR)/rtl8723com
	@install -p -D -m 644 ./rtl8821ae/rtl8821ae.ko $(MODDESTDIR)/rtl8821ae
ifeq ($(COMPRESS_GZIP), y)
	@gzip -f $(MODDESTDIR)/*.ko
	@gzip -f $(MODDESTDIR)/btcoexist/*.ko
	@gzip -f $(MODDESTDIR)/rtl8*/*.ko
endif
ifeq ($(COMPRESS_XZ), y)
	@xz -f $(MODDESTDIR)/*.ko
	@xz -f $(MODDESTDIR)/btcoexist/*.ko
	@xz -f $(MODDESTDIR)/rtl8*/*.ko
endif

	@depmod -a $(KVER)

	@#copy firmware images to target folder
	@cp -fr firmware/rtlwifi/ $(FIRMWAREDIR)/
	@echo "Install rtlwifi SUCCESS"

uninstall:
ifneq (,$(wildcard ./backup_drivers.tar))
	@echo Restoring backups
	@tar xvPf backup_drivers.tar
endif
	
	@depmod -a
	
	@echo "Uninstall rtlwifi SUCCESS"

clean:
	@rm -fr *.mod.c *.mod *.o .*.cmd *.ko *~ .*.o.d .cache.mk
	@rm -fr rtl8*/*.mod.c rtl8*/*.mod rtl8*/*.o rtl8*/.*.cmd rtl8*/*.ko rtl8*/*~ rtl8*/*.cmd rtl8*/.*.o.d
	@rm -fr bt*/*.mod.c bt*/*.mod bt*/*.o bt*/.*.cmd bt*/*.ko bt*/*~ bt*/*.cmd bt*/.*.o.d
	@rm -fr .tmp_versions
	@rm -fr Modules.symvers
	@rm -fr Module.symvers
	@rm -fr Module.markers
	@rm -fr modules.order rtl8*/modules.order bt*/modules.order
	rm -fr output/
