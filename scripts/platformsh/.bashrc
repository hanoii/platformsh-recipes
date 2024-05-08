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

export PLATFORMSH_RECIPES_PROJECT_NAME=${PLATFORMSH_RECIPES_PROJECT_NAME-$PLATFORM_APPLICATION_NAME}
# Improve window title on platform
function set_win_title() {
  # Shortening $PWD
  # /var/www/html -> /v/w/html
  local short_pwd=$(echo "$PWD" | sed "s|$HOME|~|" | sed 's/\([^\/]\)[^\/]*\//\1\//g')
  echo -ne "\033]0;$@$PLATFORMSH_RECIPES_PROJECT_NAME/$PLATFORM_BRANCH: $short_pwd\007"
}
PROMPT_COMMAND=set_win_title
prompt_psh() {
  if [ "$PLATFORM_ENVIRONMENT_TYPE" == "production" ]; then
    echo -en "\033[1;33m"
  fi
  echo -n "[p.sh/${PLATFORM_ENVIRONMENT_TYPE}]"
  if [ "$PLATFORM_ENVIRONMENT_TYPE" == "production" ]; then
    echo -en "\033[0m"
  fi
  echo -n " "
}
PS1="\[\033[1m\]\`prompt_psh\`\$PLATFORMSH_RECIPES_PROJECT_NAME@\$PLATFORM_BRANCH\[\033[0m\]:\[\033[1m\]\w\[\033[0m\]\$ "
trap 'cmd="$BASH_COMMAND"; [[ "$cmd" != "$PROMPT_COMMAND" ]] && set_win_title ${BASH_COMMAND} "- "' DEBUG
