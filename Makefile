PREFIX=/usr/local
LIBDIR=dropgit
SCRIPTS=dropgit dropgit_monitor dropgit_setup
MODULES=DropGit.pm


install:
	mkdir -p $(PREFIX)/lib/$(LIBDIR)
	mkdir -p $(PREFIX)/bin
	cp $(MODULES) $(PREFIX)/lib/$(LIBDIR)/.
	cp $(SCRIPTS) $(PREFIX)/bin
