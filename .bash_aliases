alias l='ls -l'
alias vi=vim

function xtitle() { echo -ne "\033]0;$1\007"; }	# "\e]0;$1\007"
function stitle() { echo -ne "\033k$1\033\\"; } # "\ek$1\e\\"

