if status is-interactive
    fish_vi_key_bindings
    set fish_cursor_default line
    set fish_cursor_insert block
    set fish_cursor_replace_one underscore
    set fish_cursor_visual block

    fish_add_path -g $HOME/.local/bin $HOME/.cargo/bin $HOME/.npm/bin $HOME/.opencode/bin

    if command -q mise
        mise activate fish | source
    end
    if command -q starship
        starship init fish | source
    end
    if command -q zoxide
        zoxide init fish | source
    end
    if command -q direnv
        direnv hook fish | source
    end
    if command -q atuin
        atuin init fish | source
    end

    # Elitebook (neuronix) aliases
    alias k kubectl
    function urldecode
        python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'
    end
    function urlencode
        python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'
    end

    # Omarchy bash aliases, for Fish
    if command -q eza
        alias ls 'eza -lh --group-directories-first --icons=auto'
        alias lsa 'ls -a'
        alias lt 'eza --tree --level=2 --long --icons --git'
        alias lta 'lt -a'
    end

    function ff
        if test "$TERM" = xterm-kitty
            fzf --preview 'case $(file --mime-type -b {}) in image/*) kitty icat --clear --transfer-mode=memory --stdin=no --place=${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}@0x0 {} ;; *) bat --style=numbers --color=always {} ;; esac'
        else
            fzf --preview 'bat --style=numbers --color=always {}'
        end
    end
    function eff
        set -l file (ff)
        and test -n "$file"
        and $EDITOR $file
    end

    function sff
        if test (count $argv) -eq 0
            echo 'Usage: sff <destination> (e.g. sff host:/tmp/)'
            return 1
        end
        set -l file (find . -type f -printf '%T@\t%p\n' | sort -rn | cut -f2- | ff)
        and test -n "$file"
        and scp $file $argv[1]
    end

    if command -q zoxide
        function zd
            if test (count $argv) -eq 0
                builtin cd ~
                or return
            else if test -d $argv[1]
                builtin cd $argv[1]
                or return
            else
                z $argv
                or begin
                    echo 'Error: Directory not found'
                    return 1
                end
            end
            printf '\U000F17A9 '
            pwd
        end
        alias cd zd
    end

    function open
        xdg-open $argv >/dev/null 2>&1 &
    end

    alias .. 'cd ..'
    alias ... 'cd ../..'
    alias .... 'cd ../../..'

    alias a 'omarchy-agent --inline'
    alias c 'opencode --auto'
    alias cx 'printf "\033[2J\033[3J\033[H" && claude --permission-mode auto'
    alias cy 'codex --approve-for-me'
    alias d docker
    alias r rails
    alias t 'tmux attach || tmux new -s Work'
    alias h herdr
    alias ic 'tdl c'
    alias ix 'tdl cx'
    alias icx 'tdl c cx'
    alias mup 'MISE_MINIMUM_RELEASE_AGE=0 mise up'

    function n
        if test (count $argv) -eq 0
            command nvim .
        else
            command nvim $argv
        end
    end

    alias g git
    alias gcm 'git commit -m'
    alias gcam 'git commit -a -m'
    alias gcad 'git commit -a --amend'
end
