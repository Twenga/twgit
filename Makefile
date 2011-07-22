#!/bin/sh

# Install: sudo make install --always-make

ROOT_DIR="`pwd`"

all:
	@echo "usage: make install"
	@echo "       make uninstall"

install:
	echo '#!/bin/bash' > /usr/local/bin/twgit
	echo '/bin/bash "'${ROOT_DIR}'/twgit" $$@' >> /usr/local/bin/twgit
	chmod 0755 /usr/local/bin/twgit
	ln -s ${ROOT_DIR}/install/.bash_completion /etc/bash_completion.d/twgit

uninstall:
	rm -f ${PREFIX}/bin/twgit
	rm -f /etc/bash_completion.d/twgit
