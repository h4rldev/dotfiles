#!/usr/bin/env bash

VERSION="0.0.1"
WORKING_DIR="${HOME}"
FZF_INSTALLED=$(command -v fzf)
ROOT_PACKAGE_MANAGER="pacman"

# Dirs
CONFIG_DIR="$(pwd)/.config/"
RESOURCES="$(pwd)/resources"

if command -v sudo >/dev/null; then
  sudo -K
else
  alias sudo=doas
fi


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
CLEAR='\033[0m'


install_packages() {
  local -a PACKAGES
  index=0
  while IFS= read -r line
  do
    if [[ ! -z "$line" ]]; then
      PACKAGES[index]="$line"
      ((index++))
    fi
  done < "${RESOURCES}/pacman-packages.txt"

  echo -e "${PACKAGES[@]}"
  sudo pacman -S "${PACKAGES[@]}"

}

copy_config() {
  echo -e "I copy config"
}

update() {
  echo -e "I update"
}

full_setup() {
  update
  install_packages
  copy_config
}

render_menu() {
  local OPTIONS
  local PROMPT
  local RESULT

  OPTIONS=("Full Setup" "Install Packages" "Copy Config" "Update" "Exit")
  PROMPT="Action"

  if [[ ${1} != false ]]; then
    RESULT=$(printf "%s\n" "${OPTIONS[@]}" | fzf --layout=reverse --no-sort --prompt="${PROMPT}: ")
  else
    PS3="${PROMPT}: "
    select RESULT in "${OPTIONS[@]}"; do
      if [[ $REPLY -ge 1 && $REPLY -le ${#OPTIONS[@]} ]]; then
        break
      else
        echo -e "Invalid choice!"
      fi
    done
  fi

  case "${RESULT}" in
    ${OPTIONS[0]})
      full_setup
      ;;
    ${OPTIONS[1]})
      install_packages
      ;;
    ${OPTIONS[2]})
      copy_config
      ;;
    ${OPTIONS[3]})
      update
      ;;
    ${OPTIONS[4]})
      exit 0
      ;;
  esac

}

main() {
  local FZF_INSTALL_DECISION
  local FZF_ENABLE_DECISION
  local FZF_ENABLED

  if [[ -z ${FZF_INSTALLED} ]]; then
    echo -ne "${CYAN}fzf is not installed, would you like me to install it for you? ${CLEAR}(${GREEN}Y${CLEAR}/${RED}n${CLEAR}): "; read -r FZF_INSTALL_DECISION
    if ! [[ ${FZF_INSTALL_DECISION} =~ [nN] ]]; then
      sudo "${ROOT_PACKAGE_MANAGER}" -S fzf
    fi 
  else
    echo -ne "${CYAN}Would you like to use fzf for navigation? ${CLEAR}(${GREEN}Y${CLEAR}/${RED}n${CLEAR}): "; read -r FZF_ENABLE_DECISION
    if ! [[ ${FZF_ENABLE_DECISION} =~ [nN] ]]; then
      FZF_ENABLED=true
    else
      FZF_ENABLED=false
    fi
	fi

  render_menu "${FZF_ENABLED}"
}


case $1 in 
  "--help" | "-h" | "-?")
    echo -e "H4rl's dotfile installer"
    echo -e "ONLY SUPPORTS ARCH LINUX as of right now\n"
    echo -e "Usage:"
    echo -e "--help | -h | -?"
    echo -e "Displays this message\n"
    echo -e "--version | -v"
    echo -e "Displays current version\n"
    echo -e "--directory | -d"
    echo -e "Sets the directory you want to apply the dotfiles to. (Defaults to HOME)"
    ;;
  "--version" | "-v")
    echo -e "H4rl's dotfile installer v${VERSION}"
    ;;
  "--directory" | "-d")
    WORKING_DIR=${2}
    echo -e "You've set the directory to ${WORKING_DIR}"
    main
    ;;
  *)
    main
    ;;
  esac

