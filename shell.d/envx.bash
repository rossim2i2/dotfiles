envx () {
  local envfile="$1"
  if [[ ! -e "${envfile}" ]]; then
    if [[ ! -e "$HOME/.env" ]]; then
      echo "file not found: ${envfile}"
      return
    fi
    envfile="$HOME/.env"
  fi
  while IFS= read line; do
    name=${line%%=*}
    value=${line#*=}
    if [[ -z "${name}" || $name =~ ^# ]]; then
      continue
    fi
    export "$name"="$value"
  done < "${envfile}"
} && export -f envx

if [[ -e "$HOME/.env" ]]; then
  envx $HOME/.env
fi

