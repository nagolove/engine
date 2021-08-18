#!/usr/bin/env bash
#complete -W "now tomorrow never" run
#complete -A /home/testuser/myprojects/engine/scenes run
#complete -A directory run

_dothis_completions()
{
    COMPREPLY=($(compgen -W "$(ls scenes)" "${COMP_WORDS[1]}"))
}

complete -F _dothis_completions run
complete -F _dothis_completions runc
