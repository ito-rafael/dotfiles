FROM debian:latest

# install prerequisites
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    ca-certificates \
    apt-transport-https \
    sudo \
    jq \
    xvfb \
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
COPY json/extension_install_policy_essential.json /etc/brave/policies/managed/

# enable extensions developer mode
COPY config/initial_preferences /opt/brave.com/brave-origin-beta/initial_preferences
COPY scripts/developer_mode.py /usr/local/bin/developer_mode.py

# copy the scripts to configure Surfingkeys
COPY scripts/surfingkeys_allow_user_scripts.py /usr/local/bin/surfingkeys_allow_user_scripts.py
COPY scripts/surfingkeys_advanced_mode.py      /usr/local/bin/surfingkeys_advanced_mode.py
COPY scripts/surfingkeys_load_settings.py      /usr/local/bin/surfingkeys_load_settings.py
