# Builds a base Docker image for Ubuntu with X Windows and VNC support.
#
# The built image can be found at:
#
#   https://hub.docker.com/r/x11vnc/docker-desktop
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM ubuntu:22.04
LABEL maintainer Xiangmin Jiao <xmjiao@gmail.com>

ARG DOCKER_LANG=en_US
ARG DOCKER_TIMEZONE=America/New_York
ARG X11VNC_VERSION=latest

ENV LANG=$DOCKER_LANG.UTF-8 \
    LANGUAGE=$DOCKER_LANG:UTF-8 \
    LC_ALL=$DOCKER_LANG.UTF-8

WORKDIR /tmp

ARG DEBIAN_FRONTEND=noninteractive

# Install some required system tools and packages for X Windows and ssh.
# Also remove the message regarding unminimize.
# Note that Ubuntu 22.04 uses snapd for firefox, which does not work properly,
# so we install it from ppa:mozillateam/ppa instead.
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install software-properties-common wget curl -y && echo "muddei"

RUN add-apt-repository ppa:deadsnakes/ppa -y && \
rm /etc/apt/sources.list.d/deadsnakes* && \
sh -c 'echo "deb https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy main" > /etc/apt/sources.list.d/deadsnakes.list' && \
apt-get update

RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg && \
sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'


RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apt-utils \
        apt-file \
        locales \
        language-pack-en && \
    locale-gen $LANG && \
    dpkg-reconfigure -f noninteractive locales && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        curl \
        less \
        vim \
        psmisc \
        runit \
        apt-transport-https ca-certificates \
        software-properties-common \
        man \
        sudo \
        rsync \
        libarchive-tools \
        net-tools \
        gpg-agent \
        inetutils-ping \
        csh \
        tcsh \
        zsh zsh-autosuggestions \
        build-essential autoconf automake autotools-dev pkg-config \
        libssl-dev \
        git \
        dos2unix \
        dbus-x11 \
        \
        openssh-server \
        python3 \
        python3-distutils \
        python3-tk \
        python3-dbus \
        \
        xserver-xorg-video-dummy \
        lxde \
        x11-xserver-utils xdotool \
        xterm \
        gnome-themes-standard \
        gtk2-engines-pixbuf \
        gtk2-engines-murrine \
        libcanberra-gtk-module libcanberra-gtk3-module \
        fonts-liberation \
        xfonts-base xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic \
        libopengl0 mesa-utils libglu1-mesa libgl1-mesa-dri libjpeg8 libjpeg62 \
        xauth xdg-utils \
        x11vnc \
        python3.7 python3.7-venv python3.7-dev \
        python3.11 python3.11-venv python3.11-dev \
        git vim openssh-server curl build-essential nginx \
        supervisor libldap2-dev libsasl2-dev libpq-dev ghostscript libjpeg-dev libfreetype6-dev \
        zlib1g-dev freetds-dev libxmlsec1-dev libxml2-dev libxslt1-dev libblas-dev liblapack-dev \
        libatlas-base-dev gfortran redis-server libglu1-mesa libcairo2 libcups2 libdbus-glib-1-2 \
        libxinerama1 libsm6 tmpreaper wkhtmltopdf swig libaio1 \
        postgresql pgadmin4 libnss3 unzip \
        && \
    chmod 755 /usr/local/share/zsh/site-functions && \
    add-apt-repository -y ppa:mozillateam/ppa && \
    echo 'Package: *' > /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    apt install -y firefox && \
    apt-get -y autoremove && \
    ssh-keygen -A && \
    bash -c "test ! -f /lib64/ld-linux-x86-64.so.2 || ln -s -f /lib64/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so " && \
    perl -p -i -e 's/#?X11Forwarding\s+\w+/X11Forwarding yes/g; \
        s/#?X11UseLocalhost\s+\w+/X11UseLocalhost no/g; \
        s/#?PasswordAuthentication\s+\w+/PasswordAuthentication no/g; \
        s/#?PermitEmptyPasswords\s+\w+/PermitEmptyPasswords no/g' \
        /etc/ssh/sshd_config && \
    rm -f /etc/update-motd.d/??-unminimize && \
    rm -f /etc/xdg/autostart/lxpolkit.desktop && \
    chmod a-x /usr/bin/lxpolkit && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN sudo wget https://go.microsoft.com/fwlink/?LinkID=760868 -O code.deb && \
sudo apt update && \
sudo apt install ./code.deb -y && \
rm -f code.deb

RUN sudo wget https://download.jetbrains.com/python/pycharm-community-2023.1.2.tar.gz && \
tar -xf pycharm-community-2023.1.2.tar.gz && \
mv pycharm-community-2023.1.2 /usr/ && \
mv /usr/pycharm-community-2023.1.2 /usr/pycharm && \
rm -f pycharm-community-2023.1.2.tar.gz

RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
sudo apt update && \
sudo apt install -y ./google-chrome-stable_current_amd64.deb && \
rm -f google-chrome-stable_current_amd64.deb && \
curl -s https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$(google-chrome --version | cut -d ' ' -f 3 | cut -d . -f 1) > version.txt && \
wget https://chromedriver.storage.googleapis.com/$(cat version.txt)/chromedriver_linux64.zip -O chromedriver.zip && \
unzip chromedriver.zip && \
rm -f version.txt chromedriver.zip && \
sudo mv chromedriver /usr/local/bin/

# Install websokify and noVNC
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    pip3 install --no-cache-dir \
        setuptools && \
    pip3 install -U https://github.com/novnc/websockify/archive/refs/tags/v0.10.0.tar.gz && \
    mkdir /usr/local/noVNC && \
    curl -s -L https://github.com/x11vnc/noVNC/archive/refs/heads/x11vnc.zip | \
          bsdtar zxf - -C /usr/local/noVNC --strip-components 1 && \
    (chmod a+x /usr/local/noVNC/utils/launch.sh || \
        (chmod a+x /usr/local/noVNC/utils/novnc_proxy && \
         ln -s -f /usr/local/noVNC/utils/novnc_proxy /usr/local/noVNC/utils/launch.sh)) && \
    rm -rf /tmp/* /var/tmp/*

# Install latest version of x11vnc from source
# Also, fix issue with Shift-Tab not working
# https://askubuntu.com/questions/839842/vnc-pressing-shift-tab-tab-only
RUN apt-get update && \
    apt-get install -y libxtst-dev libssl-dev libvncserver-dev libjpeg-dev && \
    \
    mkdir -p /tmp/x11vnc-${X11VNC_VERSION} && \
    curl -s -L https://github.com/LibVNC/x11vnc/archive/refs/heads/master.zip | \
        bsdtar zxf - -C /tmp/x11vnc-${X11VNC_VERSION} --strip-components 1 && \
    cd /tmp/x11vnc-${X11VNC_VERSION} && \
    bash autogen.sh --prefix=/usr/local CFLAGS='-O2 -fno-common -fno-stack-protector' && \
    make && \
    make install && \
    perl -e 's/,\s*ISO_Left_Tab//g' -p -i /usr/share/X11/xkb/symbols/pc && \
    apt-get -y remove libxtst-dev libssl-dev libvncserver-dev libjpeg-dev && \
    apt-get -y autoremove && \
    ldconfig && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

########################################################
# Customization for user and location
########################################################
# Set up user so that we do not run as root in DOCKER
ENV DOCKER_USER=ubuntu \
    DOCKER_UID=9999 \
    DOCKER_GID=9999 \
    DOCKER_SHELL=/bin/zsh

ENV DOCKER_GROUP=$DOCKER_USER \
    DOCKER_HOME=/home/$DOCKER_USER \
    SHELL=$DOCKER_SHELL


# Change the default timezone to $DOCKER_TIMEZONE
# Run ldconfig so that /usr/local/lib etc. are in the default
# search path for dynamic linker
RUN groupadd -g $DOCKER_GID $DOCKER_GROUP && \
    useradd -m -u $DOCKER_UID -g $DOCKER_GID -s $DOCKER_SHELL -G sudo $DOCKER_USER && \
    echo "$DOCKER_USER:"`openssl rand -base64 12` | chpasswd && \
    echo "$DOCKER_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "$DOCKER_TIMEZONE" > /etc/timezone && \
    ln -s -f /usr/share/zoneinfo/$DOCKER_TIMEZONE /etc/localtime

ADD image/etc /etc
ADD image/usr /usr
ADD image/sbin /sbin
ADD image/home $DOCKER_HOME

# Make home directory readable to work with Singularity
RUN mkdir -p $DOCKER_HOME/.config/mozilla && \
    ln -s -f .config/mozilla $DOCKER_HOME/.mozilla && \
    touch $DOCKER_HOME/.sudo_as_admin_successful && \
    mkdir -p $DOCKER_HOME/shared && \
    mkdir -p $DOCKER_HOME/.ssh && \
    mkdir -p $DOCKER_HOME/.log && touch $DOCKER_HOME/.log/vnc.log && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME && \
    chmod -R a+r $DOCKER_HOME && \
    find $DOCKER_HOME -type d -exec chmod a+x {} \;


WORKDIR $DOCKER_HOME

ENV DOCKER_CMD=startvnc.sh

USER ubuntu

RUN code --install-extension eamodio.gitlens && \
code --install-extension ms-python.autopep8 && \
code --install-extension ms-python.python && \
code --install-extension ms-python.vscode-pylance && \
mkdir ~/Desktop && \
ln -s /usr/pycharm/bin/pycharm.sh ~/Desktop/pycharm

USER root
ENTRYPOINT ["/sbin/my_init", "--", "/sbin/setuser", "ubuntu"]
CMD ["$DOCKER_CMD"]
