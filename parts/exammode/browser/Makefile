prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
sysconfdir = /etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all: po/de/puavo-exam-browser.mo po/fi/puavo-exam-browser.mo po/sv/puavo-exam-browser.mo

po/puavo-exam-browser.pot: puavo-exam-browser
	xgettext --omit-header --language Python --keyword=_tr -o $@ $^

%.po: po/puavo-exam-browser.pot
	msgmerge --update --no-fuzzy-matching --backup=off $@ $<
	touch $@

%.mo: %.po
	msgfmt $< --output-file $@

.PHONY: i18nupdate
i18nupdate: po/puavo-exam-browser.pot po/de/puavo-exam-browser.po po/fi/puavo-exam-browser.po po/sv/puavo-exam-browser.po

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/locale/de/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/locale/sv/LC_MESSAGES

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-exam-browser
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/de/LC_MESSAGES \
		po/de/puavo-exam-browser.mo
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES \
		po/fi/puavo-exam-browser.mo
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/sv/LC_MESSAGES \
		po/sv/puavo-exam-browser.mo

.PHONY: clean
clean:
	rm -rf po/*/*.mo po/*.pot
