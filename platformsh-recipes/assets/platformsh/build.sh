#!/bin/bash
set -e -o pipefail

source /etc/os-release

# Map uname -m output to Debian architecture names
arch=$(uname -m)
case $arch in
  x86_64)
    VERSION_ARCH="amd64"
    ;;
  aarch64)
    VERSION_ARCH="arm64"
    ;;
  *)
    echo "Unsupported debian architecture: $arch"
    exit 1
    ;;
esac

function install_debian() {
  mkdir -p $PLATFORM_APP_DIR/.global/bin
  mkdir -p $PLATFORM_APP_DIR/.global/lib
  mkdir -p $PLATFORM_APP_DIR/.global/terminfo
  echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing debian $@ packages...\033[0m"

  for i in "$@"; do
    local pkg_url=$(curl -s https://packages.debian.org/${VERSION_CODENAME_OVERRIDE-$VERSION_CODENAME}/${VERSION_ARCH_OVERRIDE-$VERSION_ARCH}/$i/download | grep -oP 'http://http.us.debian.org/debian/pool/main/.*?\.deb')
    echo "Installing $(basename $pkg_url)..."
    mkdir -p /tmp/$i
    cd /tmp/$i
    wget -q "$pkg_url" -O $i.deb
    ar x $i.deb
    tar -xf data.tar.xz
    [ -d usr/bin ] && cp -R usr/bin/* $PLATFORM_APP_DIR/.global/bin
    [ -d lib ] && cp -R lib/* $PLATFORM_APP_DIR/.global/lib
    [ -d usr/lib ] && cp -R usr/lib/* $PLATFORM_APP_DIR/.global/lib
    [ -d usr/share/terminfo ] && cp -R usr/share/terminfo/* $PLATFORM_APP_DIR/.global/terminfo
    cd
    rm -fr /tmp/$i
  done
}

# Install debian packages manually
VERSION_CODENAME_OVERRIDE=${VERSION_CODENAME//buster/bullseye} install_debian ansilove
install_debian colorized-logs
install_debian htop libnl-3-200 libnl-genl-3-200
VERSION_CODENAME_OVERRIDE=unstable VERSION_ARCH_OVERRIDE=all install_debian kitty-terminfo
install_debian logrotate
install_debian pv
install_debian screen libutempter0
install_debian telnet
install_debian vim-nox libgpm2 liblua5.2-0
if [ -f $PLATFORM_APP_DIR/.global/bin/telnet.netkit ]; then
  mv $PLATFORM_APP_DIR/.global/bin/telnet.netkit $PLATFORM_APP_DIR/.global/bin/telnet
fi
if [ -f $PLATFORM_APP_DIR/.global/bin/vim.nox ]; then
  mv $PLATFORM_APP_DIR/.global/bin/vim.nox $PLATFORM_APP_DIR/.global/bin/vi
fi

# screen tweaks
cp $PLATFORMSH_RECIPES_INSTALLDIR/platformsh-recipes/assets/platformsh/.screenrc ~/.screenrc

# Install fzf
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing fzf...\033[0m"
wget -q https://github.com/junegunn/fzf/releases/download/0.52.1/fzf-0.52.1-linux_amd64.tar.gz -O - | tar -zx -C $PLATFORM_APP_DIR/.global/bin

# Install platform cli
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing platform cli...\033[0m"
echo "Installing Platform.sh CLI"
if [ -z "$IS_DDEV_PROJECT" ]; then
  curl -fsSL https://raw.githubusercontent.com/platformsh/cli/main/installer.sh | bash > /dev/null
fi

# Install ahoy
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing ahoy...\033[0m"
wget -q https://github.com/ahoy-cli/ahoy/releases/download/v2.1.1/ahoy-bin-linux-amd64 -O $PLATFORM_APP_DIR/.global/bin/ahoy && chmod +x $PLATFORM_APP_DIR/.global/bin/ahoy
