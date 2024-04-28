#!/bin/bash
set -e

function install_debian() {
  mkdir -p $PLATFORM_APP_DIR/.global/bin
  mkdir -p $PLATFORM_APP_DIR/.global/lib
  mkdir -p $PLATFORM_APP_DIR/.global/terminfo
  local pkg=$1
  echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing debian $pkg packages...\033[0m"
  local debian_version=
  read -d . debian_version < /etc/debian_version
  local pkgs=($(cat $PLATFORMSH_RECIPES_INSTALLDIR/scripts/platformsh/debian.json | jq -r ".\"$pkg\" | .\"$debian_version\" | .[]" 2> /dev/null))

  if [ -z $pkgs ]; then
    echo -e "\033[0;33m[$(date -u "+%Y-%m-%d %T.%3N")] [warning] no known packages to download for $pkg, it wasn't installed.\033[0m"
    return 0
  fi
  for i in "${!pkgs[@]}"; do
    mkdir -p /tmp/$pkg$i
    cd /tmp/$pkg$i
    wget -q "${pkgs[$i]}" -O $pkg$i.deb
    ar x $pkg$i.deb
    tar -xf data.tar.xz
    [ -d usr/bin ] && cp -R usr/bin/* $PLATFORM_APP_DIR/.global/bin
    [ -d lib ] && cp -R lib/* $PLATFORM_APP_DIR/.global/lib
    [ -d usr/lib ] && cp -R usr/lib/* $PLATFORM_APP_DIR/.global/lib
    [ -d usr/share/terminfo ] && cp -R usr/share/terminfo/* $PLATFORM_APP_DIR/.global/terminfo
    cd
    rm -fr /tmp/$pkg$i
  done
}

# Install debian packages manually
install_debian ansilove
install_debian colorized-logs
install_debian htop
install_debian kitty-terminfo
install_debian logrotate
install_debian pv
install_debian screen

# screen tweaks
echo "defscrollback 1000000" >> ~/.screenrc
echo 'shell -$SHELL' >> ~/.screenrc

# Install fzf
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing fzf...\033[0m"
wget -q https://github.com/junegunn/fzf/releases/download/0.48.1/fzf-0.48.1-linux_amd64.tar.gz -O - | tar -zx -C .global/bin

# Install platform cli
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing platform cli...\033[0m"
echo "Installing Platform.sh CLI"
curl -fsSL https://raw.githubusercontent.com/platformsh/cli/main/installer.sh | bash > /dev/null

# Install ahoy
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing ahoy...\033[0m"
wget -q https://github.com/ahoy-cli/ahoy/releases/download/v2.1.1/ahoy-bin-linux-amd64 -O .global/bin/ahoy && chmod +x .global/bin/ahoy
