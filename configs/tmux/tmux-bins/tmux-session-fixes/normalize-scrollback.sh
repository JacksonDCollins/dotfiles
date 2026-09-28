#!/usr/bin/env bash
# Stream tmux capture-pane -eJ text with safe line endings. Bash only.
# Audited against tmux 3.7c grid_string_cells_code/fg/bg/us in grid.c.
# Capture's SO implies DEC graphics; designate G1 before replaying that shift.
# OSC 8 hyperlinks pass through unchanged.
set -euo pipefail
export LC_ALL=C

declare -A style=()
esc=$'\e'
csi_re=$'^\e\[[0-?]*[ -/]*[@-~]'

fail() { printf 'Unsupported scrollback formatting: %s\n' "$1" >&2; exit 1; }
number() {
    [[ $1 =~ ^[0-9]{1,3}$ ]] || fail 'invalid numeric parameter'
    REPLY=$((10#$1))
}

update_style() {
    local body=$1 part code mode count value encoded i=0
    local -a parts sub values
    IFS=';' read -r -a parts <<< "$body;"
    while (( i < ${#parts[@]} )); do
        part=${parts[i]}
        IFS=: read -r -a sub <<< "$part:"
        number "${sub[0]:-0}"; code=$REPLY
        ((i+=1))
        if [[ $code == 38 || $code == 48 || $code == 58 ]]; then
            if (( ${#sub[@]} > 1 )); then
                number "${sub[1]}"; mode=$REPLY
                values=("${sub[@]:2}")
                if [[ $mode == 2 && ${#values[@]} == 4 && ( ${values[0]} == '' || ${values[0]} == 0 ) ]]; then
                    values=("${values[@]:1}")
                fi
            else
                (( i < ${#parts[@]} )) || fail 'incomplete colour'
                number "${parts[i]}"; mode=$REPLY
                case $mode in 2) count=3 ;; 5) count=1 ;; *) fail 'colour mode' ;; esac
                (( i + count < ${#parts[@]} )) || fail 'incomplete colour'
                values=("${parts[@]:i+1:count}")
                ((i+=count+1))
            fi
            [[ ( $mode == 2 && ${#values[@]} == 3 ) || ( $mode == 5 && ${#values[@]} == 1 ) ]] || fail 'colour components'
            encoded="$code;$mode"
            for value in "${values[@]}"; do
                number "$value"
                (( REPLY <= 255 )) || fail 'colour out of range'
                encoded+=";$REPLY"
            done
            style[$code]=$encoded
        elif [[ $part == 5:3 ]]; then
            # tmux 3.7c serializes GRID_ATTR_OVERLINE as 5:3; its input parser
            # only understands SGR 53. Repair both this token and carried state.
            style[53]=53
            parts[i-1]=53
        elif (( ${#sub[@]} > 1 )); then
            [[ $code == 4 && ${#sub[@]} == 2 && ${sub[1]} =~ ^[0-5]$ ]] || fail 'SGR subparameters'
            if [[ ${sub[1]} == 0 ]]; then unset 'style[4]'; else style[4]="4:${sub[1]}"; fi
        else
            case $code in
                0) style=() ;;
                1|2|3|4|7|8|9|20|26|53) style[$code]=$code ;;
                5|6) style[5]=$code ;;
                21) style[4]=21 ;;
                1[1-9]) style[10]=$code ;;
                51|52) style[51]=$code ;;
                6[0-4]) style[60]=$code ;;
                73|74) style[73]=$code ;;
                3[0-7]|9[0-7]) style[38]=$code ;;
                4[0-7]|10[0-7]) style[48]=$code ;;
                10) unset 'style[10]' ;;
                22) unset 'style[1]' 'style[2]' ;;
                23) unset 'style[3]' 'style[20]' ;;
                24) unset 'style[4]' ;;
                25) unset 'style[5]' ;;
                27) unset 'style[7]' ;;
                28) unset 'style[8]' ;;
                29) unset 'style[9]' ;;
                39) unset 'style[38]' ;;
                49) unset 'style[48]' ;;
                50) unset 'style[26]' ;;
                54) unset 'style[51]' ;;
                55) unset 'style[53]' ;;
                59) unset 'style[58]' ;;
                65) unset 'style[60]' ;;
                75) unset 'style[73]' ;;
                *) fail "SGR $code" ;;
            esac
        fi
    done
    local IFS=';'
    SGR_BODY=${parts[*]}
}

emit_text() {
    # capture-pane emits SO/SI but omits G1 designation. A new pane starts with
    # ASCII G1, so an unqualified SO would turn box drawing back into letters.
    printf '%s' "${1//$'\016'/$'\e)0\016'}"
}

restore_style() {
    local IFS=';'
    local -a values=("${style[@]}")
    (( ${#values[@]} == 0 )) || printf '\e[%sm' "${values[*]}"
    return 0
}

while :; do
    line=
    if IFS= read -r line; then newline=1
    elif [[ -n $line ]]; then newline=0
    else break
    fi
    restore_style
    while [[ $line == *"$esc"* ]]; do
        prefix=${line%%"$esc"*}
        emit_text "$prefix"
        line=${line:${#prefix}}
        if [[ $line == "$esc]"* ]]; then
            # OSC payloads (e.g. hyperlinks) are opaque, never parsed as SGR.
            payload=${line:2}
            bell_prefix=${payload%%$'\a'*}
            st_prefix=${payload%%"$esc\\"*}
            if [[ $payload == *$'\a'* && ${#bell_prefix} -le ${#st_prefix} ]]; then
                token=${line:0:${#bell_prefix}+3}
            elif [[ $payload == *"$esc\\"* ]]; then
                token=${line:0:${#st_prefix}+4}
            else
                fail 'incomplete OSC sequence'
            fi
        elif [[ $line =~ $csi_re ]]; then
            token=${BASH_REMATCH[0]}
        else
            fail 'unrecognised escape sequence'
        fi
        replacement=$token
        if [[ $token == "${esc}["*m ]]; then
            update_style "${token:2:${#token}-3}"
            replacement="${esc}[${SGR_BODY}m"
        fi
        printf '%s' "$replacement"
        line=${line:${#token}}
    done
    emit_text "$line"
    printf '\e[0m'
    if (( newline )); then printf '\n'; fi
done
