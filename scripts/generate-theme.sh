#!/usr/bin/env bash
# Substitute shared variables into native *.template.* configurations.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
theme_dir="$repo/configs/theme/.config/theme"
output_dir="$theme_dir/generated"
profile=default
check=false
usage() { printf 'Usage: bash scripts/generate-theme.sh [--profile PROFILE] [--check] [--output-dir DIRECTORY]\n' >&2; }
while (( $# )); do
    case $1 in
        --check) check=true; shift ;;
        --profile)
            (( $# >= 2 )) && [[ -n $2 ]] || { usage; exit 2; }
            profile=$2; shift 2 ;;
        --output-dir)
            (( $# >= 2 )) && [[ -n $2 ]] || { usage; exit 2; }
            output_dir=$2; shift 2 ;;
        *) usage; exit 2 ;;
    esac
done
command -v jq >/dev/null || { printf 'Theme generation requires jq.\n' >&2; exit 1; }

[[ $profile =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && -d $repo/machines/$profile ]] || {
    printf 'Unknown or invalid theme profile: %s\n' "$profile" >&2; exit 1;
}
overrides='{}'
override_file="$repo/machines/$profile/theme.json"
if [[ -e $override_file || -L $override_file ]]; then
    [[ -f $override_file && ! -L $override_file ]] || {
        printf 'Invalid theme override file: %s\n' "$override_file" >&2; exit 1;
    }
    overrides=$(jq -ces '
        if length == 1 and (.[0] | type) == "object" then .[0]
        else error("Expected one profile theme JSON object") end
    ' "$override_file")
fi

vars=$(jq -ces --argjson overrides "$overrides" '
    def require($condition; $message):
        if $condition then . else error($message) end;
    require(length == 1; "Expected one theme JSON object") | .[0]
    | require(type == "object" and keys == ["extra_colors", "font", "foot_font_size", "palette"]; "Expected shared font, foot_font_size, palette and extra_colors")
    | require(($overrides | keys - ["extra_colors", "font", "foot_font_size", "palette"] | length) == 0; "Unknown profile theme variable")
    | . * $overrides
    | require((.palette | type) == "object" and (.extra_colors | type) == "object"
        and (.palette | length) > 0; "Color sections must be objects with a nonempty palette")
    | . as $theme
    | require(all(.extra_colors | keys[]; . as $key | $theme.palette | has($key) | not); "Duplicate palette and extra_colors names")
    | (.palette + .extra_colors) as $colors
    | require(all($colors | to_entries[];
        (.key | test("\\A[A-Za-z_][A-Za-z0-9_]*\\z")) and .key != "font" and .key != "name" and .key != "foot_font_size"
        and (.value | type) == "string" and (.value | test("\\A#[0-9a-fA-F]{6}\\z"))); "Colors must be named #RRGGBB values")
    | require(.font | type == "string" and length > 0
        and (test("[\u0000-\u001f\u007f]") | not); "font must be a nonempty single-line string")
    | require(.foot_font_size | type == "number" and isfinite and . > 0; "foot_font_size must be a positive finite number")
    | ($colors + {name: "hyprcachy", font, foot_font_size: (.foot_font_size | tostring)}) as $raw
    | $raw
        + ($colors | with_entries(.key += ".hex" | .value |= ltrimstr("#")))
        + ($raw | with_entries(.key += ".json" | .value |= (tojson | .[1:-1])))
' "$theme_dir/theme.json")

[[ ! -L $output_dir && ( ! -e $output_dir || -d $output_dir ) ]] || {
    printf 'Refusing non-directory or symlink output directory: %s\n' "$output_dir" >&2; exit 1;
}
shopt -s nullglob
templates=("$theme_dir/templates"/*.template.*)
(( ${#templates[@]} )) || { printf 'No theme templates found.\n' >&2; exit 1; }
changed=()
declare -A contents=()
# Render every template before publishing any output; JSON strings preserve exact whitespace.
for template in "${templates[@]}"; do
    name=${template##*/}
    [[ -f $template && ! -L $template && $name =~ ^[A-Za-z0-9_-]+\.template\.[A-Za-z0-9]+$ ]] || {
        printf 'Invalid theme template: %s\n' "$template" >&2; exit 1;
    }
    name=${name/.template./.generated.}
    path="$output_dir/$name"
    [[ ! -L $path && ( ! -e $path || -f $path ) ]] || {
        printf 'Refusing non-regular output: %s\n' "$path" >&2; exit 1;
    }
    contents[$name]=$(jq -Rsc --argjson vars "$vars" '
        gsub("\\{\\{(?<key>[^{}]*)\\}\\}|(?<invalid>\\{\\{)";
            if .invalid != null then error("Unclosed theme placeholder")
            else $vars[.key] // error("Unknown theme variable: " + .key) end)
    ' "$template")
    if [[ -f $path ]] && cmp -s -- "$path" <(jq -jr . <<< "${contents[$name]}"); then
        continue
    fi
    changed+=("$name")
done
if (( ! ${#changed[@]} )); then
    printf 'All generated themes are current.\n'
    exit 0
fi
if "$check"; then
    printf 'Stale generated themes: %s\n' "${changed[*]}" >&2
    exit 1
fi
mkdir -p -- "$output_dir"
stage=$(mktemp -d -- "$output_dir/.theme.XXXXXXXXXX")
trap 'rm -rf -- "$stage"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for name in "${changed[@]}"; do
    jq -jr . <<< "${contents[$name]}" > "$stage/$name"
    chmod 644 -- "$stage/$name"
done
# shortcut: publication is atomic per file; use directory generations if bundle-level switching is needed.
for name in "${changed[@]}"; do
    mv -fT -- "$stage/$name" "$output_dir/$name"
done
printf 'Generated: %s\n' "${changed[*]}"
