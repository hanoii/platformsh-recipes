#!/bin/bash
set -e -o pipefail

# To run it on a platform ssh console,
# export PLATFORM_APP_DIR=/tmp/tmpapp
# rm -fr /tmp/tmpapp ; mkdir -p /tmp/tmpapp
# export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${PLATFORM_APP_DIR}/.global/lib/x86_64-linux-gnu"
# Then copy from the next line to the whole install_debin() function and paste
# it on a terminal

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

function install_debian_url() {
  mkdir -p $PLATFORM_APP_DIR/.global/bin
  mkdir -p $PLATFORM_APP_DIR/.global/lib
  mkdir -p $PLATFORM_APP_DIR/.global/share

  for i in "$@"; do
    local pkg_url=$i
    local pkg_name=$(basename $pkg_url)
    echo "Installing ${pkg_name}..."
    mkdir -p /tmp/${pkg_name}
    cd /tmp/${pkg_name}
    wget -q "$pkg_url" -O "${pkg_name}"
    ar x ${pkg_name}
    tar -xf data.tar.xz
    [ -d usr/bin ] && cp -R usr/bin/* $PLATFORM_APP_DIR/.global/bin
    [ -d lib ] && cp -R lib/* $PLATFORM_APP_DIR/.global/lib
    [ -d usr/lib ] && cp -R usr/lib/* $PLATFORM_APP_DIR/.global/lib
    [ -d usr/share ] && cp -R usr/share/* $PLATFORM_APP_DIR/.global/share
    cd
    rm -fr /tmp/${pkg_name}
  done
}

function install_debian() {
  echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing debian $@ packages...\033[0m"
  local codename=${VERSION_CODENAME_OVERRIDE-$VERSION_CODENAME}
  local arch=${VERSION_ARCH_OVERRIDE-$VERSION_ARCH}

  for i in "$@"; do
    local pkg_url=
    if [ "$codename" != "stretch" ]; then
      local curl_cmd="curl --connect-timeout 5 --retry 10 --retry-delay 1 -sS https://packages.debian.org/$codename/$arch/$i/download"
      if [ -n "$PLATFORMSH_RECIPES_DEBUG" ]; then
        echo -e "\033[0;36m[debug] $curl_cmd\033[0m"
      fi
      pkg_url=$($curl_cmd | grep -oP 'http://http.us.debian.org/debian/pool/main/.*?\.deb')
    fi

    if [ "$codename" = "stretch" ] && [ "$i" = "screen" ]; then
      pkg_url="https://snapshot.debian.org/archive/debian-archive/20240331T102506Z/debian-security/pool/updates/main/s/screen/screen_4.5.0-6%2Bdeb9u1_$arch.deb"
    fi

    if [ -z "$pkg_url" ]; then
      echo -e "\033[0;33m[warning] installing debian package $i for $codename is currently not supported.\033[0m"
    else
      install_debian_url $pkg_url
    fi
  done
}

# Install debian packages manually
VERSION_CODENAME_OVERRIDE=unstable VERSION_ARCH_OVERRIDE=all install_debian kitty-terminfo
VERSION_CODENAME_OVERRIDE=${VERSION_CODENAME//buster/bullseye} install_debian ansilove
install_debian colorized-logs
install_debian htop libnl-3-200 libnl-genl-3-200
install_debian logrotate
install_debian pv
install_debian screen libutempter0
install_debian telnet
install_debian vim-nox vim-runtime libgpm2 liblua5.2-0
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
