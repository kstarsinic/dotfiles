
UNAME		= $(shell uname)
BREWTOOLS	= ack ant@1.9 bash bash-completion@2 freetds git jenv mtr mysql nmap node openssl p7zip perl pstree sqlite unixodbc vim w3m wget
CASKTOOLS	= basictex google-chrome dropbox java6 java libreoffice xquartz
# caskroom/versions for java8
TAPS		= homebrew/services keith/formulae caskroom/versions
DOTFILES	= .bash_login .bashrc

# $^	All dependencies
# $@	Target name
# $*
# $>
# $<
# $!

# XXX get .bashrc and .bash_login from DROPBOX_ALL
DROPBOX_ALL = .dataprinter .gitconfig .netrc .screenrc .vimrc .vim/autoload

.PHONY: $(DOTFILES) $(DROPBOX_ALL) .bash_hist sudoers-local

default: os_$(UNAME) bash dropbox perlbrew cpanm sudoers-local $(DROPBOX_ALL) ~/.vim/bundle/Vundle.vim

os_Darwin: taps brewtools casktools brewinfo locate

locate:
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

taps:		homebrew; @$(MAKE) _brew TITLE="homebrew taps"  WANTED="$(TAPS)"      CMD="tap"         INSTALLED="`brew tap`"

brewtools:	homebrew; @$(MAKE) _brew TITLE="homebrew tools" WANTED="$(BREWTOOLS)" CMD="install"     INSTALLED="`brew list`"

casktools:	homebrew; @$(MAKE) _brew TITLE="homebrew casks" WANTED="$(CASKTOOLS)" CMD="cask instal" INSTALLED="`brew cask list`"

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

bash: .bash_hist $(DOTFILES)
	@if [ "$$SHELL" != "/usr/local/bin/bash" ]; then \
		echo "SHELL is $$SHELL: use chsh(1)"; \
		exit 1; \
	fi

.bash_hist: ; @[ -e ~/.bash_history ] && rm ~/.bash_history; [ -d ~/.bash_hist ] || mkdir ~/.bash_hist

$(DOTFILES):                    ;         @$(MAKE) install_file_in_dir FILE=$@ DIR=~; \

sudoers-local:                  ;         @$(MAKE) install_file_in_dir FILE=$@ DIR=/etc/sudoers.d

$(DROPBOX_ALL):           dropbox ~/.vim; @$(MAKE) link_file_to_dir FILE=$@ SRC=~/Dropbox/Hosts/ALL DST=~

~/.vim/bundle/Vundle.vim: ~/.vim/bundle;  git clone https://github.com/gmarik/Vundle.vim.git $@

~/.vim ~/.vim/bundle:           ;         mkdir -p $@

link_file_to_dir:
	@echo "checking symlink " $(DST)/$(FILE); \
	if [ ! -e $(DST)/$(FILE) ]; then \
		ln -s $(SRC)/$(FILE) $(DST)/$(FILE); \
	elif [ ! -L $(DST)/$(FILE) ]; then \
		echo "$(DST)/$(FILE) is not a symlink; please resolve."; \
		exit 1; \
	fi

install_file_in_dir:
	@if ! cmp --quiet $(FILE) $(DIR)/$(FILE); then \
		if [ -s $(DIR)/$(FILE) ]; then \
			echo "$(DIR)/$(FILE) already exists; please resolve."; \
			exit 1; \
		else \
			echo "installing $(DIR)/$(FILE)"; \
			cp $(FILE) $(DIR)/$(FILE); \
		fi; \
	fi

