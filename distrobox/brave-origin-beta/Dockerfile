FROM debian:latest

# install prerequisites required for external repos, Distrobox, and Python scripts
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    ca-certificates \
    apt-transport-https \
    sudo \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# install Python packages via Pip
RUN pip3 install --break-system-packages \
    selenium \
    webdriver-manager

# download Brave Beta repo key and add the Beta sources list
RUN curl -fsSLo /usr/share/keyrings/brave-browser-beta-archive-keyring.gpg https://brave-browser-apt-beta.s3.brave.com/brave-browser-beta-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/brave-browser-beta-archive-keyring.gpg] https://brave-browser-apt-beta.s3.brave.com/ stable main" > /etc/apt/sources.list.d/brave-browser-beta.list

# install Brave Origin Beta
RUN apt-get update && apt-get install -y \
    brave-origin-beta \
    && rm -rf /var/lib/apt/lists/*

# create the managed policies directory & copy the dotfile
RUN mkdir -p /etc/brave/policies/managed
COPY extension_install_policy.json /etc/brave/policies/managed/

# copy the scripts to configure Surfingkeys
COPY allow_user_scripts.py        /usr/local/bin/allow_user_scripts.py
COPY surfingkeys_advanced_mode.py /usr/local/bin/surfingkeys_advanced_mode.py
COPY surfingkeys_load_settings.py /usr/local/bin/surfingkeys_load_settings.py
