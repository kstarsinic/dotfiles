#!/usr/bin/env bash

perlflags="-Mlib=$HOME/Dropbox/lib"

verbose='n'

declare -a dirs

for arg in "$@"; do
  case "$arg" in
    -v) verbose='y' ;;
    *)  dirs+=("$arg") ;;
  esac
done

if [ -z "${dirs[@]}" ]; then
  dirs+=(~/Dropbox/bin)
  dirs+=(~/Dropbox/lib)
fi
[ "$verbose" = "y" ] && echo "dirs [${dirs[@]}]"

declare -A mall mstatus sall # requires bash version 4 or later
declare -a liblist

printf "perl %s\n" `which perl`
if [ "$verbose" = "y" ]; then
  printf "%s %s:\n" `which perl` "$perlflags"
  perl $perlflags -e 'print "  $_\n" for @INC'
fi
echo

# Doing this the hard way, so that I'm not looping over modules in a subshell:
all=`
  find ${dirs[@]} \( -name KEEP \) -prune -o -type f \
    ! \( -name '*.sh' -o -name '*.rb' -o -name '*.js' -o -name '*.css' -o -name '*.png' -o -name '*.html' -o -name '*.sql' -o -name '*.scpt' \) \
    -exec egrep --no-filename '^[[:space:]]*(use|require)[[:space:]]+[a-zA-Z]' {} \; | \
    sed -E -e 's,^[[:space:]]*(use|require)[[:space:]]+,,' -e 's,[[:space:]].*,,' -e 's,;.*,,' | \
    sort -u
`

for lib in $all; do
  if [ -z "${mall[$lib]}" ]; then
    dependency=$(perl $perlflags -e "
      my \$e = eval { require $lib };
      if (\$@) {
        if (\$@ =~ /^Can't locate (.*) in \@INC/) {
          my \$dep = \$1;
          \$dep =~ s/\\.pm\$//;
          \$dep =~ s/\\//::/g;
          print \"\$dep\\n\";
        } else {
          print \"$lib\\n\";
        }
      }
      exit ! \$e;
    " 2>&1)

    status=$?
    if [ $status -eq 0 ]; then
      mstatus[$lib]='ok'
    else
      mstatus[$lib]='FAILED'
    fi

    if [ -n "$dependency" -a "$dependency" != "$lib" ]; then
      if [ $status -eq 0 ]; then
        mstatus["$dependency"]='ok'
      else
        mstatus["$dependency"]="Needed by $lib"
      fi

      ((mall["$dependency"]++))
      ((sall[${mstatus["$dependency"]}]++))
      liblist+=("$dependency")
    fi

    ((sall[${mstatus[$lib]}]++))
    liblist+=($lib)
  fi

  ((mall[$lib]++))
done

format="  %-30s  %3d  %s\n"
for lib in "${liblist[@]}"; do
  if [ "${mstatus[$lib]}" != 'ok' -o "$verbose" = 'y' ]; then
    printf "$format" "$lib" "${mall[$lib]}" "${mstatus[$lib]}"
  fi
done

echo "AptPkg:        Debian only"
echo "DBD::Sybase:   On Mac OS, comment out Makefile.PL lines 155-157, SYBASE=/usr/local"
echo "User::Utmp:    Linux only"

echo

for status in "${!sall[@]}"; do
  printf "$format" "Total" "${sall[$status]}" "$status"
done

