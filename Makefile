rootfs_dir    := /var/tmp/puavo-os/rootfs
rootfs_mirror := $(shell 					\
	awk '/^\s*deb .+ jessie main.*$$/ {print $$2; exit}'	\
	/etc/apt/sources.list 2>/dev/null)

subdirs       := debs parts
all-subdirs   := $(subdirs:%=.all-%)
clean-subdirs := $(subdirs:%=.clean-%)

.PHONY: all
all: $(all-subdirs)

.PHONY: $(all-subdirs)
$(all-subdirs):
	$(MAKE) -C $(@:.all-%=%)

.PHONY: $(clean-subdirs)
$(clean-subdirs):
	$(MAKE) -C $(@:.clean-%=%) clean

.PHONY: clean
clean: $(clean-subdirs)

.PHONY: help
help:
	@echo 'Puavo OS Build System'
	@echo
	@echo 'Targets:'
	@echo '    all                         -  build all components'
	@echo '    install-build-deps          -  install build dependencies (requires root)'
	@echo '    release                     -  make release commit'
	@echo '    rootfs                      -  build Puavo OS root filesystem directory (requires root)'

.PHONY: install-build-deps
install-build-deps:
	$(MAKE) -C debs install-build-deps

$(rootfs_dir):
	mkdir -p '$(rootfs_dir).tmp'
	debootstrap --arch=amd64 --include=make jessie \
		'$(rootfs_dir).tmp' '$(rootfs_mirror)'
	git clone . '$(rootfs_dir).tmp/usr/local/src/puavo-os'

	echo 'deb [trusted=yes] file:///usr/local/src/puavo-os/debs /' \
		>'$(rootfs_dir).tmp/etc/apt/sources.list.d/puavo-os.list'

	mkdir '$(rootfs_dir).tmp/puavo-os'

	mv '$(rootfs_dir).tmp' '$(rootfs_dir)'

.PHONY: release
release:
	@parts/devscripts/bin/git-update-debian-changelog

.PHONY: rootfs-update
rootfs-update: $(rootfs_dir)
	git                                                             \
		--git-dir='$(rootfs_dir)/usr/local/src/puavo-os/.git'   \
		--work-tree='$(rootfs_dir)/usr/local/src/puavo-os'      \
		fetch origin
	git                                                             \
		--git-dir='$(rootfs_dir)/usr/local/src/puavo-os/.git'   \
		--work-tree='$(rootfs_dir)/usr/local/src/puavo-os'      \
		reset --hard origin/HEAD

	systemd-nspawn -D '$(rootfs_dir)' make -C /usr/local/src/puavo-os update

.PHONY: rootfs-shell
rootfs-shell: $(rootfs_dir)
	systemd-nspawn -D '$(rootfs_dir)'

.PHONY: update
update: /puavo-os
	apt-get update

	apt-get install -V -y				\
		-o Dpkg::Options::="--force-confdef"	\
		-o Dpkg::Options::="--force-confold"	\
		devscripts equivs git

	apt-get dist-upgrade -V -y			\
		-o Dpkg::Options::="--force-confdef"	\
		-o Dpkg::Options::="--force-confold"
