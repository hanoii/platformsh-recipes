#!/bin/bash
set -e

mkdir -p .global/bin

##
# Install screen package and its dependencies
###
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing screen...\033[0m"
mkdir -p /tmp/screen
cd /tmp/screen
wget -nv http://ftp.us.debian.org/debian/pool/main/s/screen/screen_4.6.2-3+deb10u1_amd64.deb
ar x screen_4.6.2-3+deb10u1_amd64.deb
tar -xf data.tar.xz
cd
mv /tmp/screen/usr/bin/screen .global/bin
rm -fr /tmp/screen
mkdir -p /tmp/libutempter0
cd /tmp/libutempter0
wget -nv http://ftp.us.debian.org/debian/pool/main/libu/libutempter/libutempter0_1.1.6-3_amd64.deb
ar x libutempter0_1.1.6-3_amd64.deb
tar -xf data.tar.xz
cd
cp -R /tmp/libutempter0/usr/lib .global
rm -fr /tmp/libutempter0
echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] Done installing screen!\n\033[0m"

##
# Install pv
###
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing pv...\033[0m"
mkdir -p /tmp/pv
cd /tmp/pv
wget -nv http://ftp.us.debian.org/debian/pool/main/p/pv/pv_1.6.6-1_amd64.deb
ar x pv_1.6.6-1_amd64.deb
tar -xf data.tar.xz
cd
mv /tmp/pv/usr/bin/pv .global/bin
rm -fr /tmp/pv
echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] Done installing pv!\n\033[0m"

##
# Install htop
###
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing htop...\033[0m"
mkdir -p /tmp/htop
cd /tmp/htop
wget -nv http://http.us.debian.org/debian/pool/main/h/htop/htop_2.2.0-1+b1_amd64.deb
ar x htop_2.2.0-1+b1_amd64.deb
tar -xf data.tar.xz
cd
mv /tmp/htop/usr/bin/htop .global/bin
rm -fr /tmp/htop
echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] Done installing htop!\n\033[0m"

##
# Install logrotate
###
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing logrotate...\033[0m"
mkdir -p /tmp/logrotate
cd /tmp/logrotate
wget -nv http://ftp.us.debian.org/debian/pool/main/l/logrotate/logrotate_3.14.0-4_amd64.deb
ar x logrotate_3.14.0-4_amd64.deb
tar -xf data.tar.xz
cd
mv /tmp/logrotate/usr/sbin/logrotate .global/bin
rm -fr /tmp/logrotate
echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] Done installing logrotate!\n\033[0m"

# Install fzf
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing fzf...\033[0m"
wget -nv https://github.com/junegunn/fzf/releases/download/0.48.1/fzf-0.48.1-linux_amd64.tar.gz -O - | tar -zvx -C .global/bin
echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] Done installing fzf!\n\033[0m"

# Install platform cli
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing platform cli...\033[0m"
echo "Installing Platform.sh CLI"
curl -fsSL https://raw.githubusercontent.com/platformsh/cli/main/installer.sh | bash
echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] Done installing platform cli!\n\033[0m"

##
# Install ahoy
###
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing ahoy...\033[0m"
wget -nv https://github.com/ahoy-cli/ahoy/releases/download/v2.1.1/ahoy-bin-linux-amd64 -O .global/bin/ahoy && chmod +x .global/bin/ahoy
echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] Done installing ahoy!\n\033[0m"
