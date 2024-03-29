eval "$(fzf --bash)"

# Allow colon(:) in autocomplete, mostly for the ahoy below
COMP_WORDBREAKS=${COMP_WORDBREAKS//:}

# ahoy bash-complete
_ahoy_bash_autocomplete() {
  local cur opts base
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  opts=$( ${COMP_WORDS[@]:0:$COMP_CWORD} --generate-bash-completion )
  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
  return 0
}

complete -F _ahoy_bash_autocomplete ahoy
