all: platform sdk

clean:
	rm -rf repo exportrepo
	sudo rm -fr buildroot buildroot-prepare .commit-*

PROXY=
VERSION=1
ARCH=x86_64

repo/config:
	ostree init --repo=repo --mode=bare-user

exportrepo/config:
	ostree init --repo=exportrepo --mode=archive-z2

repo/refs/heads/base/org.openSUSE.Platform/$(ARCH)/$(VERSION): repo/config tumbleweed.kiwi config.sh
	sudo rm -rf buildroot
	sudo kiwi --profile="runtime" system prepare --root=$$PWD/buildroot --description=$$PWD
	sudo ./prepare-to-ostree.sh
	sudo ostree --repo=repo commit -s 'initial build' -b base/org.openSUSE.Platform/$(ARCH)/$(VERSION) --tree=dir=$$PWD/buildroot-prepare
	sudo chown -R `whoami` repo

repo/refs/heads/base/org.openSUSE.Sdk/$(ARCH)/$(VERSION): repo/config tumbleweed.kiwi config.sh
	sudo rm -rf buildroot
	sudo kiwi --profile="sdk" system prepare --root=$$PWD/buildroot --description=$$PWD
	sudo ./prepare-to-ostree.sh
	sudo ostree --repo=repo commit -s 'initial build' -b base/org.openSUSE.Sdk/$(ARCH)/$(VERSION) --tree=dir=$$PWD/buildroot-prepare
	sudo chown -R `whoami` repo

repo/refs/heads/runtime/org.openSUSE.Platform/$(ARCH)/$(VERSION): repo/refs/heads/base/org.openSUSE.Platform/$(ARCH)/$(VERSION) metadata.platform
	./commit-subtree.sh base/org.openSUSE.Platform/$(ARCH)/$(VERSION) runtime/org.openSUSE.Platform/$(ARCH)/$(VERSION) metadata.platform /usr files /etc files/etc

repo/refs/heads/runtime/org.openSUSE.Sdk/$(ARCH)/$(VERSION): repo/refs/heads/base/org.openSUSE.Sdk/$(ARCH)/$(VERSION) metadata.sdk
	./commit-subtree.sh base/org.openSUSE.Sdk/$(ARCH)/$(VERSION) runtime/org.openSUSE.Sdk/$(ARCH)/$(VERSION) metadata.sdk /usr files /etc files/etc

exportrepo/refs/heads/runtime/org.openSUSE.Platform/$(ARCH)/$(VERSION): repo/refs/heads/runtime/org.openSUSE.Platform/$(ARCH)/$(VERSION) exportrepo/config
	ostree pull-local --repo=exportrepo repo runtime/org.openSUSE.Platform/$(ARCH)/$(VERSION)
	flatpak build-update-repo exportrepo

exportrepo/refs/heads/runtime/org.openSUSE.Sdk/$(ARCH)/$(VERSION): repo/refs/heads/runtime/org.openSUSE.Sdk/$(ARCH)/$(VERSION) exportrepo/config
	ostree pull-local --repo=exportrepo repo runtime/org.openSUSE.Sdk/$(ARCH)/$(VERSION)
	flatpak build-update-repo exportrepo

platform: exportrepo/refs/heads/runtime/org.openSUSE.Platform/$(ARCH)/$(VERSION)

sdk: exportrepo/refs/heads/runtime/org.openSUSE.Sdk/$(ARCH)/$(VERSION)

