
UNAME       = $(shell uname)

BREWTOOLS   = ack bash bash-completion@2 git git-lfs mtr nmap node openssl p7zip perl pstree sqlite vim w3m wget
BREWTOOLS  += ant@1.9 freetds jenv unixodbc
BREWTOOLS  += idutils
BREWTOOLS  += inetutils                         # ftp (uses .netrc)
BREWTOOLS  += mysql                             # mysql-client is tap-only

CASKTOOLS   = basictex google-chrome dropbox iterm2 libreoffice xquartz
CASKTOOLS  += eclipse-java java java6 java11 adoptopenjdk8

TAPS        = homebrew/services keith/formulae
TAPS       += caskroom/versions     # java6

DOTFILES    = .bash_login .bashrc

# $^  All dependencies
# $@  Target name
# $*
# $>
# $<
# $!

DROPBOX_LINK  = .gitconfig .netrc .screenrc .vimrc .vim/autoload
DROPBOX_COPY  = .dataprinter
DROPBOX_FILES = $(DROPBOX_LINK) $(DROPBOX_COPY)

.PHONY: $(DOTFILES) $(DROPBOX_FILES) sudoers-local

default: os_$(UNAME) locate bash dropbox perlbrew cpanm sudoers-local $(DROPBOX_FILES) ~/.vim/bundle/Vundle.vim/.git

env:
	@echo "BREWTOOLS $(BREWTOOLS)"
	@echo "CASKTOOLS $(CASKTOOLS)"
	@echo "TAPS      $(TAPS)"

os_Darwin: taps brewtools casktools brewinfo locate

jenv_Darwin:
	@for i in /Library/Java/JavaVirtualMachines/*/Contents/Home; do \
		jenv add "$$i"; \
	done; \
	jenv versions

show:
	@echo "BREWTOOLS $(BREWTOOLS)"
	@echo "CASKTOOLS $(CASKTOOLS)"
	@echo "TAPS      $(TAPS)"

FORCE:  # Pattern rules don't play nicely with .PHONY

.vim/autoload: FORCE ~/.vim

~/%: FORCE
	@[ -e $@ ] || mkdir -p $@
	@if [ ! -d $@ ]; then echo "$@ is not a directory"; exit 1; fi

locate: os_$(UNAME)_locate

os_Darwin_locate: sudoers-local
	sudo launchctl list com.apple.locate || sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist

cpanm: perlbrew; @[ -x "$$PERLBREW_ROOT/bin/cpanm" ] || perlbrew install-cpanm

perlbrew:      ; @which -s perlbrew || curl -L https://install.perlbrew.pl | bash

homebrew:      ; @which -s brew || ruby -e "$$(curl -fsSL https:///raw.githubusercontent.com/Homebrew/install/master/install)"

_brew:
	@echo "$$TITLE:"
	@for wanted in $$WANTED; do \
		if echo "$$INSTALLED" | egrep -q -E "^$$wanted$$"; then \
			printf "  %-20s installed\n" "$$wanted"; \
		else \
			brew $$CMD "$$wanted"; \
		fi; \
	done; echo

taps:       homebrew; @$(MAKE) _brew TITLE="homebrew taps"  WANTED="$(TAPS)"      CMD="tap"         INSTALLED="`brew tap`"

brewtools:  homebrew; @$(MAKE) _brew TITLE="homebrew tools" WANTED="$(BREWTOOLS)" CMD="install"     INSTALLED="`brew list`"

casktools:  homebrew; @$(MAKE) _brew TITLE="homebrew casks" WANTED="$(CASKTOOLS)" CMD="cask instal" INSTALLED="`brew cask list`"

brewinfo:       homebrew
	@echo "info files:"
	@find -L /usr/local/Cellar -name info -type d -print | sort | while read dir; do \
		find -L $$dir -name '*.info*' -print | while read path; do \
			file=`basename $$path`; \
			if [ -e "/usr/local/info/$$file" ]; then \
				if ! cmp --quiet /usr/local/info/$$file $$path; then \
					echo "$$path conflicts with /usr/local/info/$$file"; \
					exit 1; \
				fi; \
			else \
				ln -s $$path /usr/local/info; \
			fi; \
			printf "  %-78s ok\n" "$$path"; \
		done; \
	done

dropbox:
	@[ -L $(HOME)/Dropbox ] || ln -s /usr/local/Dropbox $(HOME)/Dropbox
	@[ -e $(HOME)/Dropbox ] || open /Applications/Dropbox.app

bash: ~/.bash_hist $(DOTFILES)
	@if [ "$$SHELL" != "/usr/local/bin/bash" ]; then \
		echo "SHELL is $$SHELL: use chsh(1)"; \
		exit 1; \
	fi

$(DOTFILES):                    ;           @$(MAKE)      copy_file_to_dir FILE=$@ SRC=. DST=~

sudoers-local:                  ;           @sudo $(MAKE) copy_file_to_dir FILE=$@ SRC=. DST=/etc/sudoers.d

$(DROPBOX_LINK):                dropbox;    @$(MAKE)      link_file_to_dir FILE=$@ SRC=~/Dropbox/Hosts/ALL DST=~

$(DROPBOX_COPY):                dropbox;    @$(MAKE)      copy_file_to_dir FILE=$@ SRC=~/Dropbox/Hosts/ALL DST=~

# 'git clone' will mkdir -p
~/.vim/bundle/Vundle.vim/.git:  ;           git clone https://github.com/gmarik/Vundle.vim.git $<

# TODO: Check that $(DST)/$(FILE)'s target is $(SRC)/$(FILE)
link_file_to_dir:
	@echo "checking link " $(DST)/$(FILE); \
	if [ ! -e $(DST)/$(FILE) ]; then \
		ln -s $(SRC)/$(FILE) $(DST)/$(FILE); \
	elif [ ! -L $(DST)/$(FILE) ]; then \
		echo "$(DST)/$(FILE) is not a symlink; please resolve."; \
		exit 1; \
	fi

# NOTE: If the destination is a symlink to a file that is byte-identical with the source, then no error
copy_file_to_dir:
	@echo "checking copy " $(DST)/$(FILE); \
	if ! cmp --quiet $(SRC)/$(FILE) $(DST)/$(FILE); then \
		if [ -s $(DST)/$(FILE) ]; then \
			echo "$(DST)/$(FILE) already exists; please resolve."; \
			exit 1; \
		else \
			echo "installing $(DST)/$(FILE)"; \
			cp $(SRC)/$(FILE) $(DST)/$(FILE); \
		fi; \
	fi

