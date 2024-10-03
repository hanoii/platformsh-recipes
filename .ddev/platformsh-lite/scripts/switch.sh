#!/bin/bash
#ddev-generated

if [[ "$0" == *"switch.sh"* ]]; then
  gum log --level error The script is meant to be source\'d.
  if [ -n "$IS_FISH_SHELL" ]; then
    cmd="bass source /var/www/html/.ddev/platformsh-lite/scripts/switch.sh"
  else
    cmd="source /var/www/html/.ddev/platformsh-lite/scripts/switch.sh"
  fi
  gum log Please run \'$cmd\' on your shell
  exit 2
fi

IFS=$'\n' projects=$(gum spin --show-output --title="Querying active projects on Platform.sh..." -- platform projects --format=plain --columns=title,id --no-header --count 0)
projects_array=()
for p in $projects; do
  IFS=$'\t' read pname pid <<< $p
  projects_array+=("$pname - $pid")
done

if [ -z "$projects" ] || ! project=$(gum filter --select-if-one --header="Choose project to switch to for running platform commands against" ${projects_array[@]}); then
  gum log --level error --structured "Querying platform projects"
  (exit 2)
else
  project_id=${project#*" - "}

  gum log --level info --structured "Project selected" project $project
  gum log --level info --structured "Variable PLATFORM_PROJECT exported." project $project_id
  gum log --level warn "It will only be valid in the running shell."
  export PLATFORM_PROJECT=$project_id
fi
