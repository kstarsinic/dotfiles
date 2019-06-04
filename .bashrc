if [ -n "$PS1" ]; then # Only if running interactively
  ### History control
  ### NOTE: tty should be settable in .bash_login
  #tty=`tty | sed -e 's/ /-/g'`            # Turn "not a tty" into "not-a-tty"
  #HISTFILE=~/.bash_hist/`basename $tty`
  #HISTCONTROL=ignoredups                  # Don't put duplicate lines in the history
  #HISTSIZE=1000                           # Lines in memory
  #HISTFILESIZE=2000                       # Lines in file
  shopt -s histappend                     # Append to the history file, don't overwrite it

  # Check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
  shopt -s checkwinsize

  # From ubuntu's default .bashrc: make less more friendly for non-text input files
  [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

  # set variable identifying the chroot you work in (used in the prompt below)
  [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ] && debian_chroot=$(cat /etc/debian_chroot)

  # This must happen before PS1 is set
  if ! shopt -oq posix; then
    echo "BASH_VERSION [$BASH_VERSION]  PS1 [$PS1]  BASH_COMPLETION_VERSINFO [$BASH_COMPLETION_VERSINFO]"
    export BASH_COMPLETION_COMPAT_DIR=/usr/local/etc/bash_completion.d
    [[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
    # for dir in /usr/local/share/bash-completion /usr/local/etc /etc; do
    #   if [ -f "$dir/bash_completion" ]; then
    #     . "$dir/bash_completion"
    #     break
    #   fi
    # done
  else
    echo "POSIX!!!"
  fi

  ### Prompt
  # https://en.wikipedia.org/wiki/ANSI_escape_code
  # CSI n1 ; n2 ... m       n1, etc. are SGR parameters
  # \e\[        Control Sequence Initator (ends with ASCII 64 (@) to 126 (~))
  #   ;         parameter separator
  # \e[${number}m:
  #   0         Reset all
  #   1         Bold
  #   30-37 FG  Black Red Green Yellow Blue Magenta Cyan White
  #   38    FG  5;${RGB}m   $RGB in [0, 255]          RGB = 36R + 6G + B + 16
  #   48    BG  5;${RGB}m   $RGB in [0, 255]
  #             0x00-0x07   standard colors           (e.g., [30-37)
  #             0x08-0x0F   high-intensity colors     (e.g., [90-97)
  #             0x10-0xE7   16 + 36R + 6G + B
  #             0xE8-0xFF   grayscale from black to white
  #   40-47 BG  Black Red Green Yellow Blue Magenta Cyan White
  #   49        Default background color
  # Bracketing '[]' is so bash doesn't count the characters
  reset='\[\e[0m\]'
  host='\[\e[0;32m\]'         # Green
  dir='\[\e[38;5;27m\]'       # R0 B1 G5 (blue with a little green)
  branch='\[\e[0;34m\]'       # Blue                                                                                                      
  #screen='\[\e[0;38;5;62m\]'  # R1 G1 B4 lavender

  case "$TERM" in
    xterm-color|xterm-256color|screen-256color)
      # Debian: PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
      #PS1="${STY+| }[${host}\h${reset} ${dir}\W${reset}${branch}\$(__git_ps1 \" (%s)\")${reset}]\$ "
      #PS1="${screen}${STY/*./}${reset} [${host}\h${reset} ${dir}\W${reset}${branch}\$(__git_ps1 \" (%s)\")${reset}]\$ "
      #PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
      PS1="${reset}[${host}\h${reset} ${dir}\W${reset}${branch}\$(__git_ps1 \" (%s)\")${reset}]\$ "
      ;;
    *)
      # Debian: PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
      PS1='\u@\h\w\$ '
      ;;
  esac

  export EDITOR=vim
  export GIT_CEILING_DIRECTORIES="/usr/local"
  export HOMEBREW_GITHUB_API_TOKEN=a8c726248063895051ac1072db51c3def4169efd
  export LANG=en_US.UTF-8
  export LC_COLLATE=C
  export LESS='-ismR'
  export PAGER=less
  # For BSD ls:
  # inode:blockcount:numlinks:uname:gname:flags:filesize:filename
  # user name=6, file size=10
  [ -z "$LS_COLWIDTHS" ] && export LS_COLWIDTHS=':::6:::10:'

  # export AWT_TOOLKIT=CToolkit
  # For assemblies from other formulae: export MONO_GAC_PREFIX=/usr/local

  alias l='ls -l'
  alias vi=vim

  function xtitle() { echo -ne "\033]0;$1\007"; }	# "\e]0;$1\007"
  function stitle() { echo -ne "\033k$1\033\\"; } # "\ek$1\e\\"


  for i in ~/etc/.bashrc*; do
    if [ -f "$i" ]; then
      . $i
    elif [ -e "$i" ]; then
      echo "$i: not a file!"
    fi
  done

  oblique.pl
fi

