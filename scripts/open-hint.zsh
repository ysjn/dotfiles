#!/bin/zsh
set -eu

target=${1:?Expected a URL or file path}
target=${target%% *}
copy_target=$target
feedback="既定アプリへ渡しました"
trap '
  result_code=$?
  if (( result_code != 0 )); then
    feedback="処理に失敗しました"
  fi
  /usr/bin/osascript - "$feedback" "$target" <<\APPLESCRIPT >/dev/null 2>&1 || true
on run argv
  display notification ((item 1 of argv) & ": " & (item 2 of argv)) with title "Alacritty Hints"
end run
APPLESCRIPT
' EXIT

case "$target" in
  *://*|mailto:*) /usr/bin/open "$target"; exit ;;
esac
if [[ "$target" == '~/'* ]]; then
  target="$HOME/${target#\~/}"
fi
target=${target:a}

if [[ -d "$target" ]]; then
  /usr/bin/open "$target"
  exit
fi

mime=""
if [[ -f "$target" ]]; then
  mime=$(/usr/bin/file -b --mime-type -- "$target")
fi
case "$mime" in
  image/*)
    feedback="Finder で選択しました"
    /usr/bin/open -R "$target"
    exit ;;
esac

case "$mime" in
  text/*|application/json|application/javascript|application/xml|application/x-empty|inode/x-empty)
    text_file=true ;;
  *) text_file=false ;;
esac
case "${target:e:l}" in
  html|htm|css|scss|sass|less|js|jsx|mjs|cjs|ts|tsx|json|jsonc|yaml|yml|toml|xml|md|mdx|txt|lua|vim|sh|zsh|bash|py|rb|rs|go|c|h|cpp|hpp|java|swift|sql|conf|cfg|ini|env)
    text_file=true ;;
esac

if $text_file; then
  printf '%s' "$copy_target" | /usr/bin/pbcopy
  target=$copy_target
  feedback="パスをコピーしました"
  exit 0
fi
if [[ ! -e "$target" ]]; then
  print -u2 -- "File not found: $target"
  exit 1
fi
/usr/bin/open "$target"
