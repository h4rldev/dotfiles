#!/usr/bin/env bash

VERSION="0.0.1"
WORKING_DIR="${HOME}"

source ./config.sh

ROOT_PACKAGE_MANAGER="pacman"
USER_PACKAGE_MANAGER="paru"

SUDO_EXIST=$(command -v sudo >/dev/null)
FZF_INSTALLED=$(command -v fzf)
DOES_USER_PACKAGE_MANAGER_EXIST=$(command -v ${USER_PACKAGE_MANAGER})

# Dirs
CONFIG_DIR="$(pwd)/.config/"
RESOURCES="$(pwd)/resources"

if [[ -n ${SUDO_EXIST} ]]; then
  sudo -k
else
  alias sudo="doas"
fi

clear


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
CLEAR='\033[0m'

get_packages() {
  local INDEX=0
  local LINE
  local FILE
  local -a PACKAGES

  if [[ -n ${1} ]]; then
    FILE=${1}
  else
    echo -e "No file provided.">&2
    exit
  fi

  while IFS= read -r LINE; do
    if [[ ! -z "${LINE}" ]]; then
      PACKAGES[INDEX]="${LINE}"
      ((INDEX++))
    fi
  done < "${RESOURCES}/${FILE}"
  echo "${PACKAGES[@]}"
}


reset_sudo_timer() {
  if [[ -n ${SUDO_EXIST} ]]; then
    sudo -k
  fi
}

sudo_trap() {
  trap 'echo "Sudo was cancelled, exiting.."' SIGINT 
}

setup() {
  local -a PACKAGES
  local TEMP_DIR

  PACKAGES=$(get_packages "setup.txt")
  
  reset_sudo_timer
  sudo_trap
  sudo "${ROOT_PACKAGE_MANAGER}" -S ${PACKAGES[@]}

  TEMP_DIR=$(mktemp -d temp.XXX)
  git clone "https://aur.archlinux.org/paru.git" $TEMP_DIR
  cd $TEMP_DIR
  makepkg -si
  rm -fr $TEMP_DIR
}


install_packages() {
  local -a PACKAGES 
  PACKAGES=$(get_packages "pacman-packages.txt")

  sudo_trap
  reset_sudo_timer
  echo -e "Installing: ${PACKAGES[@]}"
  sudo ${ROOT_PACKAGE_MANAGER} -S "${PACKAGES[@]}"

}

copy_config() {
  echo -e "I copy config"
}

update() {
  reset_sudo_timer
  sudo_trap
  echo -e "Updating.."
  sudo ${ROOT_PACKAGE_MANAGER} -Syu
  if [[ -n ${DOES_USER_PACKAGE_MANAGER_EXIST} ]]; then
    ${USER_PACKAGE_MANAGER} -Syu
  fi
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

  OPTIONS=("Full Setup" "Setup Prerequisites" "Install Packages" "Copy Config" "Update" "Exit")
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
      setup
      ;;
    ${OPTIONS[2]})
      install_packages
      ;;
    ${OPTIONS[3]})
      copy_config
      ;;
    ${OPTIONS[4]})
      update
      ;;
    ${OPTIONS[5]})
      exit 0
      ;;
  esac

}

main() {
  local FZF_INSTALL_DECISION
  local FZF_ENABLE_DECISION

  if [[ -z ${FZF_INSTALLED} ]]; then
    echo -ne "${CYAN}fzf is not installed, would you like me to install it for you? ${CLEAR}(${GREEN}Y${CLEAR}/${RED}n${CLEAR}): "; read -r FZF_INSTALL_DECISION
    if ! [[ ${FZF_INSTALL_DECISION} =~ [nN] ]]; then
      sudo "${ROOT_PACKAGE_MANAGER}" -S fzf
    fi 
  else
    if ! ${FZF_ENABLED}; then
      echo -ne "${CYAN}Would you like to use fzf for navigation? ${CLEAR}(${GREEN}Y${CLEAR}/${RED}n${CLEAR}): "; read -r FZF_ENABLE_DECISION
      if ! [[ ${FZF_ENABLE_DECISION} =~ [nN] ]]; then
        FZF_ENABLED=true
        sed -i 's/FZF_ENABLED=false/FZF_ENABLED=true/' ./config.sh
      fi
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

