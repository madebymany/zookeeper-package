ZOOKEEPER_VERSION := 3.4.6
ZOOKEEPER_EXTRACT_DIR := zookeeper-$(ZOOKEEPER_VERSION)
ZOOKEEPER_TARBALL := $(ZOOKEEPER_EXTRACT_DIR).tar.gz

ZOOKEEPER_HOME := /var/lib/zookeeper
ZOOKEEPER_SOURCE_URL := http://mirror.vorboss.net/apache/zookeeper/$(ZOOKEEPER_EXTRACT_DIR)/$(ZOOKEEPER_TARBALL)
ZOOKEEPER_CHECKSUM := $(ZOOKEEPER_TARBALL).asc

ZOOKEEPER_CHECKSUM_URL := http://www.eu.apache.org/dist/zookeeper/$(ZOOKEEPER_EXTRACT_DIR)/$(ZOOKEEPER_CHECKSUM)
ZOOKEEPER_KEYS := KEYS
ZOOKEEPER_TEMP_GPG_KEYRING := ./zookeeper-keyring # ./ needed otherwise gpg puts it in ~/.gpg

ZOOKEEPER_CLI_TOOLS := /usr/bin/zk_mt /usr/bin/zk_st

DEPENDENCIES := curl zip
CURL := curl -LSs
GPG := gpg --keyring "$(ZOOKEEPER_TEMP_GPG_KEYRING)" --no-default-keyring

all: apt $(ZOOKEEPER_EXTRACT_DIR) $(ZOOKEEPER_CLI_TOOLS)

apt:
	apt-get update -qq
	apt-get install -qy $(DEPENDENCIES)

$(ZOOKEEPER_TARBALL):
	$(CURL) -o "$(ZOOKEEPER_TARBALL)" "$(ZOOKEEPER_SOURCE_URL)"
	$(CURL) -o "$(ZOOKEEPER_CHECKSUM)" "$(ZOOKEEPER_CHECKSUM_URL)"
	$(CURL) "$(ZOOKEEPER_KEYS)" | $(GPG) --import -
	$(GPG) --verify "$(ZOOKEEPER_CHECKSUM)" "$(ZOOKEEPER_TARBALL)"
	rm "$(ZOOKEEPER_TEMP_GPG_KEYRING)" "$(ZOOKEEPER_TEMP_GPG_KEYRING)~"

$(ZOOKEEPER_EXTRACT_DIR): $(ZOOKEEPER_TARBALL)
	tar -xzf "$(ZOOKEEPER_TARBALL)"

$(ZOOKEEPER_CLI_TOOLS):
	cd $(ZOOKEEPER_EXTRACT_DIR)/src/c && ./configure && $(MAKE) cli_mt && $(MAKE) cli_st

install:
	mkdir -p /etc/sv/zookeeper /etc/sv/zookeeper/log
	cp -R "$(ZOOKEEPER_EXTRACT_DIR)/" "$(ZOOKEEPER_HOME)"
	install -m 0644 -g root -o root "zoo.cfg" "$(ZOOKEEPER_HOME)/conf/zoo.cfg"
	install -m 0755 -g root -o root $(ZOOKEEPER_EXTRACT_DIR)/src/c/cli_mt /usr/bin/zk_mt
	install -m 0755 -g root -o root $(ZOOKEEPER_EXTRACT_DIR)/src/c/cli_st /usr/bin/zk_st
	install -m 0755 -g root -o root etc/sv/zookeeper/run /etc/sv/zookeeper/run
	install -m 0755 -g root -o root etc/sv/zookeeper/log/run /etc/sv/zookeeper/log/run
	install -m 0755 -g root -o root etc/default/zookeeper /etc/default/zookeeper

clean:
	rm -rf "$(ZOOKEEPER_EXTRACT_DIR)" "$(ZOOKEEPER_TARBALL)" "$(ZOOKEEPER_CHECKSUM)"

.PHONY: install clean
