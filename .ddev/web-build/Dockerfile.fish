#ddev-generated
RUN echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_11/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list
RUN curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_11/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
RUN apt update && apt satisfy -y "fish (>=3.7)"
USER $uid:$gid
# The ?v= is only there to bust the Dockerfile build cache if there's
# a new version we wan't to make sure it'll get into the builds. It doesn't
# change the installed version or the version of the install script,
# it will always be the latest at the time of the build.
RUN echo "curl -sL 'https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish?4.4.4' | source && fisher install jorgebucaran/fisher" | fish
USER root:root
